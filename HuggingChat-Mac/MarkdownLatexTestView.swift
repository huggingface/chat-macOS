//
//  MarkdownLatexTestView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/28/25.
//

import SwiftUI

struct MarkdownLatexTestView: View {
    var body: some View {
        ScrollView {
            MarkdownView(text: """
The Proximal Policy Optimization (PPO) objective function can be represented in LaTeX as follows:

\\[
J(\\theta) = \\mathbb{E}_{\\tau \\sim \\pi_\\theta} \\left[ \\sum_{t=0}^{T} \\gamma^t \\cdot \\min \\left( \\frac{\\pi_\\theta(a_t|s_t)}{\\pi_{\\theta_{\\text{old}}}(a_t|s_t)}, 1 + \\epsilon \\right) \\cdot A^{\\pi_\\theta}(s_t, a_t) \\right]
\\]

Here's a breakdown of the components in this equation:

1. **\\( J(\\theta) \\)**: This represents the objective function that we aim to maximize. It is parameterized by the policy parameters \\( \\theta \\).

2. **\\( \\mathbb{E}_{\\tau \\sim \\pi_\\theta} \\)**: This denotes the expectation over all possible trajectories \\( \\tau \\) generated by following the policy \\( \\pi_\\theta \\).

3. **\\( \\sum_{t=0}^{T} \\gamma^t \\)**: This is the summation over time steps from \\( t = 0 \\) to \\( T \\), with \\( \\gamma \\) being the discount factor applied to future rewards.

4. **\\( \\min \\left( \\frac{\\pi_\\theta(a_t|s_t)}{\\pi_{\\theta_{\\text{old}}}(a_t|s_t)}, 1 + \\epsilon \\right) \\)**: This term ensures stability by constraining the ratio of the new policy to the old policy within a small range around 1, where \\( \\epsilon \\) is a hyperparameter that controls the maximum allowed deviation.

5. **\\( A^{\\pi_\\theta}(s_t, a_t) \\)**: This is the advantage function, which measures how advantageous an action \\( a_t \\) is in state \\( s_t \\) under the policy \\( \\pi_\\theta \\). It is typically defined as \\( A^{\\pi_\\theta}(s, a) = Q^{\\pi_\\theta}(s, a) - V^{\\pi_\\theta}(s) \\), where \\( Q \\) is the action-value function and \\( V \\) is the state-value function.

This equation encapsulates the core idea of the PPO algorithm, which is to maximize the expected cumulative reward while ensuring that policy updates are stable and conservative.
""")
            
                .padding()
        }
    }
}

#Preview {
    MarkdownLatexTestView()
        .frame(width: 300, height: 400)
        .textSelection(.enabled)
}
