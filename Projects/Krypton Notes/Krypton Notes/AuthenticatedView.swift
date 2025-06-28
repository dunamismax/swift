import SwiftUI

struct AuthenticatedView<Content: View>: View {
    @EnvironmentObject var authService: LocalAuthenticationService
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack {
            switch authService.state {
            case .initial, .authenticating:
                // Show a loading/locked view
                VStack {
                    Text("Krypton Notes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                    Text("Authenticating...")
                }
            case .success:
                // Authentication successful, show the main content
                content()
            case .failure:
                // Authentication failed, show a locked screen with a retry button
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.largeTitle)
                    Text("Authentication Required")
                        .font(.headline)
                    Button("Try Again") {
                        authService.authenticate()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            // Trigger authentication as soon as this view appears
            if authService.state != .success {
                authService.authenticate()
            }
        }
    }
}
