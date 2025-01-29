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
            MarkdownView(text: "`let message = \"Hello, World!\"`\n ```swift\n let variable: Str = \"Hello, World!\" \nvar greeting:\n```\n\nThe objective function for PPO is typically defined as follows:\n\n$$\n\\mathbb{E}\\left[\\min\\left(\\frac{\\pi_{\\theta}(a \\mid s)}{\\pi_{\\theta_{\\text{old}}}(a \\mid s)} \\cdot A^{\\pi_{\\theta_{\\text{old}}}}(s, a), \\text{clip}\\left(\\frac{\\pi_{\\theta}(a \\mid s)}{\\pi_{\\theta_{\\text{old}}}(a \\mid s)}, 1-\\epsilon, 1+\\epsilon\\right) \\cdot A^{\\pi_{\\theta_{\\text{old}}}}(s, a)\\right)\\right]\n$$\n\nwhere:\n- $\\mathbb{E}$ denotes the expected value.\n- $\\pi_{\\theta}(a \\mid s)$ is the probability of taking action $a$ in state $s$ under the current policy $\\pi$ with parameters $\\theta$.\n- $\\pi_{\\theta_{\\text{old}}}(a \\mid s)$ is the probability of taking action $a$ in state $s$ under the old policy (before the update).\n- $A^{\\pi_{\\theta_{\\text{old}}}}(s, a)$ is the advantage function, which estimates the relative goodness of taking action $a$ in state $s$ compared to the average performance of the old policy.\n- $\\epsilon$ is a hyperparameter that controls the clipping range.\n\nIn simple terms, PPO aims to optimize the policy by updating it in a way that ensures the new policy doesn't deviate too much from the old one, while also maximizing the advantage function. The clipping operation helps to prevent the new policy from changing too rapidly, which can lead to unstable learning.\n\nHere's a step-by-step explanation of the PPO algorithm:\n\n1. Collect a batch of trajectories by running the current policy in the environment.\n2. Compute the advantage estimates $A^{\\pi_{\\theta_{\\text{old}}}}(s, a)$ for each state-action pair in the batch.\n3. Compute the probability ratio $\\frac{\\pi_{\\theta}(a \\mid s)}{\\pi_{\\theta_{\\text{old}}}(a \\mid s)}$ for each state-action pair.\n4. Calculate the surrogate objective using the minimum of the clipped and unclipped objective functions, as shown in the equation above.\n5. Update the policy parameters $\\theta$ using stochastic gradient ascent on the surrogate objective.\n6. Update the old policy parameters with the new parameters: $\\theta_{\\text{old}} \\leftarrow \\theta$.\n7. can be expressed as:\n\n\\[\nL^{PPO}(\\theta) = \\mathbb{E}_{s,a \\sim \\pi_\\theta} \\left[ \\min \\left( r(\\theta) \\cdot A(s,a), \\text{clip}(r(\\theta), 1 - \\epsilon, 1 + \\epsilon) \\cdot A(s,a) \\right) \\right]\n\\]\n\nWhere:\n- \\( \\pi_\\theta \\): The policy parameterized by \\( \\theta \\).\n- \\( r(\\theta) = \\frac{\\pi_\\theta(a|s)}{\\pi_{\\theta_{\\text{old}}}(a|s)} \\): The ratio of the new policy to the old policy (likelihood ratio).\n- \\( A(s,a) \\): The advantage value, which estimates how much better an action is compared to the average action in that state.\n- \\( \\epsilon \\): The clipping parameter, which bounds the ratio \\( r(\\theta) \\) to ensure the update stays within a reasonable range.\n\n### Explanation:\n1. **Likelihood Ratio (r):**\n   \\[\n   r(\\theta) = \\frac{\\pi_\\theta(a|s)}{\\pi_{\\theta_{\\text{old}}}(a|s)}\n   \\]\n   ")
                .padding()
        }
    }
}

#Preview {
    MarkdownLatexTestView()
        .frame(width: 300, height: 400)
        .textSelection(.enabled)
}
