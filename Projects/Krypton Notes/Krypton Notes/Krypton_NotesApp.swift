//
//  Krypton_NotesApp.swift
//  Krypton Notes
//
//  Created by Stephen Sawyer on 6/28/25.
//

import SwiftUI
import SwiftData

@main
struct Krypton_NotesApp: App {
    @StateObject private var authService = LocalAuthenticationService()
    @Environment(\.scenePhase) private var scenePhase

    // Define the shared model container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Note.self,
        ])
        
        // Explicitly configure the model for iCloud sync with the correct initializer
        let modelConfiguration = ModelConfiguration(
            "KryptonNotesConfiguration", // A name for this configuration
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .private("iCloud.com.dunamismax.Krypton-Notes")
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Ensure the EncryptionService is initialized once.
            _ = EncryptionService()
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            // The main view is now wrapped in a view that handles the authentication state
            AuthenticatedView {
                ContentView()
            }
            .environmentObject(authService)
        }
        .modelContainer(sharedModelContainer) // Inject the container into the environment
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // When the app becomes active, trigger authentication
            if newPhase == .active && authService.state != .success {
                authService.authenticate()
            }
            // When the app goes to the background, reset the auth state
            // so it's required again on next launch.
            if newPhase == .background {
                authService.reset()
            }
        }
    }
}
