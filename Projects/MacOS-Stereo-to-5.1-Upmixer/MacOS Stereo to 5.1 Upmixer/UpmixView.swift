import SwiftUI
import UniformTypeIdentifiers

struct UpmixView: View {
    @StateObject private var upmixer = AudioUpmixer()
    @State private var isFileImporterPresented = false
    @State private var showingErrorAlert = false
    @State private var importerConfig = ImporterConfig()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            
            FileListView(files: $upmixer.files) { urls in
                handleFilesDropped(urls: urls)
            }
            
            OutputDirectoryView(
                outputDirectory: upmixer.outputDirectory?.originalURL,
                onSelectDirectory: {
                    importerConfig.isDirectoryPicker = true
                    isFileImporterPresented = true
                }
            )
            
            FormatSelectionView(selectedFormat: $upmixer.selectedFormat)
            
            StatusBarView(status: upmixer.status, progress: upmixer.progress)
            
            FooterView(
                onSelectFiles: {
                    importerConfig.isDirectoryPicker = false
                    isFileImporterPresented = true
                },
                onUpmix: { upmixer.startUpmixing() },
                onClear: { upmixer.clearFiles() },
                onCancel: { upmixer.cancelUpmixing() },
                isUpmixing: upmixer.isUpmixing,
                canUpmix: !upmixer.files.isEmpty && !upmixer.isUpmixing && upmixer.outputDirectory != nil,
                canClear: !upmixer.files.isEmpty && !upmixer.isUpmixing,
                selectedFormat: upmixer.selectedFormat
            )
        }
        .frame(minWidth: 500, minHeight: 540)
        .background(Color.theme.background)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: importerConfig.allowedContentTypes,
            allowsMultipleSelection: importerConfig.allowsMultipleSelection
        ) { result in
            if importerConfig.isDirectoryPicker {
                handleDirectoryPick(result: result)
            } else {
                handleFileImport(result: result)
            }
        }
        .onChange(of: upmixer.errorMessage) { _, newValue in
            if newValue != nil {
                showingErrorAlert = true
            }
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(upmixer.errorMessage ?? "An unknown error occurred."),
                dismissButton: .default(Text("OK")) { 
                    upmixer.errorMessage = nil
                }
            )
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            urls.forEach { upmixer.addFile(url: $0) }
        case .failure(let error):
            upmixer.errorMessage = "Failed to import files: \(error.localizedDescription)"
        }
    }
    
    private func handleDirectoryPick(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                upmixer.setOutputDirectory(url: url)
            }
        case .failure(let error):
            upmixer.errorMessage = "Failed to select directory: \(error.localizedDescription)"
        }
    }
    
    private func handleFilesDropped(urls: [URL]) {
        var audioUrls: [URL] = []
        var hasDirectories = false
        
        for url in urls {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    hasDirectories = true
                    // Recursively find audio files in directory
                    if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                        for case let fileURL as URL in enumerator {
                            if isAudioFile(url: fileURL) {
                                audioUrls.append(fileURL)
                            }
                        }
                    }
                } else if isAudioFile(url: url) {
                    audioUrls.append(url)
                }
            }
        }
        
        // Add found audio files
        for audioUrl in audioUrls {
            upmixer.addFile(url: audioUrl)
        }
        
        if audioUrls.isEmpty && !hasDirectories {
            upmixer.errorMessage = "No supported audio files found in the dropped items."
        } else if audioUrls.isEmpty && hasDirectories {
            upmixer.errorMessage = "No supported audio files found in the dropped directories."
        }
    }
    
    private func isAudioFile(url: URL) -> Bool {
        let audioExtensions = ["mp3", "wav", "flac", "aac", "m4a", "ogg", "wma", "aiff", "au"]
        let fileExtension = url.pathExtension.lowercased()
        return audioExtensions.contains(fileExtension)
    }
}

private struct ImporterConfig {
    var isDirectoryPicker = false
    
    var allowedContentTypes: [UTType] {
        isDirectoryPicker ? [.folder] : [.audio]
    }
    
    var allowsMultipleSelection: Bool {
        !isDirectoryPicker
    }
}

// MARK: - Subviews

struct HeaderView: View {
    var body: some View {
        VStack {
            Text("Stereo Upmixer Suite")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(Color.theme.text)
            Text("Click 'Select Files' or drag files into the window")
                .font(.headline)
                .foregroundColor(Color.theme.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct FileListView: View {
    @Binding var files: [AudioFile]
    var onFilesDropped: ([URL]) -> Void
    
    @State private var isDropTargeted = false
    
    var body: some View {
        ZStack {
            if files.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.theme.dropTargetBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(isDropTargeted ? Color.theme.accent : Color.theme.dropTargetBorder)
                    )
                
                VStack {
                    Image(systemName: "music.note.list")
                        .font(.largeTitle)
                    Text("Drop audio files here or click 'Select Files'")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(Color.theme.secondaryText)
            } else {
                List {
                    ForEach($files) { $file in
                        FileRowView(file: $file)
                    }
                }
                .listStyle(.inset)
                .background(Color.theme.listBackground)
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                group.enter()
                provider.loadObject(ofClass: URL.self) { url, error in
                    defer { group.leave() }
                    if let url = url {
                        urls.append(url)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                onFilesDropped(urls)
            }
        }
        
        return !providers.isEmpty
    }
}

struct FileRowView: View {
    @Binding var file: AudioFile
    
    var body: some View {
        HStack {
            Image(systemName: "waveform.path")
                .font(.title)
                .foregroundColor(file.status.color)
            
            VStack(alignment: .leading) {
                Text(file.bookmarkedURL.originalURL.lastPathComponent).fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(Color.theme.text)
                Text(file.status.rawValue)
                    .font(.caption)
                    .foregroundColor(file.status.color)
            }
            
            Spacer()
            
            if file.status == .processing {
                ProgressView().scaleEffect(0.8)
            }
        }
        .padding(.vertical, 8)
    }
}

struct OutputDirectoryView: View {
    let outputDirectory: URL?
    var onSelectDirectory: () -> Void
    
    var body: some View {
        HStack {
            Text("Output To:")
                .font(.headline)
            
            TextField("Select an output directory", text: .constant(outputDirectory?.path ?? ""))
                .textFieldStyle(.roundedBorder)
                .disabled(true)
            
            Button(action: onSelectDirectory) {
                Image(systemName: "folder.badge.plus")
            }
        }
        .padding()
    }
}

struct FormatSelectionView: View {
    @Binding var selectedFormat: UpmixFormat
    
    var body: some View {
        HStack {
            Text("Upmix Format:")
                .font(.headline)
            
            Picker("Format", selection: $selectedFormat) {
                ForEach(UpmixFormat.allCases, id: \.self) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
            
            Spacer()
        }
        .padding()
    }
}

struct StatusBarView: View {
    let status: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(status)
                .font(.caption)
                .foregroundColor(Color.theme.secondaryText)
                .lineLimit(1)
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .accentColor(Color.theme.accent)
        }
        .padding()
    }
}

struct FooterView: View {
    var onSelectFiles: () -> Void
    var onUpmix: () -> Void
    var onClear: () -> Void
    var onCancel: () -> Void
    var isUpmixing: Bool
    var canUpmix: Bool
    var canClear: Bool
    var selectedFormat: UpmixFormat

    var body: some View {
        HStack {
            Button(action: onSelectFiles) {
                Label("Select Files", systemImage: "doc.badge.plus")
            }
            .disabled(isUpmixing)
            
            Spacer()
            
            Button(role: .destructive, action: onClear) {
                Label("Clear", systemImage: "xmark.circle")
            }
            .disabled(!canClear)
            
            if isUpmixing {
                Button(role: .destructive, action: onCancel) {
                    Label("Cancel", systemImage: "stop.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button(action: onUpmix) {
                    Text("Upmix to \(selectedFormat.rawValue)")
                }
                .buttonStyle(.bordered)
                .disabled(!canUpmix)
            }
        }
        .padding()
        .background(Material.ultraThin)
    }
}

// MARK: - Theme

extension Color {
    static let theme = Theme()
}

struct Theme {
    let accent = Color("AccentColor")
    let background = Color(.windowBackgroundColor)
    let text = Color(.textColor)
    let secondaryText = Color(.secondaryLabelColor)
    let dropTargetBackground = Color.black.opacity(0.1)
    let dropTargetBorder = Color.secondary.opacity(0.8)
    let listBackground = Color.black.opacity(0.1)
}

struct UpmixView_Previews: PreviewProvider {
    static var previews: some View {
        UpmixView()
    }
}