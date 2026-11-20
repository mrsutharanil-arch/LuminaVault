import Foundation
import SwiftUI
import Combine

@MainActor
public class VaultViewModel: ObservableObject {
    @Published public var enteredPin: String = ""
    @Published public var showPinError: Bool = false
    @Published public var selectedVaultItemForDetail: VaultItem? = nil
    @Published public var showSettingsSheet: Bool = false
    
    public var vaultService = PrivateVaultService.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        vaultService.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    public func triggerBiometricUnlock() {
        Task {
            _ = await vaultService.authenticateWithFaceID()
        }
    }
    
    public func appendPinDigit(_ digit: String) {
        guard enteredPin.count < 4 else { return }
        enteredPin.append(digit)
        
        if enteredPin.count == 4 {
            verifyPin()
        }
    }
    
    public func deletePinDigit() {
        guard !enteredPin.isEmpty else { return }
        enteredPin.removeLast()
    }
    
    public func verifyPin() {
        let success = vaultService.unlockWithPasscode(pin: enteredPin)
        if !success {
            showPinError = true
            enteredPin = ""
        } else {
            showPinError = false
            enteredPin = ""
        }
    }
    
    public func restoreItem(item: VaultItem) async {
        _ = await vaultService.restoreToCameraRoll(vaultItem: item)
        if selectedVaultItemForDetail?.id == item.id {
            selectedVaultItemForDetail = nil
        }
    }
    
    public func deletePermanently(item: VaultItem) {
        vaultService.vaultItems.removeAll { $0.id == item.id }
        if selectedVaultItemForDetail?.id == item.id {
            selectedVaultItemForDetail = nil
        }
    }
}
