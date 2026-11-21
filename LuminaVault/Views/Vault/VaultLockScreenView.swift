import SwiftUI
import UIKit

public struct VaultLockScreenView: View {
    @ObservedObject public var viewModel: VaultViewModel
    
    public init(viewModel: VaultViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Shield & Face ID Icon
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "faceid")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
            }
            .onTapGesture {
                viewModel.triggerBiometricUnlock()
            }
            
            VStack(spacing: 6) {
                Text("Private Secure Vault")
                    .font(.title2.bold())
                Text("256-bit Hardware Encrypted Sandbox")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // PIN Dots
            HStack(spacing: 16) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index < viewModel.enteredPin.count ? Color.yellow : Color.gray.opacity(0.3))
                        .frame(width: 14, height: 14)
                }
            }
            .padding(.vertical, 8)
            
            if viewModel.showPinError {
                Text("Incorrect Passcode. Try 1414 or 0000.")
                    .font(.caption.bold())
                    .foregroundColor(.red)
            }
            
            // Keypad (Numeric)
            VStack(spacing: 12) {
                HStack(spacing: 28) {
                    PinKeyButton(digit: "1", sub: "") { viewModel.appendPinDigit("1") }
                    PinKeyButton(digit: "2", sub: "ABC") { viewModel.appendPinDigit("2") }
                    PinKeyButton(digit: "3", sub: "DEF") { viewModel.appendPinDigit("3") }
                }
                HStack(spacing: 28) {
                    PinKeyButton(digit: "4", sub: "GHI") { viewModel.appendPinDigit("4") }
                    PinKeyButton(digit: "5", sub: "JKL") { viewModel.appendPinDigit("5") }
                    PinKeyButton(digit: "6", sub: "MNO") { viewModel.appendPinDigit("6") }
                }
                HStack(spacing: 28) {
                    PinKeyButton(digit: "7", sub: "PQRS") { viewModel.appendPinDigit("7") }
                    PinKeyButton(digit: "8", sub: "TUV") { viewModel.appendPinDigit("8") }
                    PinKeyButton(digit: "9", sub: "WXYZ") { viewModel.appendPinDigit("9") }
                }
                HStack(spacing: 28) {
                    Button(action: {
                        viewModel.triggerBiometricUnlock()
                    }) {
                        Image(systemName: "faceid")
                            .font(.title2)
                            .foregroundColor(.yellow)
                            .frame(width: 72, height: 72)
                    }
                    
                    PinKeyButton(digit: "0", sub: "") { viewModel.appendPinDigit("0") }
                    
                    Button(action: {
                        viewModel.deletePinDigit()
                    }) {
                        Image(systemName: "delete.left.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 72, height: 72)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            viewModel.triggerBiometricUnlock()
        }
    }
}

public struct PinKeyButton: View {
    public let digit: String
    public let sub: String
    public let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(digit)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundColor(.primary)
                if !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 72, height: 72)
            .background(Color(UIColor.secondarySystemFill))
            .clipShape(Circle())
        }
    }
}
