# MedMinder 💊🧠

> Smart, intuitive medication reminder and pill tracker app for iOS inspired by Medisafe. Built with SwiftUI, XcodeGen, and automated CI/CD via GitHub Actions.

![MedMinder Icon](MedMinder/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png)

---

## ✨ Features

- 📅 **Today Timeline (Pillbox)**: Interactive schedule partitioned into Morning, Afternoon, Evening, and Night. Mark doses as **Taken**, **Snooze (15 min)**, or **Skip** with single-tap actions.
- 💊 **Custom Pill Identification**: Visual pill customization with custom shapes (Capsule, Tablet, Liquid, Drops, Injection, Inhaler, Patch, Spray) and vibrant color palettes.
- ⏰ **Flexible Dosing & Schedules**:
  - Daily, specific days of the week, or interval doses.
  - Multiple doses per day with exact hours and minutes.
  - Meal instructions (*Before meal*, *With meal*, *After meal*, *Anytime*).
- 📦 **Medicine Cabinet & Refill Alerts**: Track inventory stock for each medication. Automatic refill warning notifications when stock reaches your defined safety threshold.
- 📊 **Adherence & Progress**: Track your 7-day and 30-day medication adherence percentages, streaks, and chronological log history.
- 🔔 **iOS Local Notifications**: Actionable notification reminders with buttons to take or snooze directly from the lock screen.
- 🔒 **100% Offline & Private**: All data is stored locally on device with zero tracking or telemetry.

---

## 🛠️ Tech Stack & Architecture

- **Platform**: iOS 16.0+ (iPhone & iPad)
- **Framework**: Native SwiftUI (Swift 5.9+)
- **Project Configuration**: [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`)
- **CI/CD**: GitHub Actions (`.github/workflows/build-ipa.yml`) compiling the unsigned `.ipa` artifact on every push.

---

## 🚀 Building the Project

### Local Development (macOS)
1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen):
   ```bash
   brew install xcodegen
   ```
2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```
3. Open `MedMinder.xcodeproj` in Xcode and run on Simulator or Device.

### Automated CI/CD (GitHub Actions)
Every push to `main` triggers `.github/workflows/build-ipa.yml`:
- Generates the Xcode project with XcodeGen.
- Builds an unsigned Release `.xcarchive`.
- Packages the app into `MedMinder.ipa`.
- Uploads the `.ipa` as a downloadable GitHub Actions artifact (ready for AltStore, TrollStore, or Sideloadly).

---

## 📄 License
MIT License.
