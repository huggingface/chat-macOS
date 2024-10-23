//
//  LlamaModel.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 10/2/24.
//

import Foundation
import llama

func llama_batch_clear(_ batch: inout llama_batch) {
    batch.n_tokens = 0
}

func llama_batch_add(_ batch: inout llama_batch, _ id: llama_token, _ pos: llama_pos, _ seq_ids: [llama_seq_id], _ logits: Bool) {
    batch.token   [Int(batch.n_tokens)] = id
    batch.pos     [Int(batch.n_tokens)] = pos
    batch.n_seq_id[Int(batch.n_tokens)] = Int32(seq_ids.count)
    for i in 0..<seq_ids.count {
        batch.seq_id[Int(batch.n_tokens)]![Int(i)] = seq_ids[i]
    }
    batch.logits  [Int(batch.n_tokens)] = logits ? 1 : 0

    batch.n_tokens += 1
}

public struct LlamaChatMessage {
    public let role: String
    public let content: String
    
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
    
    func toCStruct() -> llama_chat_message {
        return llama_chat_message(role: strdup(role), content: strdup(content))
    }
}

class LlamaModel {
    private let model: CPPModel
    private let configuration: LlamaConfiguration
    private let context: OpaquePointer
    private var sampling: UnsafeMutablePointer<llama_sampler>
    private var batch: CPPBatch
    private var tokens: [CPPToken]
    private var n_batch: UInt32
    private var n_ctx: UInt32
    private var temporaryInvalidCChars: [CChar] = []
    private var generatedTokenAccount: Int32 = 0
    private var ended = false
    
    
    private var n_keep: Int32 = 0 // number of tokens to keep from the initial prompt (default: 0, -1 = all)
    
    // group-attention state
    private var ga_i: Int = 0 // number of grouped KV tokens so far; (used only if params.grp_attn_n > 1)
    private var ga_n: UInt32 = 1
    private var ga_w: UInt32 = 512
    
    var n_decode: Int32 = 0
    
    var shouldContinue: Bool {
        generatedTokenAccount < configuration.maxTokenCount && !ended
    }
    
    var eogTokens: Set<String> = []
    
    init(path: String, configuration: LlamaConfiguration = .init()) throws {
        self.configuration = configuration
        llama_backend_init()
        var model_params = llama_model_default_params()
        
        
#if targetEnvironment(simulator)
        model_params.n_gpu_layers = 0
#endif
        guard let model = llama_load_model_from_file(path, model_params) else {
            throw LlamaError.others("Cannot load model at path \(path)")
        }
        
        self.model = model
        guard let context = llama_new_context_with_model(model, configuration.contextParameters) else {
            throw LlamaError.couldNotInitializeContext
        }
        self.context = context
        self.tokens = []
        self.batch = llama_batch_init(Int32(configuration.batchSize * LlamaConfiguration.historySize * 2), 0, 1)
        
        let sparams = llama_sampler_chain_default_params()
        self.sampling = llama_sampler_chain_init(sparams)
        
        llama_sampler_chain_add(self.sampling, llama_sampler_init_temp(0.8))
        llama_sampler_chain_add(self.sampling, llama_sampler_init_softmax())
        llama_sampler_chain_add(self.sampling, llama_sampler_init_dist(1234))
        
        n_ctx = llama_n_ctx(context)
        n_batch = llama_n_batch(model)
        
        try checkContextLength(context: context, model: model)
        self.eogTokens = getEOGTokens()
    }
    
    private func checkContextLength(context: CPPContext, model: CPPModel) throws {
        let n_ctx_train = llama_n_ctx_train(model)
        if n_ctx > n_ctx_train {
            throw LlamaError.others("Model was trained on \(n_ctx_train) context but tokens \(n_ctx) specified")
        }
    }
    
    func start(for prompt: String) throws {
        ended = false
        tokens = tokenize(text: prompt, addBos: true)
        temporaryInvalidCChars = []
        
        
        if tokens.count > 2048 {
            throw LlamaError.others("Input text is too long and cannot be processed. Please reduce the length of the input text or start a new conversation.")
        }
        
        let n_kv_req = tokens.count + (Int(n_ctx) - tokens.count)
        
        if n_kv_req > n_ctx {
            print("error: n_kv_req > n_ctx, the required KV cache size is not big enough")
        }
        
        batch.clear()
        
        tokens.enumerated().forEach { index, token in
            batch.add(token: token, position: Int32(index), seqIDs: [0], logit: false)
        }
        batch.logits[Int(batch.n_tokens) - 1] = 1 // true
        
        if llama_decode(context, batch) != 0 {
            throw LlamaError.decoderError
        }
        generatedTokenAccount = batch.n_tokens // n_cur = batch.n_tokens
    }
    
    func `continue`() throws -> String {
        var new_token_id: llama_token = 0
        
        new_token_id = llama_sampler_sample(sampling, context, batch.n_tokens - 1)
        
        if llama_token_is_eog(model, new_token_id) || generatedTokenAccount == n_ctx {
            ended = true
            let new_token_str = String(cString: temporaryInvalidCChars + [0])
            temporaryInvalidCChars.removeAll()
            return new_token_str
        }
        
        let new_token_cchars = tokenToCChars(token: new_token_id)
        temporaryInvalidCChars.append(contentsOf: new_token_cchars)
        let new_token_str: String
        if let string = String(validatingUTF8: temporaryInvalidCChars + [0]) {
            temporaryInvalidCChars.removeAll()
            new_token_str = string
        } else if (0 ..< temporaryInvalidCChars.count).contains(where: {$0 != 0 && String(validatingUTF8: Array(temporaryInvalidCChars.suffix($0)) + [0]) != nil}) {
            // in this case, at least the suffix of the temporary_invalid_cchars can be interpreted as UTF8 string
            let string = String(cString: temporaryInvalidCChars + [0])
            temporaryInvalidCChars.removeAll()
            new_token_str = string
        } else {
            new_token_str = ""
        }
        
        llama_batch_clear(&batch)
        llama_batch_add(&batch, new_token_id, generatedTokenAccount, [0], true)
        
        n_decode += 1
        generatedTokenAccount    += 1
        
        if llama_decode(context, batch) != 0 {
            print("failed to evaluate llama!")
        }
        
        return new_token_str
    }
    
    private func manageContext() {
            // context shifting
        if ga_n == 1 {
           
                let n_left = generatedTokenAccount - n_keep
                let n_discard = n_left / 2
                print("Context full, swapping: n_past = \(generatedTokenAccount), n_left = \(n_left), n_ctx = \(n_ctx), n_keep = \(n_keep), n_discard = \(n_discard)")
                llama_kv_cache_seq_rm(context, 0, Int32(n_keep), Int32(n_keep) + n_discard)
                llama_kv_cache_seq_add(context, 0, Int32(n_keep) + n_discard, generatedTokenAccount, -n_discard)
                
                generatedTokenAccount -= n_discard
                print("After swap: n_past = \(generatedTokenAccount)")
                print("Clear session path")
            
        } else {
            // Self-extend
            while generatedTokenAccount >= Int32(ga_i + Int(ga_w)) {
                let ib = (Int(ga_n) * ga_i) / Int(ga_w)
                let bd = (Int(ga_w) / Int(ga_n)) * (Int(ga_n) - 1)
                let dd = (Int(ga_w) / Int(ga_n)) - ib * bd - Int(ga_w)
                
                print("\nshift: [\(String(format: "%6d", ga_i)), \(String(format: "%6d", generatedTokenAccount))] + \(String(format: "%6d", ib*bd)) -> [\(String(format: "%6d", ga_i + ib*bd)), \(String(format: "%6d", Int(generatedTokenAccount) + ib*bd))]")
                print("div:   [\(String(format: "%6d", ga_i + ib*bd)), \(String(format: "%6d", ga_i + ib*bd + Int(ga_w)))] / \(String(format: "%6d", ga_n)) -> [\(String(format: "%6d", (ga_i + ib*bd)/Int(ga_n))), \(String(format: "%6d", (ga_i + ib*bd + Int(ga_w))/Int(ga_n)))]")
                print("shift: [\(String(format: "%6d", ga_i + ib*bd + Int(ga_w))), \(String(format: "%6d", Int(generatedTokenAccount) + ib*bd))] + \(String(format: "%6d", dd)) -> [\(String(format: "%6d", ga_i + ib*bd + Int(ga_w) + dd)), \(String(format: "%6d", Int(generatedTokenAccount) + ib*bd + dd))]")
                
                llama_kv_cache_seq_add(context, 0, Int32(ga_i), generatedTokenAccount, Int32(ib*bd))
                llama_kv_cache_seq_div(context, 0, Int32(ga_i + ib*bd), Int32(ga_i + ib*bd + Int(ga_w)), Int32(ga_n))
                llama_kv_cache_seq_add(context, 0, Int32(ga_i + ib*bd + Int(ga_w)), generatedTokenAccount + Int32(ib*bd), Int32(dd))
                
                generatedTokenAccount -= Int32(bd)
                ga_i += Int(ga_w) / Int(ga_n)
                
                print("\nn_past_old = \(generatedTokenAccount + Int32(bd)), n_past = \(generatedTokenAccount), ga_i = \(ga_i)\n")
            }
        }
    }
    
    private func tokenToCChars(token: llama_token) -> [CChar] {
        let result = UnsafeMutablePointer<Int8>.allocate(capacity: 8)
        result.initialize(repeating: Int8(0), count: 8)
        defer {
            result.deallocate()
        }
        let nTokens = llama_token_to_piece(model, token, result, 8, 0, false)
        
        if nTokens < 0 {
            let newResult = UnsafeMutablePointer<Int8>.allocate(capacity: Int(-nTokens))
            newResult.initialize(repeating: Int8(0), count: Int(-nTokens))
            defer {
                newResult.deallocate()
            }
            let nNewTokens = llama_token_to_piece(model, token, newResult, -nTokens, 0, false)
            let bufferPointer = UnsafeBufferPointer(start: newResult, count: Int(nNewTokens))
            return Array(bufferPointer)
        } else {
            let bufferPointer = UnsafeBufferPointer(start: result, count: Int(nTokens))
            return Array(bufferPointer)
        }
    }
    
    
    private func getEOGTokens() -> Set<String> {
        var rawTokens: [llama_token] = []
        let n_vocab = llama_n_vocab(model)
        
        for i in 0..<n_vocab {
            if llama_token_is_eog(model, llama_token(i)) {
                rawTokens.append(llama_token(i))
            }
        }
        
        var bufferSize = 16  // Assuming most tokens will be short
        var buffer = [CChar](repeating: 0, count: bufferSize)
        
        func processToken(_ token: llama_token) -> String? {
            while true {
                let result = withUnsafePointer(to: token) { tokenPtr in
                    llama_detokenize(
                        model,
                        tokenPtr,
                        1,
                        &buffer,
                        Int32(bufferSize),
                        false,
                        true
                    )
                }
                
                if result >= 0 {
                    return buffer.withUnsafeBufferPointer { bufferPointer in
                        guard let baseAddress = bufferPointer.baseAddress else { return nil }
                        return String(cString: baseAddress, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                } else {
                    
                    bufferSize = max(bufferSize * 2, -Int(result))
                    buffer = [CChar](repeating: 0, count: bufferSize)
                }
            }
        }
        
        var tokens = Set<String>()
        for token in rawTokens {
            if let tokenString = processToken(token), !tokenString.isEmpty {
                tokens.insert(tokenString)
            }
        }
        return tokens
    }
    
    func apply_chat_template(template: String?, chat: [LlamaChatMessage], addAss: Bool) -> String? {
        var fallback = false
        var allocatedSize: Int = 0
        let cChat = chat.map { message -> llama_chat_message in
            let cStruct = message.toCStruct()
            allocatedSize += Int(Double(message.role.count + message.content.count) * 1.25)
            return cStruct
        }
        var buffer = [Int8](repeating: 0, count: allocatedSize)
        var result = llama_chat_apply_template(
            model,
            nil,
            cChat,
            chat.count,
            addAss,
            &buffer,
            Int32(allocatedSize)
        )
        
        if result < 0 {
            if template != nil {
                print("Error applying chat template")
                return nil
            } else {
                result = llama_chat_apply_template(
                    nil,
                    "chatml",
                    cChat,
                    chat.count,
                    addAss,
                    &buffer,
                    Int32(allocatedSize)
                )
                fallback = true
            }
        }
        
        if result > allocatedSize {
            buffer = [Int8](repeating: 0, count: Int(result))
            result = llama_chat_apply_template(
                fallback ? nil : model,
                fallback ? "chatml" : template,
                cChat, chat.count, addAss, &buffer, Int32(buffer.count));
        }
        defer {
            cChat.forEach { message in
                free(UnsafeMutablePointer(mutating: message.role))
                free(UnsafeMutablePointer(mutating: message.content))
            }
        }
        return buffer.withUnsafeBufferPointer { bufferPointer in
            guard let baseAddress = bufferPointer.baseAddress else { return nil }
            return String(cString: baseAddress, encoding: .utf8)
        }
    }
    
    
    private func tokenize(text: String, addBos: Bool) -> [CPPToken] {
        let utf8Count = text.utf8.count
        let n_tokens = utf8Count + (addBos ? 1 : 0) + 1
        let tokens = UnsafeMutablePointer<llama_token>.allocate(capacity: n_tokens)
        let tokenCount = llama_tokenize(model, text, Int32(utf8Count), tokens, Int32(n_tokens), addBos, true)
        
        var swiftTokens: [llama_token] = []
        for i in 0..<tokenCount {
            swiftTokens.append(tokens[Int(i)])
        }
        
        tokens.deallocate()
        
        return swiftTokens
    }
    
    func clear() {
        tokens.removeAll()
        temporaryInvalidCChars.removeAll()
        llama_kv_cache_clear(context)
    }
    
    deinit {
        llama_sampler_free(sampling)
        llama_batch_free(batch)
        llama_free(context)
        llama_free_model(model)
        llama_backend_free()
    }
}

