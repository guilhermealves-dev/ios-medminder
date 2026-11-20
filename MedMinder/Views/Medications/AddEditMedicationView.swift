import SwiftUI

public struct AddEditMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storage = StorageService.shared
    
    public var editingMedication: Medication?
    
    @State private var name: String = ""
    @State private var strength: String = ""
    @State private var form: MedicationForm = .capsule
    @State private var themeColor: PillThemeColor = .sapphire
    @State private var instruction: MealInstruction = .anytime
    @State private var frequency: FrequencyType = .everyday
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    @State private var doseTimes: [DoseTime] = [DoseTime(hour: 8, minute: 0)]
    @State private var currentStock: String = "30"
    @State private var refillThreshold: String = "5"
    @State private var refillAlertEnabled: Bool = true
    @State private var notes: String = ""
    
    @State private var showingTimePicker = false
    @State private var newDoseDate = Date()
    
    private let weekdays = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat")
    ]
    
    public init(editingMedication: Medication? = nil) {
        self.editingMedication = editingMedication
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // Section 1: Live Pill Preview & Basic Info
                Section {
                    HStack(spacing: 16) {
                        PillIconView(form: form, color: themeColor.color, size: 48)
                            .padding(4)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "Medication Name" : name)
                                .font(.headline)
                                .foregroundColor(name.isEmpty ? .secondary : .primary)
                            
                            Text(strength.isEmpty ? "Dosage (e.g. 500mg)" : strength)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    TextField("Medication Name (e.g. Ibuprofen)", text: $name)
                    TextField("Strength / Dosage (e.g. 400 mg)", text: $strength)
                } header: {
                    Text("Basic Info")
                }
                
                // Section 2: Visual Appearance (Form & Color)
                Section {
                    // Pill Form Horizontal Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MedicationForm.allCases) { item in
                                let isSelected = item == form
                                Button {
                                    form = item
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: item.systemIcon)
                                            .font(.system(size: 20))
                                        Text(item.rawValue)
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 74, height: 60)
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .background(isSelected ? themeColor.color : Color(UIColor.tertiarySystemGroupedBackground))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Color Palette Selector
                    HStack(spacing: 12) {
                        ForEach(PillThemeColor.allCases) { colorCase in
                            let isSelected = colorCase == themeColor
                            Button {
                                themeColor = colorCase
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(colorCase.color)
                                        .frame(width: 32, height: 32)
                                    
                                    if isSelected {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                            .frame(width: 28, height: 28)
                                        Circle()
                                            .stroke(colorCase.color, lineWidth: 2)
                                            .frame(width: 36, height: 36)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Pill Appearance")
                }
                
                // Section 3: Schedule & Frequency
                Section {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(FrequencyType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    if frequency == .specificDays {
                        HStack(spacing: 6) {
                            ForEach(weekdays, id: \.0) { day, label in
                                let isSelected = selectedDays.contains(day)
                                Button {
                                    if isSelected {
                                        if selectedDays.count > 1 { selectedDays.remove(day) }
                                    } else {
                                        selectedDays.insert(day)
                                    }
                                } label: {
                                    Text(label)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .background(isSelected ? themeColor.color : Color(UIColor.tertiarySystemGroupedBackground))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Picker("Take with food?", selection: $instruction) {
                        ForEach(MealInstruction.allCases) { inst in
                            Label(inst.rawValue, systemImage: inst.icon).tag(inst)
                        }
                    }
                } header: {
                    Text("Schedule")
                }
                
                // Section 4: Dose Times of Day
                Section {
                    ForEach(Array(doseTimes.enumerated()), id: \.element.id) { index, dose in
                        HStack {
                            Text("Dose \(index + 1)")
                                .font(.subheadline)
                            Spacer()
                            Text(dose.formattedTime)
                                .font(.headline)
                                .foregroundColor(.accentColor)
                            
                            Button {
                                if doseTimes.count > 1 {
                                    doseTimes.remove(at: index)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                            .disabled(doseTimes.count <= 1)
                        }
                    }
                    
                    Button {
                        showingTimePicker = true
                    } label: {
                        Label("Add Another Dose Time", systemImage: "plus")
                            .foregroundColor(.accentColor)
                    }
                } header: {
                    Text("Dose Times")
                }
                
                // Section 5: Inventory & Refill Reminders
                Section {
                    HStack {
                        Text("Current Stock")
                        Spacer()
                        TextField("30", text: $currentStock)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("pills").foregroundColor(.secondary)
                    }
                    
                    Toggle("Refill Reminder", isOn: $refillAlertEnabled)
                    
                    if refillAlertEnabled {
                        HStack {
                            Text("Alert When Below")
                            Spacer()
                            TextField("5", text: $refillThreshold)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("pills").foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Inventory & Refill")
                }
                
                // Section 6: Notes
                Section {
                    TextField("Doctor instructions, storage conditions, etc.", text: $notes)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle(editingMedication == nil ? "Add Medication" : "Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedication()
                    }
                    .fontWeight(.bold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingTimePicker) {
                timePickerSheet
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    // Time picker sheet
    private var timePickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Time",
                    selection: $newDoseDate,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                
                Spacer()
            }
            .navigationTitle("Add Dose Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingTimePicker = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: newDoseDate)
                        let newDose = DoseTime(hour: comps.hour ?? 8, minute: comps.minute ?? 0)
                        doseTimes.append(newDose)
                        doseTimes.sort { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
                        showingTimePicker = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func loadExistingData() {
        guard let med = editingMedication else { return }
        name = med.name
        strength = med.strength
        form = med.form
        themeColor = med.themeColor
        instruction = med.instruction
        frequency = med.frequency
        selectedDays = med.selectedDays
        doseTimes = med.doseTimes
        currentStock = "\(Int(med.currentStock))"
        refillThreshold = "\(Int(med.refillThreshold))"
        refillAlertEnabled = med.refillAlertEnabled
        notes = med.notes
    }
    
    private func saveMedication() {
        let stockVal = Double(currentStock) ?? 30
        let thresholdVal = Double(refillThreshold) ?? 5
        
        let med = Medication(
            id: editingMedication?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            strength: strength.trimmingCharacters(in: .whitespacesAndNewlines),
            form: form,
            themeColor: themeColor,
            instruction: instruction,
            frequency: frequency,
            selectedDays: selectedDays,
            doseTimes: doseTimes,
            currentStock: stockVal,
            refillThreshold: thresholdVal,
            refillAlertEnabled: refillAlertEnabled,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            isActive: editingMedication?.isActive ?? true,
            createdAt: editingMedication?.createdAt ?? Date()
        )
        
        if editingMedication != nil {
            storage.updateMedication(med)
        } else {
            storage.addMedication(med)
        }
        
        dismiss()
    }
}
