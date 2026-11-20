# LuminaVault - iPhone 14 Photo & Video Manager

A high-performance **iOS 16+ / iPhone 14 Photo & Video Management Application** built natively in **SwiftUI** with **Google Photos Cloud Backup**, on-device **Apple Vision AI Smart Grouping** (Documents, Face Areas, Geographic Areas, Screenshots, Short Photos), full phone **File Manager**, and an AES-256 encrypted **Private Vault** with **Face ID** authentication.

---

## 🌟 Key Features

### 1. 📱 Full Phone Library Scanner & File Manager
- **PhotoKit Integration**: Direct high-speed indexing of all camera roll assets via `PHPhotoLibrary` and `PHAsset`.
- **Storage Breakdown Meter**: Analyzes iPhone 14 internal storage (HEIC Photos, 4K Videos, Documents, Screenshots, Private Vault, and iOS system storage).
- **EXIF & Camera Metadata Inspector**: Displays sensor details (e.g. *iPhone 14 Main Camera 26mm ƒ/1.5*, ISO sensitivity, focal length, resolution, GPS coordinates).
- **1-Tap Duplicate Cleaner**: Detects duplicate or near-identical burst sequences and reclaims device storage in one tap.
- **Large Files Explorer**: Filters out files and 4K videos greater than 8 MB to optimize internal storage.

### 2. 🧠 On-Device Apple Vision AI Smart Grouping
- **Document & Receipt OCR**:
  - Uses Apple's `VNRecognizeTextRequest` to scan receipts, paper contracts, whiteboards, notes, and business cards.
  - Built-in text recognition with 1-tap copy to clipboard.
- **Face Area & People Clustering**:
  - Uses `VNDetectFaceRectanglesRequest` to locate facial bounding coordinates, count faces, and cluster portraits by detected individuals.
- **Area & Geolocation Grouping**:
  - Extracts GPS coordinates and runs reverse geocoding via `CLGeocoder` into City, Landmark, and Regional photo albums (e.g., Tokyo, San Francisco, New York, Paris, Hawaii).
- **Screenshots & Clips**:
  - Identifies `photoScreenshot` assets and screen recordings.
  - Includes a 1-tap cleaner for screenshots older than 7 days.
- **Short Photos & Live Clips**:
  - Auto-groups Apple Live Photos (`photoLive`), camera burst sequences, and short video clips (&le;15 seconds).

### 3. ☁️ Google Photos Cloud Backup
- **OAuth 2.0 & Google Sign-In**: Authenticates with Google Photos Library REST API.
- **Binary Upload Protocol**: Streams raw photo/video bytes to `https://photoslibrary.googleapis.com/v1/uploads` with `X-Goog-Upload-Protocol: raw`.
- **Batch Creation**: Calls `mediaItems:batchCreate` to register uploads in the user's Google Photos cloud gallery.
- **Live Sync Queue**: Tracks upload progress per asset with retry capabilities and upload token caching.
- **Google One Quota**: Live cloud storage visualizer (e.g., 4.8 GB of 15 GB used).
- **Configurable Settings**: Wi-Fi-only sync, cellular data toggle, and Original Quality vs Storage Saver.

### 4. 🔒 Private Vault (Locked Folder with Face ID)
- **Biometric Protection**: Face ID and Touch ID authentication via `LocalAuthentication` (`LAContext`).
- **Passcode Fallback**: 4-digit PIN pad (Master PIN: `1414` or `0000`).
- **Stealth Decoy PIN (`9999`)**: Entering the stealth PIN opens a clean, empty decoy vault without exposing private media.
- **256-Bit Hardware Encryption**: Uses Apple's `CryptoKit` with AES-GCM encryption.
- **Isolated Sandbox**: Encrypted payloads are stored in the app's `Application Support/PrivateVaultStorage` directory and explicitly excluded from iCloud and iTunes backups (`isExcludedFromBackup = true`).
- **Move to Vault**: Automatically encrypts selected photos and safely deletes them from the iOS camera roll.
- **Restore Option**: Decrypts and returns files back to the iPhone camera roll at any time.

---

## 🏗️ Architecture & Project Structure

```
LuminaVault/
├── LuminaVault.xcodeproj/
│   └── project.pbxproj                     # Standard Xcode project file (compiles in Xcode)
├── LuminaVault/
│   ├── App/
│   │   ├── LuminaVaultApp.swift            # SwiftUI @main entrypoint & scenePhase auto-lock
│   │   ├── AppState.swift                  # Global app state & session flags
│   │   └── Info.plist                      # PhotoKit, Face ID, Camera, Location & Background permissions
│   ├── Models/
│   │   ├── MediaItem.swift                 # Core media model with EXIF, OCR, faces, and backup status
│   │   ├── MediaCategory.swift             # Smart group types (Documents, Faces, Areas, Screenshots, Short Photos)
│   │   ├── StorageBreakdown.swift          # Phone storage breakdown & duplicate cluster models
│   │   ├── GoogleAccount.swift             # Google OAuth profile, storage quota, and backup tasks
│   │   └── VaultItem.swift                 # AES-GCM encrypted private vault item metadata
│   ├── Services/
│   │   ├── PhotoLibraryScanner.swift       # PhotoKit (PHPhotoLibrary, PHAsset fetch & real-time observer)
│   │   ├── VisionGroupingEngine.swift      # Apple Vision OCR (VNRecognizeText) & Face Detection
│   │   ├── LocationGroupingService.swift   # CoreLocation & MapKit area clustering & reverse geocoding
│   │   ├── GooglePhotosService.swift       # Google Photos REST API (OAuth2, upload byte stream, batchCreate)
│   │   ├── PrivateVaultService.swift       # LocalAuthentication (Face ID) & CryptoKit AES-GCM encryption
│   │   └── FileManagerService.swift        # Internal storage scanner, duplicate detection & file size analyzer
│   ├── ViewModels/
│   │   ├── GalleryViewModel.swift          # Photo grid feed, search, filter segments, batch selection
│   │   ├── SmartGroupingViewModel.swift    # 5 smart groups management & Vision triggers
│   │   ├── FileManagerViewModel.swift      # Storage analysis & 1-tap duplicate cleanup
│   │   ├── BackupViewModel.swift           # Cloud sync status, queue observer, backup settings
│   │   └── VaultViewModel.swift            # Face ID auth, PIN keypad, restore/delete actions
│   ├── Views/
│   │   ├── MainTabView.swift               # iOS 5-tab root container (Photos, Groups, Manager, Backup, Vault)
│   │   ├── Gallery/
│   │   │   ├── GalleryView.swift           # 3-column photo grid, scan status banner & multi-select actions
│   │   │   ├── MediaDetailView.swift       # Fullscreen viewer with OCR copy, EXIF drawer & vault lock button
│   │   │   └── FilterSegmentBar.swift      # Horizontal filter pills (All, Photos, Videos, Live, Favorites)
│   │   ├── SmartGroups/
│   │   │   ├── SmartGroupsHubView.swift    # Hub view with 5 category cards & Vision rescan trigger
│   │   │   ├── DocumentScannerView.swift   # Scanned receipts, forms, invoices with OCR text preview
│   │   │   ├── FaceAreaGroupingView.swift  # Facial recognition albums & person filter pills
│   │   │   ├── LocationGroupingView.swift  # Geolocation clusters with horizontal preview strips
│   │   │   ├── ScreenshotManagerView.swift # Screenshot gallery with 7-day cleanup tool
│   │   │   └── ShortPhotosView.swift       # Live Photos, bursts & short clips (<15s)
│   │   ├── FileManager/
│   │   │   ├── FileManagerView.swift       # Phone storage bar, duplicate cleaner, large files explorer
│   │   │   └── ExifDetailSheet.swift       # Technical camera specs (Lens, ISO, Aperture, GPS, resolution)
│   │   ├── Backup/
│   │   │   ├── GooglePhotosBackupView.swift# Google One meter, 1-tap "Sync All", and upload queue
│   │   │   └── BackupSettingsSheet.swift   # Wi-Fi only, cellular backup, quality mode settings
│   │   └── Vault/
│   │       ├── VaultContainerView.swift    # Lock state switch with navigation bar controls
│   │       ├── VaultLockScreenView.swift   # Face ID biometric prompt & 4-digit PIN pad
│   │       ├── VaultGalleryView.swift      # Decrypted in-memory gallery, restore & delete actions
│   │       └── VaultSettingsView.swift     # Auto-lock timeout, decoy PIN toggle, biometric settings
│   ├── Components/
│   │   ├── GlassCard.swift                 # Frosted glass container (iOS 16/17 HIG)
│   │   ├── MediaThumbnailView.swift        # Image thumbnail with OCR/Face/Shot/Cloud badges
│   │   ├── CircularProgressBar.swift       # Ring progress bar for sync & scan
│   │   └── DynamicIslandBanner.swift       # iPhone 14 Pro / 14 Dynamic Island status banner
│   └── Resources/
│       └── Assets.xcassets/                # AppIcon & AccentColor asset catalogs
├── .github/
│   └── workflows/
│       └── ios-build.yml                   # Automated macOS GitHub Actions CI build workflow
├── Package.swift                           # Swift Package Manager manifest
├── project.yml                             # XcodeGen specification
├── preview.html                            # Interactive browser simulator (iPhone 14 frame & working features)
├── mobile.html                             # Mobile viewport simulator
└── README.md                               # Project documentation
```

---

## ⚡ Quick Test in Browser (Interactive Simulator)

You can test every feature right now on any browser:
1. Open `preview.html` in your browser (Google Chrome, Edge, Safari, or Firefox).
2. You will see an interactive **iPhone 14 frame with Dynamic Island**:
   - **Photos Tab**: Browse media items, filter by Photos/Videos/Live/Favorites, search receipts or cities, and select photos to lock in the vault.
   - **Smart Groups Tab**: Inspect the 5 categories (Documents & OCR, Face Areas & People, Area & Locations, Screenshots & Clips, Short Photos & Live).
   - **File Manager Tab**: View the iPhone 14 storage bar, clean duplicates, and explore large files.
   - **Google Backup Tab**: Tap **"Sync All Now"** to watch the upload progress bar, Dynamic Island animation, and status update to "Backed up to Google Photos".
   - **Private Vault Tab**: Tap the yellow Face ID button or enter PIN `1414` (or decoy `9999`) to unlock the AES-256 encrypted vault.

---

## 🛠️ Building & Running on macOS with Xcode

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- iOS 16.0+ SDK (or iPhone 14 Simulator)

### Steps to Run
1. Open the project in Xcode:
   ```bash
   open LuminaVault.xcodeproj
   ```
2. In the target scheme dropdown, select **LuminaVault** &rarr; **iPhone 14** (or any iOS 16/17/18 simulator).
3. Press **Cmd + R** to build and run.
4. When prompted by the simulator:
   - Accept the **Photos Permission** request to let the app scan your photo library.
   - Accept **Face ID Permission** to allow biometric vault unlocking.

---

## 🔐 Private Vault Security Whitepaper

1. **Key Generation**: A 256-bit symmetric key is derived and managed securely via Apple's `CryptoKit` (`SymmetricKey(size: .bits256)`).
2. **Authenticated Cipher**: All files moved into the vault are sealed using **AES-GCM** (Galois/Counter Mode), providing confidentiality and tamper-evident authentication.
3. **Sandbox Isolation**: Files are written into the isolated application directory (`Application Support/PrivateVaultStorage/`) with POSIX permission `0700`.
4. **Cloud Exclusion**: `URLResourceValues.isExcludedFromBackup = true` is set on the vault directory to prevent unencrypted cloud leakage into iTunes or iCloud backups.
5. **Decoy Vault**: Entering decoy PIN `9999` loads an empty decoy view, providing protection under duress.

---

## ☁️ Google Photos REST API Implementation Details

- **Upload Endpoint**: `POST https://photoslibrary.googleapis.com/v1/uploads`
  - Headers:
    - `Authorization: Bearer <ACCESS_TOKEN>`
    - `Content-Type: application/octet-stream`
    - `X-Goog-Upload-File-Name: <FILENAME>`
    - `X-Goog-Upload-Protocol: raw`
  - Response: A unique `uploadToken` string.
- **Batch Create Endpoint**: `POST https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate`
  - Payload:
    ```json
    {
      "newMediaItems": [
        {
          "description": "Uploaded via LuminaVault for iPhone 14",
          "simpleMediaItem": {
            "uploadToken": "<UPLOAD_TOKEN>",
            "fileName": "IMG_1402.HEIC"
          }
        }
      ]
    }
    ```
- **Background Sync**: Uses `URLSessionConfiguration.background(withIdentifier:)` combined with `BGProcessingTask` to continue backups even when the app is minimized.
