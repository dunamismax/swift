import Foundation
import LocalAuthentication
import Combine

enum AuthenticationState {
    case initial
    case authenticating
    case success
    case failure
}

@MainActor
class LocalAuthenticationService: ObservableObject {
    @Published var state: AuthenticationState = .initial
    
    private var context = LAContext()

    init() {
        // Configure the context
        context.localizedCancelTitle = "Enter Password" // Fallback button title
    }

    func authenticate() {
        self.state = .authenticating
        
        var error: NSError?
        let reason = "Please authenticate to access your secure notes."

        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            Task {
                do {
                    let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                    if success {
                        self.state = .success
                    } else {
                        // This case is less common, but could happen.
                        self.state = .failure
                    }
                } catch {
                    // Handle errors like user cancellation, fallback, etc.
                    print("Authentication failed: \(error.localizedDescription)")
                    self.state = .failure
                }
            }
        } else {
            // Biometrics not available, handle appropriately.
            // For this app, we will treat it as a failure to enforce security.
            print("Biometrics not available.")
            self.state = .failure
        }
    }
    
    /// Resets the authentication state, allowing for a new authentication attempt.
    /// This is useful when the app returns from the background.
    func reset() {
        // Create a new context for the next authentication attempt
        context = LAContext()
        context.localizedCancelTitle = "Enter Password"
        self.state = .initial
    }
}
