import SwiftUI

public enum MetroThemeColor: String, CaseIterable, Identifiable {
    case nokiaCyan = "Nokia Cyan"
    case cobalt = "Cobalt Blue"
    case mango = "Mango Orange"
    case crimson = "Crimson Red"
    case lime = "Emerald Lime"
    case magenta = "Magenta Pink"
    
    public var id: String { rawValue }
    
    public var color: Color {
        switch self {
        case .nokiaCyan: return Color(red: 0.0, green: 0.64, blue: 0.89)
        case .cobalt: return Color(red: 0.0, green: 0.35, blue: 0.8)
        case .mango: return Color(red: 0.94, green: 0.59, blue: 0.04)
        case .crimson: return Color(red: 0.9, green: 0.08, blue: 0.0)
        case .lime: return Color(red: 0.2, green: 0.6, blue: 0.2)
        case .magenta: return Color(red: 0.85, green: 0.0, blue: 0.45)
        }
    }
}

public struct WindowsPhoneMetroView: View {
    @ObservedObject private var scanner = PhotoLibraryScanner.shared
    @ObservedObject private var googleService = GooglePhotosService.shared
    @ObservedObject private var vaultService = PrivateVaultService.shared
    @ObservedObject private var fileManagerService = FileManagerService.shared
    @AppStorage("app_ui_theme") private var appUiTheme: String = "metro"
    
    @State private var selectedPivot: String = "start"
    @State private var themeColor: MetroThemeColor = .nokiaCyan
    @State private var showAppBarMenu: Bool = false
    @State private var selectedMediaItem: MediaItem? = nil
    @State private var tileFlipAngle: Double = 0.0
    
    private let pivotSections = ["start", "photos", "videos", "documents", "people", "vault", "cloud"]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Pure OLED Black Background (Windows Phone Signature)
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Windows Phone Header
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("LUMINA VAULT")
                            .font(.system(size: 11, weight: .black, design: .default))
                            .tracking(3)
                            .foregroundColor(themeColor.color)
                        
                        Spacer()
                        
                        // Switch to iOS Modern Tab UI
                        Button(action: {
                            appUiTheme = "modern"
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "switch.2")
                                Text("iOS UI")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    
                    // Pivot Horizontal Title Header
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(pivotSections, id: \.self) { section in
                                Button(action: {
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        selectedPivot = section
                                    }
                                }) {
                                    Text(section)
                                        .font(.system(size: 36, weight: selectedPivot == section ? .light : .ultraLight, design: .default))
                                        .foregroundColor(selectedPivot == section ? .white : Color.gray.opacity(0.45))
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                }
                .padding(.bottom, 6)
                
                // Pivot Content Pages
                TabView(selection: $selectedPivot) {
                    // 1. START SCREEN (Live Tiles Grid)
                    metroStartScreen
                        .tag("start")
                    
                    // 2. ALL PHOTOS
                    metroAllPhotosList
                        .tag("photos")
                    
                    // 3. VIDEOS
                    metroVideosList
                        .tag("videos")
                    
                    // 4. DOCUMENTS & OCR
                    metroDocumentsList
                        .tag("documents")
                    
                    // 5. PEOPLE & FACES
                    metroPeopleList
                        .tag("people")
                    
                    // 6. PRIVATE VAULT
                    metroVaultScreen
                        .tag("vault")
                    
                    // 7. GOOGLE CLOUD
                    metroCloudScreen
                        .tag("cloud")
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Windows Phone Application Bar
                metroApplicationBar
            }
        }
        .sheet(item: $selectedMediaItem) { item in
            MediaDetailView(item: Binding(
                get: { selectedMediaItem },
                set: { selectedMediaItem = $0 }
            ))
        }
    }
    
    // MARK: - 1. Live Tiles Start Screen
    private var metroStartScreen: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Permission Denied Metro Alert Banner
                if scanner.permissionDenied {
                    Button(action: {
                        scanner.openSystemSettings()
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title)
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("PHOTOS ACCESS REQUIRED")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(.white)
                                Text("Tap to grant access in Settings to show your photos & videos.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(Color.red.opacity(0.8))
                    }
                }
                
                // Scanning Progress Banner
                if scanner.isScanning {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SCANNING IPHONE CAMERA ROLL...")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white)
                            Text("\(scanner.totalScannedCount) items scanned (\(Int(scanner.scanProgress * 100))%)")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(themeColor.color)
                }
                
                // Row 1: Large 2x2 Photo Live Tile
                Button(action: { selectedPivot = "photos" }) {
                    ZStack(alignment: .bottomLeading) {
                        if let firstPhoto = scanner.photos.first {
                            MediaThumbnailView(item: firstPhoto)
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                                .overlay(Color.black.opacity(0.35))
                        } else {
                            Rectangle()
                                .fill(LinearGradient(colors: [themeColor.color.opacity(0.85), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 180)
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Spacer()
                                Image(systemName: "photo.stack.fill")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            Spacer()
                            Text("camera roll")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(scanner.photos.count) photos • \(scanner.videos.count) videos")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(14)
                    }
                }
                
                // Row 2: Two Medium Tiles (Videos & Documents OCR)
                HStack(spacing: 12) {
                    // Videos Tile
                    Button(action: { selectedPivot = "videos" }) {
                        ZStack(alignment: .bottomLeading) {
                            Rectangle()
                                .fill(Color.purple.opacity(0.9))
                                .aspectRatio(1, contentMode: .fit)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Spacer()
                                    Text("\(scanner.videos.count)")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Image(systemName: "video.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                Text("videos")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                        }
                    }
                    
                    // Documents OCR Tile
                    Button(action: { selectedPivot = "documents" }) {
                        ZStack(alignment: .bottomLeading) {
                            Rectangle()
                                .fill(Color.orange.opacity(0.9))
                                .aspectRatio(1, contentMode: .fit)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Spacer()
                                    Text("\(scanner.allMediaItems.filter { $0.isDocument }.count)")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Image(systemName: "doc.text.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                Text("documents OCR")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                        }
                    }
                }
                
                // Row 3: Two Medium Tiles (People & Screenshots)
                HStack(spacing: 12) {
                    // Face Areas & People Tile
                    Button(action: { selectedPivot = "people" }) {
                        ZStack(alignment: .bottomLeading) {
                            Rectangle()
                                .fill(Color.indigo.opacity(0.9))
                                .aspectRatio(1, contentMode: .fit)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Spacer()
                                    Text("\(scanner.allMediaItems.filter { $0.isFaceGroup }.count)")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Image(systemName: "person.crop.rectangle.stack.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                Text("people")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                        }
                    }
                    
                    // Screenshots Tile
                    Button(action: { selectedPivot = "photos" }) {
                        ZStack(alignment: .bottomLeading) {
                            Rectangle()
                                .fill(Color.teal.opacity(0.9))
                                .aspectRatio(1, contentMode: .fit)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Spacer()
                                    Text("\(scanner.screenshots.count)")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Image(systemName: "camera.viewfinder")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                Text("screenshots")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                        }
                    }
                }
                
                // Row 4: Wide Live Tile - Google Cloud Backup
                Button(action: { selectedPivot = "cloud" }) {
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(themeColor.color)
                            .frame(height: 90)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: googleService.isBackingUp ? "arrow.triangle.2.circlepath.icloud.fill" : "checkmark.icloud.fill")
                                    .foregroundColor(.white)
                                Text("google photos backup")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                if googleService.isBackingUp {
                                    Text("SYNCING")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.yellow)
                                }
                            }
                            Spacer()
                            Text(googleService.isBackingUp ? "Backing up photos to Google Cloud..." : "\(scanner.allMediaItems.count) items ready to backup")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(12)
                    }
                }
                
                // Row 5: Two Medium Tiles (Private Vault & Storage)
                HStack(spacing: 12) {
                    // Private Vault Tile
                    Button(action: { selectedPivot = "vault" }) {
                        ZStack(alignment: .bottomLeading) {
                            Rectangle()
                                .fill(Color(red: 0.75, green: 0.6, blue: 0.0))
                                .aspectRatio(1, contentMode: .fit)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "lock.shield.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Text("\(vaultService.vaultItems.count)")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundColor(.white)
                                Text("private vault")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                        }
                    }
                    
                    // Phone Storage File Manager Tile
                    Button(action: { selectedPivot = "photos" }) {
                        ZStack(alignment: .bottomLeading) {
                            Rectangle()
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
                                .aspectRatio(1, contentMode: .fit)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "internaldrive.fill")
                                        .font(.title3)
                                        .foregroundColor(themeColor.color)
                                }
                                Spacer()
                                Text(fileManagerService.storageBreakdown.formattedPhotosBytes)
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(.white)
                                Text("media storage")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                            .padding(12)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 2. All Photos Metro List with Real Thumbnails
    private var metroAllPhotosList: some View {
        ScrollView {
            if scanner.allMediaItems.isEmpty {
                VStack(spacing: 14) {
                    Spacer().frame(height: 60)
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No Photos Found")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white)
                    Text(scanner.permissionDenied ? "Allow Photo access in Settings to view your photos." : "Your iPhone camera roll is empty.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    if scanner.permissionDenied {
                        Button(action: { scanner.openSystemSettings() }) {
                            Text("Open Settings")
                                .font(.caption.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(themeColor.color)
                                .foregroundColor(.white)
                        }
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)], spacing: 4) {
                    ForEach(scanner.allMediaItems) { item in
                        MediaThumbnailView(item: item)
                            .onTapGesture {
                                selectedMediaItem = item
                            }
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }
    
    // MARK: - 3. Videos Metro List
    private var metroVideosList: some View {
        ScrollView {
            if scanner.videos.isEmpty {
                VStack(spacing: 14) {
                    Spacer().frame(height: 60)
                    Image(systemName: "video.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No Videos Found")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)], spacing: 4) {
                    ForEach(scanner.videos) { video in
                        MediaThumbnailView(item: video)
                            .onTapGesture {
                                selectedMediaItem = video
                            }
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }
    
    // MARK: - 4. Documents OCR Metro View
    private var metroDocumentsList: some View {
        ScrollView {
            let docs = scanner.allMediaItems.filter { $0.isDocument }
            if docs.isEmpty {
                VStack(spacing: 14) {
                    Spacer().frame(height: 60)
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("No Documents Detected Yet")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white)
                    Text("Tap 'Scan Vision' in the Smart Groups tab to analyze photos for receipts, forms, and documents.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(docs) { doc in
                        Button(action: {
                            selectedMediaItem = doc
                        }) {
                            HStack(spacing: 14) {
                                MediaThumbnailView(item: doc)
                                    .frame(width: 55, height: 55)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(doc.filename)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    if let text = doc.detectedText {
                                        Text(text.replacingOccurrences(of: "\n", with: " "))
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - 5. People & Faces Metro View
    private var metroPeopleList: some View {
        ScrollView {
            let faceItems = scanner.allMediaItems.filter { $0.isFaceGroup }
            if faceItems.isEmpty {
                VStack(spacing: 14) {
                    Spacer().frame(height: 60)
                    Image(systemName: "person.crop.rectangle.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.purple)
                    Text("No Faces Detected Yet")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white)
                    Text("Run Apple Vision scan to isolate face areas and cluster portraits from your camera roll.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(faceItems) { personItem in
                        Button(action: {
                            selectedMediaItem = personItem
                        }) {
                            HStack(spacing: 14) {
                                MediaThumbnailView(item: personItem)
                                    .frame(width: 55, height: 55)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(personItem.detectedFaces.first?.personTag ?? "Portrait Shot")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("\(personItem.detectedFaces.count) Face(s) Detected • \(personItem.formattedDate)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - 6. Private Vault Metro View
    private var metroVaultScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(Color.yellow)
            
            Text("PRIVATE VAULT")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.white)
            
            Text("\(vaultService.vaultItems.count) Files • 256-bit AES-GCM Encrypted")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            Button(action: {
                Task {
                    _ = await vaultService.authenticateWithFaceID()
                    if vaultService.isUnlocked {
                        selectedPivot = "photos"
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "faceid")
                    Text("UNLOCK WITH FACE ID")
                }
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(themeColor.color)
                .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 7. Google Cloud Metro View
    private var metroCloudScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("cloud sync")
                .font(.system(size: 26, weight: .light))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Google Account")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(themeColor.color)
                Text(googleService.account.email ?? "Not Connected")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Google One Storage")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(themeColor.color)
                Text(googleService.account.formattedStorageSummary)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                googleService.queueAllForBackup(items: scanner.allMediaItems)
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("BACKUP ALL PHONE PHOTOS (\(scanner.allMediaItems.count))")
                }
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(themeColor.color)
                .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(20)
    }
    
    // MARK: - Windows Phone Application Bar
    private var metroApplicationBar: some View {
        HStack(spacing: 20) {
            // Circle button 1: Photos
            metroCircleButton(icon: "photo.stack", title: "photos") {
                selectedPivot = "photos"
            }
            
            // Circle button 2: Videos
            metroCircleButton(icon: "video.fill", title: "videos") {
                selectedPivot = "videos"
            }
            
            // Circle button 3: Rescan
            metroCircleButton(icon: "arrow.clockwise", title: "rescan") {
                Task {
                    await scanner.startFullLibraryScan()
                }
            }
            
            // Circle button 4: Color Theme
            metroCircleButton(icon: "paintpalette", title: "theme") {
                cycleThemeColor()
            }
            
            Spacer()
            
            // Switch UI mode Button
            Button(action: {
                appUiTheme = "modern"
            }) {
                Image(systemName: "rectangle.grid.2x2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(red: 0.05, green: 0.05, blue: 0.06))
    }
    
    private func metroCircleButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                Text(title)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func cycleThemeColor() {
        let all = MetroThemeColor.allCases
        if let idx = all.firstIndex(of: themeColor) {
            let nextIdx = (idx + 1) % all.count
            themeColor = all[nextIdx]
        }
    }
}
