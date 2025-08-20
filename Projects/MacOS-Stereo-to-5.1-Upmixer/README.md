<h1 align="center">Stereo Upmixer Suite</h1>

<p align="center">
  A user-friendly, native macOS application to upmix stereo audio files to various surround sound formats including 5.1, 7.1 PCM, DTS Master Audio, and Atmos.
  <br />
  Click "Select Files", choose your format, and upmix!
</p>

<p align="center">
  <img src="assets/app-screenshot-v3.png" alt="App Screenshot" width="500">
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

To get the latest version of **Stereo Upmixer Suite**, please visit the official **[GitHub Releases](https://github.com/dunamismax/Swift/releases)** page for the main Swift repository.

1. Navigate to the [**releases page**](https://github.com/dunamismax/Swift/releases).
2. Download the latest `.dmg` file for the **Stereo Upmixer Suite** from the "Assets" section of the most recent release.
3. Double-click the downloaded `.dmg` file to open it.
4. Drag the **Stereo Upmixer Suite** app icon into your **Applications** folder.
5. Launch the app from your Applications folder.

## How to Use

1. **Launch the app.**
2. Click **"Select Files"** to add your stereo audio files, or drag files/folders directly into the window.
3. Click **"Output To"** to choose a destination folder for your upmixed files.
4. Select your desired **"Upmix Format"** from the dropdown (5.1 Surround, 7.1 PCM, DTS Master Audio, or Atmos).
5. Click **"Upmix to [Selected Format]"** to start the process.

The new surround sound files will be saved in the output directory you selected with appropriate suffixes like `_5.1.flac`, `_7.1.flac`, `_DTS-MA.dts`, or `_Atmos.flac`.

## Features

- **Multiple Format Support**: Choose from 5.1 Surround, 7.1 PCM, DTS Master Audio, and Atmos formats
- **Drag & Drop Interface**: Simply drag audio files or folders directly into the app window
- **Intuitive Interface**: Simple file selection and a clear workflow
- **Custom Output Directory**: Choose where to save your upmixed files
- **Batch Processing**: Upmix multiple files at once
- **Real-Time Feedback**: See the status of each file and a master progress bar
- **Cancellable Operation**: Stop the upmixing process at any time
- **Error Handling**: Clear alerts for common issues (e.g., failed processing)
- **Native Look & Feel**: Built with SwiftUI for a modern macOS experience
- **Self-Contained**: `ffmpeg` is bundled with the app, so no extra setup is needed

---

## Listening to Surround Audio

To properly play back the multi-channel audio files, you will need:

- A media player that supports multi-channel FLAC/DTS, such as **VLC** or **IINA**
- An audio system capable of playing the respective surround format (5.1, 7.1, etc.), like an A/V receiver or compatible headphones
- For Atmos content, you'll need an Atmos-capable receiver and speaker setup

---

## Building from Source

If you prefer to build the application yourself, you can do so using Xcode. The `ffmpeg` binary is already included in the project.

### Step 1: Clone the Repository

```sh
git clone https://github.com/dunamismax/Swift.git
cd "Swift/Projects/MacOS-Stereo-to-5.1-Upmixer"
```

### Step 2: Open the Project in Xcode

Navigate to the project directory and open the `MacOS Stereo to 5.1 Upmixer.xcodeproj` file in Xcode.

### Step 3: Configure Your Development Team

Before building, you must select your development team to sign the application:

1. In Xcode, select the project root (`MacOS Stereo to 5.1 Upmixer`) in the Project Navigator.
2. Go to the **"Signing & Capabilities"** tab.
3. From the **"Team"** dropdown, select your personal or developer team.

### Step 4: Build and Run the Application

Now you can build and run the application in Xcode:

1. Select the `MacOS Stereo to 5.1 Upmixer` scheme from the toolbar.
2. Choose **My Mac** as the build destination.
3. Click the **"Run"** button (or press `Cmd+R`).

Xcode will build the application, and it should launch automatically.

---

## ️ Project Structure

The `MacOS-Stereo-to-5.1-Upmixer` project is organized as follows:

```sh
MacOS-Stereo-to-5.1-Upmixer/
├── MacOS Stereo to 5.1 Upmixer/
│   ├── UpmixerApp.swift        # Main entry point
│   ├── UpmixView.swift         # Main SwiftUI view
│   └── AudioUpmixer.swift      # Core upmixing logic
├── MacOS Stereo to 5.1 Upmixer.xcodeproj
└── ffmpeg                    # Bundled ffmpeg binary
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
