//
//  LlamaBatch.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 10/2/24.
//

import Foundation
import llama

extension CPPBatch {
    mutating func clear() {
        self.n_tokens = 0
    }

    mutating func add(token: CPPToken,
                      position: CPPPosition,
                      seqIDs: [CPPSeqID],
                      logit: Bool) {
        let nextIndex = Int(n_tokens)
        self.token[nextIndex] = token
        self.pos[nextIndex] = position
        self.n_seq_id[nextIndex] = Int32(seqIDs.count)
        seqIDs.enumerated().forEach { index, id in
            seq_id[nextIndex]?[index] = id
        }
        self.logits[nextIndex] = logit ? 1 : 0
        self.n_tokens += 1
    }
}
