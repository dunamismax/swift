<h1 align="center">Krypton Notes</h1>

<p align="center">
  A secure, end-to-end encrypted, and feature-rich note-taking application designed exclusively for macOS.
  <br />
  Your private notes, secured with military-grade encryption.
</p>

<p align="center">
  <img src="https://github.com/dunamismax/Swift/blob/main/Projects/Krypton%20Notes/Krypton-Notes-Screenshot.png" width="850">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Language-Swift-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/Platform-macOS-lightgrey.svg" alt="macOS">
  <img src="https://img.shields.io/badge/Framework-SwiftUI-blue.svg" alt="SwiftUI">
  <a href="https://github.com/dunamismax/Swift/releases"><img src="https://img.shields.io/github/v/release/dunamismax/Swift" alt="Latest Release"></a>
  <a href="https://github.com/dunamismax/Swift/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://github.com/dunamismax/Swift/pulls"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square" alt="PRs Welcome"></a>
  <a href="https://github.com/dunamismax/Swift/stargazers"><img src="https://img.shields.io/github/stars/dunamismax/Swift?style=social" alt="GitHub Stars"></a>
</p>

---

## Download & Install

To get the latest version of Krypton Notes, please visit the official **[GitHub Releases](https://github.com/dunamismax/Swift/releases)** page.

1. Navigate to the [**releases page**](https://github.com/dunamismax/Swift/releases).
2. Download the latest `.dmg` file from the "Assets" section of the most recent release.
3. Double-click the downloaded `.dmg` file to open it.
4. Drag the **Krypton Notes** app icon into your **Applications** folder.
5. Launch the app from your Applications folder.

## Features

- **End-to-End Encryption:** All notes are encrypted on-device using AES-256-GCM via Apple's CryptoKit framework. The encryption key is securely stored in the iCloud Keychain, ensuring that only the user can access their data.
- **Seamless iCloud Sync:** Notes are automatically and securely synchronized across all of the user's Macs via their private CloudKit container.
- **Native macOS Interface:** The user interface is built entirely in SwiftUI and is designed to feel perfectly at home on macOS, with a familiar three-pane layout, native components, and support for both Light and Dark Modes.
- **Full Markdown Support:** Write notes in Markdown and instantly switch to a rendered preview.
- **Category Management:** Organize your notes with categories. Create, rename, and delete categories, which are dynamically displayed in the sidebar.
- **Favorites:** Mark important notes as favorites for quick access.
- **Advanced Search:** A powerful search feature allows you to filter notes by title or by their full decrypted content.
- **Biometric Lock:** The application requires Face ID or Touch ID authentication on launch to protect your data from unauthorized access.

---

## Building from Source

If you prefer to build the application yourself, you can do so using Xcode.

### Step 1: Clone the Repository

```sh
git clone https://github.com/dunamismax/Swift.git
cd "Swift/Projects/Krypton Notes"
```

### Step 2: Open the Project in Xcode

Navigate to the project directory and open the `Krypton Notes.xcodeproj` file in Xcode.

### Step 3: Configure Your Development Team

Before building, you must select your development team to sign the application:

1. In Xcode, select the project root (`Krypton Notes`) in the Project Navigator.
2. Go to the **"Signing & Capabilities"** tab.
3. From the **"Team"** dropdown, select your personal or developer team.
4. **Crucially**, you must also update the **App Group**, **iCloud Container**, and **Keychain Sharing Group** with your own unique identifiers.

### Step 4: Build and Run the Application

Now you can build and run the application in Xcode:

1. Select the `Krypton Notes` scheme from the toolbar.
2. Choose **My Mac** as the build destination.
3. Click the **"Run"** button (or press `Cmd+R`).

Xcode will build the application, and it should launch automatically.

---

## ️ Project Structure

The Krypton Notes project is organized as follows:

```sh
Krypton Notes/
├── Krypton Notes/
│   ├── Krypton_NotesApp.swift    # Main entry point
│   ├── ContentView.swift         # Main SwiftUI view
│   ├── Note.swift                # SwiftData Model
│   ├── EncryptionService.swift   # Encryption/Decryption logic
│   └── LocalAuthentication.swift # Biometric lock logic
└── Krypton Notes.xcodeproj
```

---

## Contribute

**This project is built by the community, for the community. We need your help!**

Whether you're a seasoned Swift developer or just starting, there are many ways to contribute:

- **Report Bugs:** Find something broken? [Open an issue](https://github.com/dunamismax/Swift/issues) and provide as much detail as possible.
- **Suggest Features:** Have a great idea for a new feature? [Start a discussion](https://github.com/dunamismax/Swift/discussions) or open a feature request issue.
- **Write Code:** Grab an open issue, fix a bug, or implement a new system. [Submit a Pull Request](https://github.com/dunamismax/Swift/pulls) and we'll review it together.
- **Improve Documentation:** Help us make our guides and examples clearer and more comprehensive.

If this project excites you, please **give it a star!** It helps us gain visibility and attract more talented contributors like you.

### Connect

Connect with the author, **dunamismax**, on:

- **Twitter:** [@dunamismax](https://twitter.com/dunamismax)
- **Bluesky:** [@dunamismax.bsky.social](https://bsky.app/profile/dunamismax.bsky.social)
- **Reddit:** [u/dunamismax](https://www.reddit.com/user/dunamismax)
- **Discord:** `dunamismax`
- **Signal:** `dunamismax.66`

## License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.
