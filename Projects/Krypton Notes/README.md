# Krypton Notes

Krypton Notes is a secure, end-to-end encrypted, and feature-rich note-taking application designed exclusively for macOS. It leverages modern Apple technologies like SwiftUI, SwiftData, and CloudKit to provide a seamless and secure experience for managing sensitive information.

## Features

- **End-to-End Encryption:** All notes are encrypted on-device using AES-256-GCM via Apple's CryptoKit framework. The encryption key is securely stored in the iCloud Keychain, ensuring that only the user can access their data.
- **Seamless iCloud Sync:** Notes are automatically and securely synchronized across all of the user's Macs via their private CloudKit container.
- **Native macOS Interface:** The user interface is built entirely in SwiftUI and is designed to feel perfectly at home on macOS, with a familiar three-pane layout, native components, and support for both Light and Dark Modes.
- **Full Markdown Support:** Write notes in Markdown and instantly switch to a rendered preview.
- **Category Management:** Organize your notes with categories. Create, rename, and delete categories, which are dynamically displayed in the sidebar.
- **Favorites:** Mark important notes as favorites for quick access.
- **Advanced Search:** A powerful search feature allows you to filter notes by title or by their full decrypted content.
- **Biometric Lock:** The application requires Face ID or Touch ID authentication on launch to protect your data from unauthorized access.

## Tech Stack

- **UI:** SwiftUI
- **Data Persistence & Sync:** SwiftData with NSPersistentCloudKitContainer
- **Encryption:** Apple CryptoKit (AES-256-GCM)
- **Key Management:** iCloud Keychain Sharing
- **Local Authentication:** LocalAuthentication (Face ID / Touch ID)
- **Markdown Rendering:** [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui)

## Getting Started

1.  **Clone the Repository:**
    ```bash
    git clone <repository-url>
    ```
2.  **Configure Xcode Project:**
    - Open the `Krypton Notes.xcodeproj` file in Xcode.
    - In the "Signing & Capabilities" tab for the `Krypton Notes` target, you must select your own Apple Developer team and configure the following capabilities with your own unique identifiers:
        - **App Groups** (e.g., `group.com.yourdomain.KryptonNotes`)
        - **Keychain Sharing** (must match the App Group)
        - **iCloud** (select CloudKit and create/select a container, e.g., `iCloud.com.yourdomain.KryptonNotes`)
3.  **Update Identifiers in Code:**
    - In `EncryptionService.swift`, update the `keychainGroup` constant to match your Keychain Sharing group.
    - In `Krypton_NotesApp.swift`, update the `cloudKitContainerIdentifier` in the `ModelConfiguration` to match your iCloud container.
4.  **Add Package Dependencies:**
    - In Xcode, go to **File > Add Package Dependencies...** and add the `MarkdownUI` package: `https://github.com/gonzalezreal/swift-markdown-ui`
5.  **Build and Run:** Build and run the application in Xcode.

This completes the final project setup. The application is now ready for use, further development, or distribution.
