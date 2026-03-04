import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentNote.updatedAt, order: .reverse) private var notes: [ContentNote]
    
    @State private var showingAddNote = false
    @State private var selectedNote: ContentNote?
    
    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    emptyState
                } else {
                    notesList
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddNote = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                NoteEditorSheet(note: nil) { title, body, url in
                    addNote(title: title, body: body, url: url)
                }
            }
            .sheet(item: $selectedNote) { note in
                NoteEditorSheet(note: note) { title, body, url in
                    updateNote(note, title: title, body: body, url: url)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.spacing) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.textMuted)
            
            Text("No notes yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textSecondary)
            
            Text("Add training tips, form cues, or links to helpful content")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showingAddNote = true
            } label: {
                Text("Add Note")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacing) {
                ForEach(notes) { note in
                    NoteRow(note: note) {
                        selectedNote = note
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteNote(note)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func addNote(title: String, body: String, url: String) {
        let note = ContentNote(title: title, body: body, urlString: url)
        modelContext.insert(note)
        try? modelContext.save()
    }
    
    private func updateNote(_ note: ContentNote, title: String, body: String, url: String) {
        note.title = title
        note.body = body
        note.urlString = url
        note.updatedAt = Date()
        try? modelContext.save()
    }
    
    private func deleteNote(_ note: ContentNote) {
        modelContext.delete(note)
        try? modelContext.save()
    }
}

struct NoteRow: View {
    let note: ContentNote
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(note.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    if note.hasLink {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundStyle(AppTheme.accentSecondary)
                    }
                }
                
                if !note.body.isEmpty {
                    Text(note.body)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(3)
                }
                
                Text(note.formattedDate)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct NoteEditorSheet: View {
    let note: ContentNote?
    let onSave: (String, String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var noteBody: String
    @State private var urlString: String
    
    init(note: ContentNote?, onSave: @escaping (String, String, String) -> Void) {
        self.note = note
        self.onSave = onSave
        _title = State(initialValue: note?.title ?? "")
        _noteBody = State(initialValue: note?.body ?? "")
        _urlString = State(initialValue: note?.urlString ?? "")
    }
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var sheetBody: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLarge) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    TextField("Note title", text: $title)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .cardStyle()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    TextField("Write your notes here...", text: $noteBody, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(5...15)
                }
                .cardStyle()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Link (optional)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    TextField("https://...", text: $urlString)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundStyle(AppTheme.textPrimary)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                .cardStyle()
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(note == nil ? "New Note" : "Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(AppTheme.textSecondary)
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(title, noteBody, urlString)
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundStyle(isValid ? AppTheme.accent : AppTheme.textMuted)
                .disabled(!isValid)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            sheetBody
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NotesView()
        .modelContainer(for: [Exercise.self, WorkoutLog.self, ContentNote.self], inMemory: true)
}
