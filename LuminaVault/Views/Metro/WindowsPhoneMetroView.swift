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
    
    @State private var selectedPivot: String = "start"
    @State private var themeColor: MetroThemeColor = .nokiaCyan
    @State private var showAppBarMenu: Bool = false
    @State private var selectedMediaItem: MediaItem? = nil
    @State private var tileFlipAngle: Double = 0.0
    
    private let pivotSections = ["start", "all", "documents", "people", "vault", "cloud"]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Pure OLED Black Background (Windows Phone Signature)
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Windows Phone Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("LUMINA VAULT")
                        .font(.system(size: 11, weight: .black, design: .default))
                        .tracking(3)
                        .foregroundColor(themeColor.color)
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
                                        .font(.system(size: 38, weight: selectedPivot == section ? .light : .ultraLight, design: .default))
                                        .foregroundColor(selectedPivot == section ? .white : Color.gray.opacity(0.45))
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                }
                .padding(.bottom, 8)
                
                // Pivot Content Pages
                TabView(selection: $selectedPivot) {
                    // 1. START SCREEN (Live Tiles Grid)
                    metroStartScreen
                        .tag("start")
                    
                    // 2. ALL PHOTOS
                    metroAllPhotosList
                        .tag("all")
                    
                    // 3. DOCUMENTS & OCR
                    metroDocumentsList
                        .tag("documents")
                    
                    // 4. PEOPLE & FACES
                    metroPeopleList
                        .tag("people")
                    
                    // 5. PRIVATE VAULT
                    metroVaultScreen
                        .tag("vault")
                    
                    // 6. GOOGLE CLOUD
                    metroCloudScreen
                        .tag("cloud")
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Windows Phone Application Bar
                metroApplicationBar
            }
        }
    }
    
    // MARK: - 1. Live Tiles Start Screen
    private var metroStartScreen: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Row 1: Large 2x2 Photo Live Tile
                Button(action: { selectedPivot = "all" }) {
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(LinearGradient(colors: [themeColor.color.opacity(0.85), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 180)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Spacer()
                                Image(systemName: "photo.stack.fill")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Text("camera roll")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(scanner.allMediaItems.count) photos & videos")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(14)
                    }
                }
                
                // Row 2: Two Medium Tiles (Documents OCR & People)
                HStack(spacing: 12) {
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
                                        .font(.system(size: 28, weight: .light))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Image(systemName: "doc.text.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                Text("documents")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                        }
                    }
                    
                    // Face Areas & People Tile
                    Button(action: { selectedPivot = "people" }) {
                        ZStack(alignment: .bottomLeading) {
                            Rectangle()
                                .fill(Color.purple.opacity(0.9))
                                .aspectRatio(1, contentMode: .fit)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Spacer()
                                    Text("\(scanner.allMediaItems.filter { $0.isFaceGroup }.count)")
                                        .font(.system(size: 28, weight: .light))
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
                }
                
                // Row 3: Wide Live Tile - Google Cloud Backup
                Button(action: { selectedPivot = "cloud" }) {
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(themeColor.color)
                            .frame(height: 90)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: googleService.isBackingUp ? "arrow.triangle.2.circlepath.icloud.fill" : "checkmark.icloud.fill")
                                    .foregroundColor(.white)
                                Text("google photos")
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
                            Text(googleService.isBackingUp ? "Backing up phone library to Google One..." : "Library in sync • 4.8 GB of 15 GB")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(12)
                    }
                }
                
                // Row 4: Two Medium Tiles (Private Vault & Storage)
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
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundColor(.white)
                                Text("private vault")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                        }
                    }
                    
                    // Phone Storage File Manager Tile
                    Button(action: { selectedPivot = "all" }) {
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
                                Text("55.6 GB")
                                    .font(.system(size: 22, weight: .light))
                                    .foregroundColor(.white)
                                Text("free of 128 GB")
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
    
    // MARK: - 2. All Photos Metro List
    private var metroAllPhotosList: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)], spacing: 4) {
                ForEach(scanner.allMediaItems) { item in
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.12))
                            .aspectRatio(1, contentMode: .fit)
                        
                        Image(systemName: item.mediaType.iconName)
                            .font(.title2)
                            .foregroundColor(themeColor.color.opacity(0.8))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        Text(item.filename)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(4)
                            .lineLimit(1)
                    }
                    .onTapGesture {
                        selectedMediaItem = item
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 3. Documents OCR Metro View
    private var metroDocumentsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(scanner.allMediaItems.filter { $0.isDocument }) { doc in
                    HStack(spacing: 14) {
                        Rectangle()
                            .fill(Color.orange.opacity(0.85))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(doc.filename)
                                .font(.system(size: 15, weight: .bold))
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
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 4. People & Faces Metro View
    private var metroPeopleList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(scanner.allMediaItems.filter { $0.isFaceGroup }) { personItem in
                    HStack(spacing: 14) {
                        Rectangle()
                            .fill(Color.purple.opacity(0.85))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(personItem.detectedFaces.first?.personTag ?? "Detected Portrait")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(personItem.detectedFaces.count) Faces • \(personItem.areaName ?? "Location")")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 5. Private Vault Metro View
    private var metroVaultScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(Color.yellow)
            
            Text("PRIVATE VAULT")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.white)
            
            Text("256-bit AES-GCM Encrypted Sandbox")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            Button(action: {
                Task {
                    _ = await vaultService.authenticateWithFaceID()
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
    
    // MARK: - 6. Google Cloud Metro View
    private var metroCloudScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("cloud sync")
                .font(.system(size: 26, weight: .light))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Google Account")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(themeColor.color)
                Text(googleService.account.email ?? "user.iphone14@gmail.com")
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
                    Text("BACKUP ALL PHONE PHOTOS")
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
            // Circle button 1: Search
            metroCircleButton(icon: "magnifyingglass", title: "search") {
                selectedPivot = "all"
            }
            
            // Circle button 2: Sync
            metroCircleButton(icon: "arrow.triangle.2.circlepath", title: "sync") {
                googleService.queueAllForBackup(items: scanner.allMediaItems)
            }
            
            // Circle button 3: Vault
            metroCircleButton(icon: "lock.shield", title: "vault") {
                selectedPivot = "vault"
            }
            
            // Circle button 4: Color Theme
            metroCircleButton(icon: "paintpalette", title: "theme") {
                cycleThemeColor()
            }
            
            Spacer()
            
            // Three Dots (...)
            Button(action: {
                showAppBarMenu.toggle()
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
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
