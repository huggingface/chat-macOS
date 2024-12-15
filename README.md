<p align="center" style="margin-bottom: 0;">
  <img src="assets/banner.png" alt="HuggingChat macOS Banner">
</p>
<h1 align="center" style="margin-top: 0;">HuggingChat macOS</h1>

![Static Badge](https://img.shields.io/badge/License-Apache-orange)
[![swift-version](https://img.shields.io/badge/Swift-6.0-brightgreen.svg)](https://github.com/apple/swift)
[![platform](https://img.shields.io/badge/Platform-macOS_14.0-blue.svg)](https://github.com/apple/swift)


### About
HuggingChat macOS is a native chat interface designed specifically for macOS users, leveraging the power of open-source language models. It brings the capabilities of advanced AI conversation right to your desktop, offering a seamless and intuitive experience.

### Demo
https://github.com/user-attachments/assets/dacc87b2-2242-4ef5-84d5-9f9aae50c453


### Installation

1. Go to the [Releases](https://github.com/huggingface/chat-macOS/releases) section of this repository.
2. Download the latest `HuggingChat-macOS.zip` file.
3. Unzip the downloaded file.
4. Drag the `HuggingChat.app` to your Applications folder.

#### Homebrew
HuggingChat is also available via Homebrew. Simply run:

```bash
brew install --cask huggingchat
```

That's it! You can now launch HuggingChat from your Applications folder or using the dedicated keyboard shortcut: `⌘ + Shift + Return`.

#### VSCode Integration
In order to use HuggingChat in VSCode, you'll need to install the [HuggingChat Extension](https://github.com/cyrilzakka/huggingchat-helper). After downloading it, add it to VSCode by navigating to the Extensions tab and selecting "Install from VSIX". Choose the downloaded file and restart VSCode. HuggingChat can now use context from your code editor to provide more accurate responses.

### Development Setup
#### Prerequisites
- Xcode 16.0 or later
- macOS 14.0 or later

#### Building the Project
1. Clone the repository:
   ```bash
   git clone https://github.com/huggingface/chat-macOS.git
   cd chat-macOS
   ```
2. Open `HuggingChat-macOS.xcodeproj` in Xcode
3. Select your development team in the project settings if you plan to run on a physical device
4. Build and run the project (⌘ + R)

### Making Contributions
#### 1. Choose or Create an Issue
- Check existing [issues](https://github.com/huggingface/chat-macOS/issues) for something you'd like to work on
- Create a new issue if you have a bug fix or feature proposal
- Comment on the issue to let maintainers know you're working on it

#### 2. Fork and Branch
1. Fork the repository to your GitHub account
2. Create a new branch for your work:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

#### 3. Code Style Guidelines
- Follow Apple's [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint rules defined in the project
- Maintain consistent spacing and formatting
- Write meaningful commit messages
- Add comments for complex logic


### Feedback

We value your input! If you have any suggestions, encounter issues, or want to share your experience, please feel free to reach out:

2. **GitHub Issues**: For bug reports or feature requests, please create an issue in this repository. 
    - Provide a clear title and description of your feedback
   - Include steps to reproduce the issue (for bugs) or detailed explanation (for feature requests)
   - Include the app version number and macOS version
   - Submit the issue

Your feedback helps improve HuggingChat macOS for everyone. Thank you for your support!
