# Project Setup and Local Development Guide

This guide explains how to set up Flutter on your machine and run OST-pro locally.

## 1. Install Flutter

Before running OST-pro, Flutter SDK is required.

### Step-by-step summary:
1. Download Flutter SDK for your operating system. It is recommended to use VS Code to setup Flutter as it is the recommended method of using Flutter in the official documentation. 
2. Add flutter to your system PATH.
3. Run `flutter doctor` to verify setup.

### Detailed Flutter Installation Guide:

Follow the detailed instructions for macOS, Windows, or Linux [here](https://docs.flutter.dev/get-started).

## 2. Verify Flutter Installation

After installation, open a terminal and run:
```
flutter doctor
```

This command checks your environment and displays any missing dependencies.

Make sure all required components are resolved before continuing.

## 3. Clone this repository to your local machine:
```
git clone https://github.com/SplitTime/ost-remote-pro.git

cd ost-remote-pro
```

## 4. Install Dependencies
Run the following command to fetch project dependencies:
```
flutter pub get
```

## 5. Run the Project
Run the following command in the terminal:
```
flutter run
```
Flutter will ask you which machine you would like to run on (Windows/MacOS/Edge etc.)

Follow the prompt and Flutter will compile the app and deploy it to the selected device.

You should now be ready to develop and run this ost-remote-pro locally.

## Project file & object overview

- `pubspec.yaml` — Project metadata, dependencies, assets, and Flutter configuration.
- `README.md` — Project overview and usage instructions (this file).
- `CHANGELOG.md` — Project change history and release notes.
- `LICENSE` — License terms for the repository.
- `.gitignore` — Files and folders excluded from Git.
- `analysis_options.yaml` — Dart/Flutter static analysis rules and lints.
- `.github/` — CI workflows, issue/PR templates and other GitHub configuration.
- `android/` — Android platform project and Gradle configuration.
- `ios/` — iOS platform project and Xcode configuration.
- `web/` — Web platform entry and configuration (if present).
- `windows/`, `macos/`, `linux/` — Desktop platform projects (if present).
- `assets/` — Static assets (images, fonts, JSON) referenced by the app.
- `test/` — Unit and widget tests for the app.
- `build/` — Generated build artifacts (ignored in source control).
- `.metadata` / `.flutter-plugins` — Flutter tooling metadata (generated).
- `.dart_tool/` — Tooling cache and build outputs (generated).

Common `lib/` structure and objects
- `lib/main.dart` — App entrypoint; initializes app and runs `runApp()`.
- `lib/app.dart` or `lib/src/app.dart` — App-level widget, routing, and theme setup.
- `lib/screens/` or `lib/pages/` — Top-level screens (pages/views) composing the app UI.
- `lib/widgets/` — Reusable UI components and small widgets.
- `lib/models/` — Data models and plain Dart objects (DTOs).
- `lib/services/` — API clients, network calls, and external integrations.
- `lib/providers/` or `lib/blocs/` — State-management units (Provider, BLoC, Riverpod, etc.).
- `lib/repositories/` — Data access layer, abstracts services and local storage.
- `lib/utils/` or `lib/helpers/` — Utility functions, formatters, and constants.
- `lib/themes/` — Theme definitions, color palettes, and typography.
- `lib/routes.dart` — Centralized route definitions and navigation helpers.
- `lib/generated/` — Generated code (e.g., localization, JSON serialization).

Tips
- Use `flutter pub get` after editing `pubspec.yaml`.
- Run `flutter analyze` to check static issues and linting.
- Keep widgets small and place shared logic in `services/` or `repositories/` for testability.
- Add or update `test/` files to cover new or changed behavior.

If you want, provide the actual repository listing and I’ll generate a precise file-by-file description.