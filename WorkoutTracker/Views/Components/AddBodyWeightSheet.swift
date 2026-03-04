import SwiftUI
import SwiftData

struct AddBodyWeightSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var weight: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var isSaving = false
    
    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var recentEntries: [BodyWeightEntry]
    
    private var lastWeight: Double? {
        recentEntries.first?.weight
    }
    
    private var isValid: Bool {
        guard let weightValue = Double(weight) else { return false }
        return weightValue > 0 && weightValue < 1000
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.spacingLarge) {
                        weightInputSection
                        dateSection
                        notesSection
                        
                        if let lastWeight = lastWeight {
                            lastEntryHint(lastWeight: lastWeight)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Weight")
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
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(isValid ? AppTheme.accent : AppTheme.textMuted)
                    .disabled(!isValid || isSaving)
                }
            }
        }
        .onAppear {
            if let lastWeight = lastWeight {
                weight = String(format: "%.1f", lastWeight)
            }
        }
    }
    
    private var weightInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textSecondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TextField("0.0", text: $weight)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                
                Text("lbs")
                    .font(.title2)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
        }
    }
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textSecondary)
            
            DatePicker(
                "",
                selection: $date,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(AppTheme.accent)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textSecondary)
            
            TextField("How are you feeling?", text: $notes, axis: .vertical)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(3...6)
                .padding()
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        }
    }
    
    private func lastEntryHint(lastWeight: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(AppTheme.accentSecondary)
            
            Text("Your last entry was ")
                .foregroundStyle(AppTheme.textSecondary) +
            Text(String(format: "%.1f lbs", lastWeight))
                .foregroundStyle(AppTheme.textPrimary)
                .fontWeight(.semibold)
        }
        .font(.caption)
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.accentSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
    
    private func saveEntry() {
        guard let weightValue = Double(weight), isValid else { return }
        
        isSaving = true
        
        let entry = BodyWeightEntry(date: date, weight: weightValue, notes: notes)
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            
            Task {
                await pushToAPI(entry)
            }
            
            dismiss()
        } catch {
            isSaving = false
        }
    }
    
    @MainActor
    private func pushToAPI(_ entry: BodyWeightEntry) async {
        let request = CreateBodyWeightRequest(
            date: ISO8601DateFormatter().string(from: entry.date),
            weight: entry.weight,
            notes: entry.notes.isEmpty ? nil : entry.notes
        )
        
        do {
            let apiEntry = try await APIClient.shared.createBodyWeight(request)
            if let uuid = UUID(uuidString: apiEntry.id) {
                entry.id = uuid
                try? modelContext.save()
            }
        } catch {
            print("Failed to sync body weight to API: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddBodyWeightSheet()
        .modelContainer(for: [BodyWeightEntry.self], inMemory: true)
}
