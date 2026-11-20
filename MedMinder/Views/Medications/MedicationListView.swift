import SwiftUI

public struct MedicationListView: View {
    @ObservedObject var storage = StorageService.shared
    @ObservedObject var language = LanguageManager.shared
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var medicationToEdit: Medication?
    
    private var filteredMedications: [Medication] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return storage.medications
        }
        return storage.medications.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.strength.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var activeMeds: [Medication] {
        filteredMedications.filter { $0.isActive }
    }
    
    private var pausedMeds: [Medication] {
        filteredMedications.filter { !$0.isActive }
    }
    
    public var body: some View {
        NavigationView {
            List {
                if !activeMeds.isEmpty {
                    Section {
                        ForEach(activeMeds) { med in
                            medicationRow(med)
                        }
                    } header: {
                        Text(String(format: loc("active_medications"), activeMeds.count))
                    }
                }
                
                if !pausedMeds.isEmpty {
                    Section {
                        ForEach(pausedMeds) { med in
                            medicationRow(med)
                        }
                    } header: {
                        Text(String(format: loc("paused_medications"), pausedMeds.count))
                    }
                }
                
                if activeMeds.isEmpty && pausedMeds.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "pills.circle")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? loc("no_meds_added") : loc("no_search_results"))
                            .font(.headline)
                        Text(searchText.isEmpty ? loc("no_meds_hint") : loc("no_search_hint"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                }
            }
            .searchable(text: $searchText, prompt: loc("search_medications"))
            .listStyle(.insetGrouped)
            .navigationTitle(loc("medications_title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditMedicationView()
            }
            .sheet(item: $medicationToEdit) { med in
                AddEditMedicationView(editingMedication: med)
            }
        }
    }
    
    private func medicationRow(_ med: Medication) -> some View {
        Button {
            medicationToEdit = med
        } label: {
            HStack(spacing: 14) {
                PillIconView(
                    form: med.form,
                    color: med.themeColor.color,
                    size: 34
                )
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(med.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if !med.strength.isEmpty {
                            Text(med.strength)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Text(med.frequency.localizedTitle)
                        Text("•")
                        Text(med.doseTimes.map { $0.formattedTime }.joined(separator: ", "))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Stock pill badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: loc("pills_left_badge"), Int(med.currentStock)))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(med.currentStock <= med.refillThreshold ? .orange : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(med.currentStock <= med.refillThreshold ? Color.orange.opacity(0.15) : Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                storage.deleteMedication(id: med.id)
            } label: {
                Label(loc("delete"), systemImage: "trash")
            }
            
            Button {
                storage.toggleActive(id: med.id)
            } label: {
                Label(med.isActive ? loc("pause") : loc("resume"), systemImage: med.isActive ? "pause.circle" : "play.circle")
            }
            .tint(med.isActive ? .orange : .green)
        }
    }
}
