import SwiftUI
import SwiftData
import MarkdownUI

// MARK: - Main Content View
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedNote: Note?
    @State private var selectedSection: NoteSection = .all
    @State private var searchText = ""
    @State private var searchScope: SearchScope = .title
    
    private let encryptionService = EncryptionService()

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSection)
        } content: {
            NoteListView(
                selection: $selectedNote,
                searchText: $searchText,
                filter: noteFilter
            )
        } detail: {
            if let selectedNote {
                NoteDetailView(note: selectedNote, encryptionService: encryptionService)
                    .id(selectedNote.id)
            } else {
                ContentUnavailableView("Select a Note", systemImage: "note.text", description: Text("Choose a note from the list to view its content, or create a new one."))
            }
        }
        .searchable(text: $searchText, prompt: "Search Notes")
        .searchScopes($searchScope) {
            Text("Title").tag(SearchScope.title)
            Text("Content").tag(SearchScope.content)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addNote) {
                    Label("New Note", systemImage: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
    
    private var noteFilter: (Note) -> Bool {
        let searchPredicate: (Note) -> Bool
        if searchText.isEmpty {
            searchPredicate = { _ in true }
        } else {
            searchPredicate = { note in
                let textToSearch = searchText.lowercased()
                if searchScope == .title {
                    return note.title.lowercased().contains(textToSearch)
                } else {
                    // For content search, we must decrypt on the fly. This can be slow for large notes.
                    if let decrypted = try? encryptionService.decrypt(data: note.encryptedContent) {
                        return note.title.lowercased().contains(textToSearch) || decrypted.lowercased().contains(textToSearch)
                    }
                    return false
                }
            }
        }
        
        switch selectedSection {
        case .all:
            return searchPredicate
        case .favorites:
            return { note in note.isFavorite && searchPredicate(note) }
        case .category(let category):
            return { note in note.category == category && searchPredicate(note) }
        }
    }

    private func addNote() {
        do {
            let encryptedContent = try encryptionService.encrypt(string: "# New Note\n\nStart writing your brilliant ideas here!")
            
            let category: String?
            if case .category(let categoryName) = selectedSection {
                category = categoryName
            } else {
                category = nil
            }
            
            let newNote = Note(
                title: "New Note",
                encryptedContent: encryptedContent,
                category: category
            )
            
            modelContext.insert(newNote)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedNote = newNote
            }
        } catch {
            print("Failed to create new note: \(error)")
        }
    }
}

// MARK: - Search Scope
enum SearchScope: String, CaseIterable {
    case title = "Title"
    case content = "Title & Content"
}

// MARK: - Sidebar
enum NoteSection: Hashable, Identifiable {
    case all
    case favorites
    case category(String)
    
    var id: String {
        switch self {
        case .all: return "all"
        case .favorites: return "favorites"
        case .category(let name): return "category-\(name)"
        }
    }
}

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.category) private var notes: [Note]
    @Binding var selection: NoteSection
    
    @State private var isShowingRenameAlert = false
    @State private var isShowingDeleteAlert = false
    @State private var categoryToRename: String?
    @State private var newCategoryName = ""

    private var categories: [String] {
        Array(Set(notes.compactMap { $0.category })).sorted()
    }

    var body: some View {
        List(selection: $selection) {
            Section("Library") {
                Label("All Notes", systemImage: "note.text")
                    .tag(NoteSection.all)
                Label("Favorites", systemImage: "star")
                    .tag(NoteSection.favorites)
            }
            
            if !categories.isEmpty {
                Section("Categories") {
                    ForEach(categories, id: \.self) { category in
                        Label(category, systemImage: "folder")
                            .tag(NoteSection.category(category))
                            .contextMenu {
                                Button("Rename") {
                                    categoryToRename = category
                                    newCategoryName = category
                                    isShowingRenameAlert = true
                                }
                                Button("Delete", role: .destructive) {
                                    categoryToRename = category
                                    isShowingDeleteAlert = true
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Krypton Notes")
        .alert("Rename Category", isPresented: $isShowingRenameAlert) {
            TextField("New Name", text: $newCategoryName)
            Button("Rename") {
                if let oldName = categoryToRename {
                    renameCategory(from: oldName, to: newCategoryName)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Category?", isPresented: $isShowingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let categoryToDelete = categoryToRename {
                    deleteCategory(categoryToDelete)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete the category \"\(categoryToRename ?? "")\"? Notes in this category will not be deleted.")
        }
    }
    
    private func renameCategory(from oldName: String, to newName: String) {
        let notesToUpdate = notes.filter { $0.category == oldName }
        for note in notesToUpdate {
            note.category = newName
        }
        // If the currently selected category was the one renamed, update the selection
        if selection == .category(oldName) {
            selection = .category(newName)
        }
    }
    
    private func deleteCategory(_ name: String) {
        let notesToUpdate = notes.filter { $0.category == name }
        for note in notesToUpdate {
            note.category = nil
        }
        // If the currently selected category was deleted, switch to All Notes
        if selection == .category(name) {
            selection = .all
        }
    }
}

// MARK: - Note List
struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.modifiedAt, order: .reverse) private var notes: [Note]
    
    @Binding var selection: Note?
    @Binding var searchText: String
    let filter: (Note) -> Bool

    var body: some View {
        List(selection: $selection) {
            ForEach(notes.filter(filter)) { note in
                NavigationLink(value: note) {
                    NoteRowView(note: note)
                }
                .contextMenu {
                    Button {
                        note.isFavorite.toggle()
                    } label: {
                        Label(note.isFavorite ? "Unfavorite" : "Favorite", systemImage: note.isFavorite ? "star.slash" : "star")
                    }
                    
                    Button("Delete", role: .destructive) {
                        modelContext.delete(note)
                    }
                }
            }
        }
        .navigationTitle("Notes")
        .overlay {
            if notes.filter(filter).isEmpty {
                ContentUnavailableView("No Notes Found", systemImage: "note.text.badge.plus")
            }
        }
    }
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(note.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if note.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.callout)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Note Detail View
struct NoteDetailView: View {
    @Bindable var note: Note
    let encryptionService: EncryptionService
    
    @State private var decryptedContent: String = ""
    @State private var categoryInput: String = ""
    @State private var isPreviewing: Bool = false
    
    // State to hold the note's initial values for comparison
    @State private var initialTitle: String = ""
    @State private var initialContent: String = ""
    @State private var initialFavoriteStatus: Bool = false
    @State private var initialCategory: String?

    var body: some View {
        VStack(spacing: 0) {
            // The main content area
            if isPreviewing {
                ScrollView {
                    Markdown(decryptedContent)
                        .markdownTheme(.gitHub)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TextEditor(text: $decryptedContent)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // The status bar footer
            Divider()
            HStack(spacing: 16) {
                HStack {
                    Image(systemName: "folder")
                    TextField("Category", text: $categoryInput)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: categoryInput) { _, newValue in
                            note.category = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newValue
                        }
                }
                
                Spacer()
                
                Text("\(decryptedContent.split(whereSeparator: \.isWhitespace).count) words")
                
                Text("Modified: \(note.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
            }
            .font(.callout)
            .foregroundColor(.secondary)
            .padding(12)
        }
        .onAppear(perform: loadInitialState)
        .onDisappear(perform: saveChangesIfModified)
        .toolbar {
            // Toolbar items are now first-class citizens of the toolbar
            ToolbarItem(placement: .principal) {
                TextField("Title", text: $note.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(minWidth: 200)
            }
            
            ToolbarItem {
                Button { note.isFavorite.toggle() } label: {
                    Label("Favorite", systemImage: note.isFavorite ? "star.fill" : "star")
                }
                .tint(note.isFavorite ? .yellow : .secondary)
                .help("Toggle Favorite")
            }

            ToolbarItem {
                Picker("Markdown Mode", selection: $isPreviewing) {
                    Label("Edit", systemImage: "pencil").tag(false)
                    Label("Preview", systemImage: "eye").tag(true)
                }
                .pickerStyle(.segmented)
                .help("Toggle between Markdown editor and preview")
            }
        }
    }
    
    private func loadInitialState() {
        do {
            initialContent = try encryptionService.decrypt(data: note.encryptedContent)
            decryptedContent = initialContent
            initialTitle = note.title
            initialFavoriteStatus = note.isFavorite
            initialCategory = note.category
            categoryInput = note.category ?? ""
        } catch {
            decryptedContent = "Error: Could not decrypt note."
        }
    }
    
    private func saveChangesIfModified() {
        let hasChanges = note.title != initialTitle ||
                         decryptedContent != initialContent ||
                         note.isFavorite != initialFavoriteStatus ||
                         note.category != initialCategory
        
        guard hasChanges else { return }
        
        do {
            note.encryptedContent = try encryptionService.encrypt(string: decryptedContent)
            note.modifiedAt = .now
        } catch {
            print("Encryption failed on save: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Note.self, inMemory: true)
}
