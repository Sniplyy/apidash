# PR Description: API Explorer Feature (#619) & macOS Build Fixes

## 🚀 What does this PR do?

This PR implements the **API Explorer** feature (Issue #619) allowing users to discover, browse, search, and import a curated library of public APIs directly into their APIDash workspace. It also squashes several critical macOS build-time null-safety bugs and fixes the native workspace "Choose Directory" picker on macOS.

### ✨ New Features: API Explorer
* **Dashboard Integration:** Added a new "Explore" 🧭 tab into the main dashboard navigation rail.
* **Curated API Registry:** Bundled an offline-first library of 25 popular endpoints (OpenAI, Gemini, GitHub, Weather, Finance, etc.) across 11 categories.
* **Discovery & Search UI:** Built an `ApiExplorerSidebar` with category filter chips, search text field, and method-badged endpoint list.
* **Detail & Import View:** Implemented `ApiExplorerDetail` to preview the request (URL, Params, Headers, Body) and a 1-click **"Import to Workspace"** button that seamlessly adds the endpoint to the user's Requests tab.
* **Backend Automation Pipeline:** Created a Python toolset (`tools/api_explorer/*`) that can automatically parse OpenAPI JSON/YAML specs, auto-tag categories via keywords, enrich endpoints with sample bodies, and emit the `api_registry.json`.

### 🐛 Bug Fixes
* **Codegen Null-Safety Violations:** Fixed 22 code generator modules (`lib/codegen/**/*.dart`) that were attempting to access parts of `Uri?` without null checks. Added the guard: `if (uri == null) return null;` where `getValidRequestUri(..)` is called.
* **History Null-Safety:** Fixed `history_service.dart` where `retentionDate` was being compared without a null guard.
* **Collection Null-Safety:** Fixed `collection_providers.dart` where `requestModel` was not promoted to non-nullable before execution.
* **macOS Directory Picker:** Fixed the native "Choose Directory" workspace picker button not opening. The macOS app sandbox was blocking `file_selector`. Fixed by adding `com.apple.security.files.user-selected.read-write` to `DebugProfile.entitlements` and `Release.entitlements`.

## 📸 Screenshots & Videos

> **Note to Submitter:** Please replace these placeholders with actual screenshots from your running app!

| Explore Tab Navbar | Category Chips & Search |
| :---: | :---: |
| <img width="300" alt="Explore Navbar" src="https://via.placeholder.com/300?text=Insert+Nav+Rail+Screenshot"> | <img width="300" alt="Sidebar" src="https://via.placeholder.com/300?text=Insert+Sidebar+Screenshot"> |

| Endpoint Detail & Import Button | macOS "Choose Directory" Working |
| :---: | :---: |
| <img width="400" alt="Detail Pane" src="https://via.placeholder.com/400?text=Insert+Detail+View+Screenshot"> | <img width="400" alt="Directory Picker" src="https://via.placeholder.com/400?text=Insert+macOS+Finder+Picker"> |

## 🛠️ Testing Strategy (How to Verify)

1. **Verify Backend Pipeline:** 
   ```bash
   cd tools/api_explorer
   python3 pipeline.py --seed
   ```
   *Expected: Re-generates `assets/api_registry.json` successfully.*

2. **Verify App Build:**
   ```bash
   flutter clean && flutter pub get
   flutter run -d macos
   ```
   *Expected: App builds with 0 null-safety or codegen compilation errors.*

3. **Verify API Explorer Integration:**
   * Click **Explore** in the sidebar.
   * Filter by the `AI` category.
   * Search for `Google Gemini`.
   * Click **"Import to Workspace"**.
   * *Expected: Switches to Requests tab and the Gemini endpoint is pre-populated in the workspace.*

4. **Verify macOS File Picker:**
   * Navigate to the Workspace setup screen.
   * Click **"Select"** directory.
   * *Expected: The native macOS finder directory picker opens.*

## 📋 Checklist
- [x] Read the [Contributing Guidelines](https://github.com/foss42/apidash/blob/main/CONTRIBUTING.md).
- [x] Followed the code style of the project and ran `flutter analyze`.
- [x] Tested changes locally.
- [x] Checked for any new or existing bugs.
