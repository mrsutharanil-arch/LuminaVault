import Foundation
import SwiftUI

@MainActor
public class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var isFirstLaunch: Bool = false
    @Published public var activeModalSheet: String? = nil
    
    public init() {
        let launched = UserDefaults.standard.bool(forKey: "has_launched_before")
        if !launched {
            self.isFirstLaunch = true
            UserDefaults.standard.set(true, forKey: "has_launched_before")
        }
    }
}
