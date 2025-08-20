
import Foundation
import AVFoundation
import SwiftUI

// MARK: - Enums and Structs

enum UpmixFormat: String, CaseIterable {
    case surround5_1 = "5.1 Surround"
    case surround7_1 = "7.1 PCM"
    case dtsMasterAudio = "DTS Master Audio"
    case atmos = "Dolby Atmos"
    
    var channels: Int {
        switch self {
        case .surround5_1:
            return 6
        case .surround7_1:
            return 8
        case .dtsMasterAudio:
            return 6 // DTS-HD Master Audio typically uses 5.1 or 7.1, we'll use 5.1 as base
        case .atmos:
            return 8 // Using 7.1 bed layer for Atmos
        }
    }
    
    var fileSuffix: String {
        switch self {
        case .surround5_1:
            return "_5.1"
        case .surround7_1:
            return "_7.1"
        case .dtsMasterAudio:
            return "_DTS-MA"
        case .atmos:
            return "_Dolby_Atmos"
        }
    }
    
    var codec: String {
        switch self {
        case .surround5_1, .surround7_1:
            return "flac"
        case .dtsMasterAudio:
            return "dts"
        case .atmos:
            return "flac" // Using FLAC for Dolby Atmos bed layer
        }
    }
}

enum AudioQuality: String, CaseIterable {
    case cd_quality = "16-bit / 44.1 kHz"
    case dvd_quality = "24-bit / 48 kHz"
    case bluray_standard = "24-bit / 96 kHz"
    case bluray_premium = "24-bit / 192 kHz"
    case studio_float = "32-bit Float / 96 kHz"
    case studio_float_192 = "32-bit Float / 192 kHz"
    
    var bitDepth: String {
        switch self {
        case .cd_quality:
            return "16"
        case .dvd_quality, .bluray_standard, .bluray_premium:
            return "24"
        case .studio_float, .studio_float_192:
            return "32"
        }
    }
    
    var sampleRate: String {
        switch self {
        case .cd_quality:
            return "44100"
        case .dvd_quality:
            return "48000"
        case .bluray_standard, .studio_float:
            return "96000"
        case .bluray_premium, .studio_float_192:
            return "192000"
        }
    }
    
    var isFloat: Bool {
        switch self {
        case .studio_float, .studio_float_192:
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        return rawValue
    }
    
    var fileSuffix: String {
        switch self {
        case .cd_quality:
            return "_16-44"
        case .dvd_quality:
            return "_24-48"
        case .bluray_standard:
            return "_24-96"
        case .bluray_premium:
            return "_24-192"
        case .studio_float:
            return "_32f-96"
        case .studio_float_192:
            return "_32f-192"
        }
    }
}

enum FileStatus: String {
    case pending = "Pending"
    case processing = "Processing..."
    case upmixed = "Upmixed"
    case failed = "Failed"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .pending: return .secondary
        case .processing: return .accentColor
        case .upmixed: return .green
        case .failed: return .red
        case .cancelled: return .orange
        }
    }
}

enum UpmixError: LocalizedError {
    case ffmpegNotFound
    case processFailed(String)
    case operationCancelled
    case bookmarkFailed

    var errorDescription: String? {
        switch self {
        case .ffmpegNotFound:
            return "FFmpeg executable not found in the app bundle."
        case .processFailed(let message):
            return "The upmix operation failed: \(message)"
        case .operationCancelled:
            return "The upmix operation was cancelled."
        case .bookmarkFailed:
            return "Failed to create a security-scoped bookmark for file access."
        }
    }
}

struct BookmarkedURL: Identifiable {
    let id = UUID()
    let bookmarkData: Data
    let originalURL: URL
}

struct AudioFile: Identifiable {
    let id = UUID()
    let bookmarkedURL: BookmarkedURL
    var status: FileStatus = .pending
    
    var url: URL {
        // This will be a security-scoped URL
        var isStale = false
        guard let resolvedURL = try? URL(resolvingBookmarkData: bookmarkedURL.bookmarkData,
                                         options: .withSecurityScope,
                                         relativeTo: nil,
                                         bookmarkDataIsStale: &isStale) else {
            // Fallback to original URL, though access may fail
            return bookmarkedURL.originalURL
        }
        
        if isStale {
            // Handle stale bookmark data if necessary
            print("Warning: Bookmark data is stale for \(bookmarkedURL.originalURL.lastPathComponent)")
        }
        
        return resolvedURL
    }
}

// MARK: - AudioUpmixer Class

@MainActor
class AudioUpmixer: ObservableObject {
    @Published var files: [AudioFile] = []
    @Published var isUpmixing = false
    @Published var progress: Double = 0.0
    @Published var status: String = "Ready"
    @Published var errorMessage: String?
    @Published var outputDirectory: BookmarkedURL?
    @Published var selectedFormat: UpmixFormat = .surround5_1
    @Published var selectedQuality: AudioQuality = .bluray_standard

    private var ffmpegPath: String?
    private var currentProcess: Process?
    private var isCancelled = false

    init() {
        self.ffmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil)
        validateFFmpegAvailability()
    }
    
    private func validateFFmpegAvailability() {
        if ffmpegPath == nil {
            status = "Warning: FFmpeg not found in app bundle"
        } else if let path = ffmpegPath, !FileManager.default.isExecutableFile(atPath: path) {
            status = "Warning: FFmpeg is not executable"
        }
    }

    // MARK: - Public Methods

    func setOutputDirectory(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            handleError(UpmixError.bookmarkFailed)
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            self.outputDirectory = BookmarkedURL(bookmarkData: bookmarkData, originalURL: url)
        } catch {
            handleError(UpmixError.bookmarkFailed)
        }
    }
    
    func addFile(url: URL) {
        // Check if already accessing security scope (from drag & drop)
        let wasAlreadyAccessing = url.path.hasPrefix("/")
        
        if !wasAlreadyAccessing {
            guard url.startAccessingSecurityScopedResource() else {
                handleError(UpmixError.bookmarkFailed)
                return
            }
        }
        
        defer {
            if !wasAlreadyAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            let bookmarkedURL = BookmarkedURL(bookmarkData: bookmarkData, originalURL: url)
            
            if !files.contains(where: { $0.bookmarkedURL.originalURL == url }) {
                files.append(AudioFile(bookmarkedURL: bookmarkedURL))
            }
        } catch {
            let errorMsg = "Failed to create security-scoped bookmark for '\(url.lastPathComponent)': \(error.localizedDescription)"
            handleError(UpmixError.processFailed(errorMsg))
        }
    }

    func clearFiles() {
        guard !isUpmixing else { return }
        files.removeAll()
        resetStatus()
    }

    func startUpmixing() {
        guard !files.isEmpty, !isUpmixing else { return }
        guard ffmpegPath != nil else {
            handleError(UpmixError.ffmpegNotFound)
            return
        }
        guard outputDirectory != nil else {
            handleError(UpmixError.processFailed("Please select an output directory first."))
            return
        }

        isUpmixing = true
        isCancelled = false
        resetStatus()
        status = "Starting upmix..."

        Task {
            await processFiles()
            
            if !isCancelled {
                let successCount = files.filter { $0.status == .upmixed }.count
                status = "Upmixing complete. Successfully processed \(successCount) of \(totalFiles) files."
            }
            isUpmixing = false
        }
    }
    
    func cancelUpmixing() {
        isCancelled = true
        currentProcess?.terminate()
        status = "Cancelling..."
    }

    // MARK: - Private Methods

    private func processFiles() async {
        let totalFiles = files.count
        for i in 0..<files.count {
            if isCancelled {
                await handleCancellation(from: i)
                break
            }
            
            let file = files[i]
            
            guard file.url.startAccessingSecurityScopedResource() else {
                await updateFileStatus(at: i, to: .failed)
                handleError(UpmixError.processFailed("Could not access file at \(file.bookmarkedURL.originalURL.lastPathComponent)"))
                continue
            }
            
            await updateFileStatus(at: i, to: .processing, message: "Upmixing \(file.bookmarkedURL.originalURL.lastPathComponent) (\(i + 1) of \(totalFiles))...")

            do {
                try await upmix(file: file)
                await updateFileStatus(at: i, to: .upmixed)
            } catch {
                if isCancelled {
                    await handleCancellation(from: i)
                    break
                }
                await updateFileStatus(at: i, to: .failed)
                handleError(error)
                break
            }
            
            file.url.stopAccessingSecurityScopedResource()
            
            progress = Double(i + 1) / Double(totalFiles)
        }
    }

    private func upmix(file: AudioFile) async throws {
        guard let ffmpegPath = ffmpegPath else { throw UpmixError.ffmpegNotFound }
        guard let outputDir = outputDirectory else { throw UpmixError.processFailed("Output directory not set.") }

        var isStale = false
        guard let outputDirURL = try? URL(resolvingBookmarkData: outputDir.bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            throw UpmixError.bookmarkFailed
        }
        
        guard outputDirURL.startAccessingSecurityScopedResource() else {
            throw UpmixError.processFailed("Could not access output directory.")
        }
        defer { outputDirURL.stopAccessingSecurityScopedResource() }

        let outputFileName = file.bookmarkedURL.originalURL.deletingPathExtension().lastPathComponent + selectedFormat.fileSuffix + selectedQuality.fileSuffix + "." + selectedFormat.codec
        let outputURL = outputDirURL.appendingPathComponent(outputFileName)
        
        let filter = createFFmpegFilter(for: selectedFormat)

        var arguments = [
            "-i", file.url.path,
            "-vn",
            "-filter_complex", filter,
            "-c:a", selectedFormat.codec
        ]
        
        // Add quality-specific arguments for FLAC files
        if selectedFormat.codec == "flac" {
            if selectedQuality.isFloat {
                arguments.append(contentsOf: ["-sample_fmt", "flt"])
                arguments.append(contentsOf: ["-ar", selectedQuality.sampleRate])
            } else {
                arguments.append(contentsOf: ["-sample_fmt", "s\(selectedQuality.bitDepth)"])
                arguments.append(contentsOf: ["-ar", selectedQuality.sampleRate])
            }
        } else if selectedFormat.codec == "dts" {
            // For DTS, use PCM with specified bit depth and sample rate
            arguments.append(contentsOf: ["-ar", selectedQuality.sampleRate])
        }
        
        arguments.append(contentsOf: ["-y", outputURL.path])

        currentProcess = Process()
        currentProcess?.executableURL = URL(fileURLWithPath: ffmpegPath)
        currentProcess?.arguments = arguments

        let errorPipe = Pipe()
        currentProcess?.standardError = errorPipe

        do {
            try currentProcess?.run()
            currentProcess?.waitUntilExit()

            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

            if currentProcess?.terminationStatus != 0 {
                if isCancelled {
                    throw UpmixError.operationCancelled
                } else {
                    throw UpmixError.processFailed(errorOutput)
                }
            }
        } catch {
            throw UpmixError.processFailed(error.localizedDescription)
        }
    }
    
    private func createFFmpegFilter(for format: UpmixFormat) -> String {
        switch format {
        case .surround5_1:
            // Standard 5.1 surround sound upmixing
            return "[0:a]pan=5.1(side)|FL=FL|FR=FR|FC=0.5*FL+0.5*FR|LFE=0.1*FL+0.1*FR|SL=0.5*FL|SR=0.5*FR"
            
        case .surround7_1:
            // 7.1 surround sound upmixing
            return "[0:a]pan=7.1|FL=FL|FR=FR|FC=0.5*FL+0.5*FR|LFE=0.1*FL+0.1*FR|SL=0.3*FL|SR=0.3*FR|BL=0.2*FL|BR=0.2*FR"
            
        case .dtsMasterAudio:
            // DTS Master Audio - using 5.1 layout with optimized channel mapping
            return "[0:a]pan=5.1(side)|FL=FL|FR=FR|FC=0.6*FL+0.6*FR|LFE=0.15*FL+0.15*FR|SL=0.4*FL|SR=0.4*FR"
            
        case .atmos:
            // Dolby Atmos bed layer - using 7.1 as base with enhanced center and surround channels
            return "[0:a]pan=7.1|FL=FL|FR=FR|FC=0.7*FL+0.7*FR|LFE=0.2*FL+0.2*FR|SL=0.4*FL|SR=0.4*FR|BL=0.3*FL|BR=0.3*FR"
        }
    }
    
    private func handleCancellation(from index: Int) async {
        for i in index..<files.count {
            await updateFileStatus(at: i, to: .cancelled)
        }
        status = "Upmix operation cancelled."
        progress = 1.0 // Show completion of cancellation
    }

    private func updateFileStatus(at index: Int, to newStatus: FileStatus, message: String? = nil) async {
        guard index < files.count else { return }
        files[index].status = newStatus
        if let message = message {
            status = message
        }
    }

    private func handleError(_ error: Error) {
        if let upmixError = error as? UpmixError {
            self.errorMessage = upmixError.localizedDescription
        } else {
            self.errorMessage = error.localizedDescription
        }
        self.status = "An error occurred."
    }
    
    private func resetStatus() {
        progress = 0.0
        if ffmpegPath != nil {
            status = "Ready"
        } else {
            status = "Warning: FFmpeg not found"
        }
        errorMessage = nil
    }
}

