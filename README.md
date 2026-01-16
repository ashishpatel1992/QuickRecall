# QuickRecall

> A native macOS app for managing and inserting text snippets with speed and precision.

QuickRecall allows you to store named text snippets and insert them anywhere using a global hotkey. Built with Swift and SwiftUI for a lightweight, native experience.

## ✨ Features

- **Global Hotkey**: Access your snippets from any app (Default: `⌘ + ⇧ + Space`).
- **Fuzzy Search**: Quickly find snippets by name or content.
- **Search Filtering**: Toggle between **Full Text** and **Title Only** search for better precision.
- **Privacy First**: Snippets are stored locally on your machine.

## 🛠 Tech Stack

- **Language**: Swift 5
- **UI Frameworks**: SwiftUI, AppKit (for status items & global shortcuts)
- **Tooling**: XcodeGen

## 🚀 Getting Started

### Prerequisites

- macOS 13.0 or later
- Xcode 14+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/yourusername/QuickRecall.git
    cd QuickRecall
    ```

2.  **Install XcodeGen** (if not already installed)
    ```bash
    brew install xcodegen
    ```

3.  **Generate the Xcode Project**
    ```bash
    xcodegen generate
    ```

4.  **Run the App**
    - Open `QuickRecall.xcodeproj` in Xcode.
    - Select the `QuickRecall` scheme.
    - Press `Cmd+R` to run.

### Permissions

On first use, QuickRecall will request **Accessibility Permissions**. This is required to simulate the `Cmd+V` keystroke for pasting text into other applications.

1.  Go to **System Settings** → **Privacy & Security** → **Accessibility**.
2.  Enable the toggle for **QuickRecall**.
3.  Restart the app if necessary.

## 🤝 Contributing

We welcome contributions from the community! Whether it's fixing a bug, adding a feature, or improving documentation, your help is appreciated.

### How to Contribute

1.  **Fork the Project**: Click the "Fork" button at the top right of this page.
2.  **Create your Feature Branch**:
    ```bash
    git checkout -b feature/AmazingFeature
    ```
3.  **Commit your Changes**:
    ```bash
    git commit -m 'Add some AmazingFeature'
    ```
4.  **Push to the Branch**:
    ```bash
    git push origin feature/AmazingFeature
    ```
5.  **Open a Pull Request**: Go to the original repository and click "New Pull Request".

### Development Guidelines

- Follow standard Swift coding conventions.
- Ensure the app builds and runs without errors.
- If adding new UI features, please test thoroughly on macOS.

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## ☕ Support

If you find this app useful and want to support its development, you can buy me a coffee!

<a href="https://buymeacoffee.com/ashishpatel.dev" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
