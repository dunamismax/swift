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
            
            FileListView(files: $upmixer.files)
            
            OutputDirectoryView(
                outputDirectory: upmixer.outputDirectory?.originalURL,
                onSelectDirectory: {
                    importerConfig.isDirectoryPicker = true
                    isFileImporterPresented = true
                }
            )
            
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
                canClear: !upmixer.files.isEmpty && !upmixer.isUpmixing
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
            Text("Stereo to 5.1 Upmixer")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(Color.theme.text)
            Text("Click the 'Select Files' button to begin")
                .font(.headline)
                .foregroundColor(Color.theme.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct FileListView: View {
    @Binding var files: [AudioFile]
    
    var body: some View {
        ZStack {
            if files.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.theme.dropTargetBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(Color.theme.dropTargetBorder)
                    )
                
                VStack {
                    Image(systemName: "music.note.list")
                        .font(.largeTitle)
                    Text("No files selected")
                        .font(.headline)
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
                    Text("Upmix to 5.1")
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