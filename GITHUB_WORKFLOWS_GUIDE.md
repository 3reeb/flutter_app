# 🚀 GitHub Actions On-Demand Automation Guide

This project includes ultra-flexible, powerful GitHub Actions workflows designed to run **on-demand (manually)** whenever you trigger them from GitHub.

---

## 🛠️ Workflows Overview

| Workflow | File | Description |
| :--- | :--- | :--- |
| **On-Demand Build & Test Suite** | `.github/workflows/manual_build_and_test.yml` | Full build system supporting **Android, iOS, Web, Windows, macOS, Linux**, custom build modes, test toggles, and GitHub Release generation. |
| **Fast Manual Test Suite** | `.github/workflows/quick_test.yml` | High-speed runner for running static code analysis (`flutter analyze`) and unit test suites on demand. |

---

## 🎯 How to Trigger Workflows from GitHub

1. Push your repository code to GitHub (`git push origin main`).
2. Go to your repository on GitHub.
3. Click the **Actions** tab at the top.
4. On the left sidebar, select **On-Demand Build & Test Suite** or **Fast Manual Test Suite**.
5. Click the **Run workflow** dropdown on the right.
6. Select your parameters:
   - **Target Platform**: Choose `all`, `android`, `ios`, `web`, `windows`, `macos`, `linux`, or `none`.
   - **Build Mode**: Choose `release`, `profile`, or `debug`.
   - **Run Analysis**: Check to run `flutter analyze`.
   - **Run Tests**: Check to run `flutter test`.
   - **Upload Artifacts**: Check to attach downloadable `.apk`, `.aab`, `.zip` app bundles to the GitHub Actions run summary.
   - **Create Release**: Check to automatically generate a GitHub Release tagged with your chosen `release_tag`.
7. Click the green **Run workflow** button!

---

## 📦 Downloaded Build Outputs

When **Upload Artifacts** is checked, built binaries will be downloadable directly under **Artifacts** at the bottom of the completed workflow run page:

- **Android**: `android-apk-release` (APK) and `android-aab-release` (App Bundle)
- **iOS**: `ios-app-release.zip`
- **Web**: `web-release.zip`
- **Windows Desktop**: `windows-release.zip` (.exe + data files)
- **macOS Desktop**: `macos-release.zip` (.app bundle)
- **Linux Desktop**: `linux-release.zip` (executable + library bundle)

---

## 🔑 Code Signing (Optional)

- **Android**: By default, Android APKs are built as unsigned release binaries. You can configure keystore secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, etc.) in GitHub Repository Secrets.
- **iOS**: iOS builds are set to `--no-codesign` so they build smoothly in cloud CI without requiring Apple certificates.
