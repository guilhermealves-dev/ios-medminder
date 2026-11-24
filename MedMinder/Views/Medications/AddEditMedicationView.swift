import SwiftUI

public struct AddEditMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storage = StorageService.shared
    @ObservedObject var language = LanguageManager.shared
    
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
    @State private var alertSound: AlertSound = .default
    
    private var weekdays: [(Int, String)] {
        if language.currentLanguage == .ptBR {
            return [
                (1, "Dom"), (2, "Seg"), (3, "Ter"), (4, "Qua"),
                (5, "Qui"), (6, "Sex"), (7, "Sáb")
            ]
        } else {
            return [
                (1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"),
                (5, "Thu"), (6, "Fri"), (7, "Sat")
            ]
        }
    }
    
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
                            Text(name.isEmpty ? loc("med_name_label") : name)
                                .font(.headline)
                                .foregroundColor(name.isEmpty ? .secondary : .primary)
                            
                            Text(strength.isEmpty ? loc("strength_placeholder") : strength)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    TextField(loc("med_name_placeholder"), text: $name)
                    TextField(loc("strength_placeholder"), text: $strength)
                } header: {
                    Text(loc("basic_info"))
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
                                        Text(item.localizedTitle)
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 82, height: 60)
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
                    Text(loc("appearance"))
                }
                
                // Section 3: Schedule & Frequency
                Section {
                    Picker(loc("frequency_label"), selection: $frequency) {
                        ForEach(FrequencyType.allCases) { type in
                            Text(type.localizedTitle).tag(type)
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
                    
                    Picker(loc("meal_label"), selection: $instruction) {
                        ForEach(MealInstruction.allCases) { inst in
                            Label(inst.localizedTitle, systemImage: inst.icon).tag(inst)
                        }
                    }
                } header: {
                    Text(loc("schedule"))
                }
                
                // Section 4: Dose Times of Day (Directly Editable)
                Section {
                    ForEach(Array(doseTimes.enumerated()), id: \.element.id) { index, dose in
                        HStack {
                            DatePicker(
                                String(format: loc("dose_number"), index + 1),
                                selection: bindingForDose(at: dose.id),
                                displayedComponents: .hourAndMinute
                            )
                            
                            if doseTimes.count > 1 {
                                Button {
                                    withAnimation {
                                        doseTimes.removeAll { $0.id == dose.id }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 4)
                            }
                        }
                    }
                    
                    Button {
                        withAnimation {
                            let lastHour = doseTimes.last?.hour ?? 8
                            let nextHour = (lastHour + 4) % 24
                            let newDose = DoseTime(hour: nextHour, minute: 0)
                            doseTimes.append(newDose)
                        }
                    } label: {
                        Label(loc("add_another_time"), systemImage: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                } header: {
                    Text(loc("dose_times_header"))
                }
                
                // Section 5: Inventory & Refill Reminders
                Section {
                    HStack {
                        Text(loc("current_stock"))
                        Spacer()
                        TextField("30", text: $currentStock)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(loc("pills_unit")).foregroundColor(.secondary)
                    }
                    
                    Toggle(loc("refill_reminder"), isOn: $refillAlertEnabled)
                    
                    if refillAlertEnabled {
                        HStack {
                            Text(loc("alert_when_below"))
                            Spacer()
                            TextField("5", text: $refillThreshold)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text(loc("pills_unit")).foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(loc("inventory_header"))
                }
                
                // Section 5.5: Notification Sound
                Section {
                    HStack {
                        Picker(loc("alert_sound"), selection: $alertSound) {
                            ForEach(AlertSound.allCases) { sound in
                                Text(sound.localizedTitle).tag(sound)
                            }
                        }
                        
                        Button {
                            SoundPreviewPlayer.shared.play(alertSound)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(loc("sound_section"))
                }
                
                // Section 6: Notes
                Section {
                    TextField(loc("notes_placeholder"), text: $notes)
                } header: {
                    Text(loc("notes_header"))
                }
            }
            .navigationTitle(editingMedication == nil ? loc("new_medication") : loc("edit_medication"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(loc("cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(loc("save")) {
                        saveMedication()
                    }
                    .fontWeight(.bold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    // Binding helper for individual doses by UUID
    private func bindingForDose(at id: UUID) -> Binding<Date> {
        Binding(
            get: {
                guard let dose = doseTimes.first(where: { $0.id == id }) else { return Date() }
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                comps.hour = dose.hour
                comps.minute = dose.minute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                guard let idx = doseTimes.firstIndex(where: { $0.id == id }) else { return }
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                doseTimes[idx].hour = comps.hour ?? 8
                doseTimes[idx].minute = comps.minute ?? 0
            }
        )
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
        alertSound = med.alertSound
    }
    
    private func saveMedication() {
        let stockVal = Double(currentStock) ?? 30
        let thresholdVal = Double(refillThreshold) ?? 5
        
        // Sort doses chronologically before saving
        var sortedDoses = doseTimes
        sortedDoses.sort { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
        
        let med = Medication(
            id: editingMedication?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            strength: strength.trimmingCharacters(in: .whitespacesAndNewlines),
            form: form,
            themeColor: themeColor,
            instruction: instruction,
            frequency: frequency,
            selectedDays: selectedDays,
            doseTimes: sortedDoses,
            currentStock: stockVal,
            refillThreshold: thresholdVal,
            refillAlertEnabled: refillAlertEnabled,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            isActive: editingMedication?.isActive ?? true,
            createdAt: editingMedication?.createdAt ?? Date(),
            alertSound: alertSound
        )
        
        if editingMedication != nil {
            storage.updateMedication(med)
        } else {
            storage.addMedication(med)
        }
        
        dismiss()
    }
}
