//
//  LlamaConfiguration.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 10/2/24.
//

import Foundation
import llama

public struct LlamaConfiguration {
    static var historySize = 5
    public let seed: Int
    public let topK: Int
    public let topP: Float
    public let nCTX: UInt32
    public let temperature: Float
    public let maxTokenCount: Int
    public let batchSize: Int
    public let grp_attn_n: UInt32
    public let grp_attn_w: UInt32

    public init(seed: Int = 1234,
                topK: Int = 40,
                topP: Float = 0.9,
                nCTX: UInt32 = 0,
                temperature: Float = 0.2,
                batchSize: Int = 2048,
                stopSequence: String? = nil,
                historySize: Int = 5,
                maxTokenCount: Int = 1024,
                grp_attn_n: UInt32 = 1,
                grp_attn_w: UInt32 = 512) {
        self.seed = seed
        self.topK = topK
        self.topP = topP
        self.nCTX = nCTX
        self.batchSize = batchSize
        self.temperature = temperature
        Self.historySize = historySize
        self.maxTokenCount = maxTokenCount
        self.grp_attn_n = grp_attn_n
        self.grp_attn_w = grp_attn_w
    }
}

extension LlamaConfiguration {
    var contextParameters: CPPContextParameters {
        var params = llama_context_default_params()
        let processorCount = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
        params.n_ctx = self.nCTX
        params.n_threads = Int32(processorCount)
        params.n_threads_batch = Int32(processorCount)
        return params
    }
}

