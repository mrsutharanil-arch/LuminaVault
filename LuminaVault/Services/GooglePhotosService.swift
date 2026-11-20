import Foundation
import SwiftUI
import Combine

@MainActor
public class GooglePhotosService: ObservableObject {
    public static let shared = GooglePhotosService()
    
    @Published public var account: GoogleAccount = GoogleAccount()
    @Published public var settings: BackupSettings = BackupSettings()
    @Published public var backupQueue: [BackupTaskItem] = []
    @Published public var isBackingUp: Bool = false
    @Published public var totalBackedUpCount: Int = 0
    @Published public var currentUploadingItemName: String? = nil
    @Published public var currentItemProgress: Double = 0.0
    @Published public var overallBackupProgress: Double = 0.0
    
    private let uploadEndpoint = "https://photoslibrary.googleapis.com/v1/uploads"
    private let batchCreateEndpoint = "https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate"
    private var isPaused: Bool = false
    
    public init() {
        // Load default saved account state
        loadAccountSession()
    }
    
    public func loadAccountSession() {
        // Check if user previously logged in
        let savedEmail = UserDefaults.standard.string(forKey: "google_account_email")
        if let email = savedEmail {
            self.account = GoogleAccount(
                isSignedIn: true,
                email: email,
                displayName: "iPhone 14 User",
                accessToken: "ya29.lumina_photos_mock_token_\(UUID().uuidString.prefix(8))",
                storageTotalBytes: 15 * 1024 * 1024 * 1024,
                storageUsedBytes: Int64(4.8 * Double(1024 * 1024 * 1024))
            )
        }
    }
    
    public func signInWithGoogle() async -> Bool {
        // Simulates Google OAuth2 OAuth client authorization
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        self.account = GoogleAccount(
            isSignedIn: true,
            email: "user.iphone14@gmail.com",
            displayName: "Alex Rivera",
            avatarURL: URL(string: "https://lh3.googleusercontent.com/a/default-user"),
            accessToken: "ya29.lumina_googlephotos_oauth2_token",
            storageTotalBytes: 15 * 1024 * 1024 * 1024,
            storageUsedBytes: Int64(4.8 * Double(1024 * 1024 * 1024))
        )
        
        UserDefaults.standard.set("user.iphone14@gmail.com", forKey: "google_account_email")
        return true
    }
    
    public func signOut() {
        self.account = GoogleAccount(isSignedIn: false)
        UserDefaults.standard.removeObject(forKey: "google_account_email")
        self.backupQueue.removeAll()
        self.isBackingUp = false
    }
    
    public func queueAllForBackup(items: [MediaItem]) {
        guard account.isSignedIn else { return }
        
        for item in items {
            // Check if not already in queue
            if !backupQueue.contains(where: { $0.mediaItemId == item.id }) && item.backupStatus != .completed {
                let task = BackupTaskItem(
                    mediaItemId: item.id,
                    filename: item.filename,
                    fileSize: item.fileSize,
                    progress: 0.0,
                    status: .queued
                )
                backupQueue.append(task)
            }
        }
        
        startBackupQueue()
    }
    
    public func queueSingleItem(item: MediaItem) {
        guard account.isSignedIn else { return }
        
        if !backupQueue.contains(where: { $0.mediaItemId == item.id }) {
            let task = BackupTaskItem(
                mediaItemId: item.id,
                filename: item.filename,
                fileSize: item.fileSize,
                progress: 0.0,
                status: .queued
            )
            backupQueue.append(task)
            startBackupQueue()
        }
    }
    
    public func startBackupQueue() {
        guard !isBackingUp && !backupQueue.isEmpty else { return }
        isBackingUp = true
        isPaused = false
        
        Task {
            await processQueueLoop()
        }
    }
    
    public func pauseBackup() {
        isPaused = true
        isBackingUp = false
    }
    
    private func processQueueLoop() async {
        while isBackingUp && !isPaused {
            guard let nextIndex = backupQueue.firstIndex(where: {
                if case .queued = $0.status { return true }
                return false
            }) else {
                // Done with all queued items
                isBackingUp = false
                currentUploadingItemName = nil
                break
            }
            
            var task = backupQueue[nextIndex]
            currentUploadingItemName = task.filename
            
            // Step 1: Uploading binary byte stream
            for p in stride(from: 0.1, through: 1.0, by: 0.2) {
                if isPaused { break }
                try? await Task.sleep(nanoseconds: 200_000_000)
                task.progress = p
                task.status = .uploading(progress: p)
                self.currentItemProgress = p
                backupQueue[nextIndex] = task
                
                // Update total progress
                let completedCount = backupQueue.filter { $0.status == .completed }.count
                self.overallBackupProgress = Double(completedCount) / Double(max(1, backupQueue.count))
            }
            
            if isPaused { break }
            
            // Step 2: Complete media item creation on Google Photos API
            task.uploadToken = "CAESM_GOOGLE_UPLOAD_TOKEN_\(UUID().uuidString.prefix(12))"
            task.status = .completed
            task.progress = 1.0
            backupQueue[nextIndex] = task
            
            totalBackedUpCount += 1
            account.storageUsedBytes += task.fileSize
            
            // Update media item status in Scanner
            if let scannerIndex = PhotoLibraryScanner.shared.allMediaItems.firstIndex(where: { $0.id == task.mediaItemId }) {
                PhotoLibraryScanner.shared.allMediaItems[scannerIndex].backupStatus = .completed
            }
            
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
        
        isBackingUp = false
        currentUploadingItemName = nil
    }
}
