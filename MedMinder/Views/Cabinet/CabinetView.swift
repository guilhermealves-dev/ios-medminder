import SwiftUI

public struct CabinetView: View {
    @ObservedObject var storage = StorageService.shared
    @State private var showingRefillSheet = false
    @State private var selectedMedicationForRefill: Medication?
    @State private var refillQuantityString = "30"
    
    public var body: some View {
        NavigationView {
            List {
                // Section 1: Refill Warnings
                if !storage.lowStockMeds.isEmpty {
                    Section {
                        ForEach(storage.lowStockMeds) { med in
                            HStack(spacing: 12) {
                                PillIconView(form: med.form, color: med.themeColor.color, size: 32)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(med.name)
                                        .font(.headline)
                                    Text("\(Int(med.currentStock)) pills remaining (below \(Int(med.refillThreshold)))")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                
                                Spacer()
                                
                                Button("Refill") {
                                    selectedMedicationForRefill = med
                                    refillQuantityString = "30"
                                    showingRefillSheet = true
                                }
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .cornerRadius(10)
                            }
                        }
                    } header: {
                        Label("Refill Needed", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                // Section 2: All Inventory Items
                Section {
                    ForEach(storage.medications) { med in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                PillIconView(form: med.form, color: med.themeColor.color, size: 36)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(med.name)
                                        .font(.headline)
                                    Text(med.strength.isEmpty ? "Standard dose" : med.strength)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("+30") {
                                    var updated = med
                                    updated.currentStock += 30
                                    storage.updateMedication(updated)
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.12))
                                .cornerRadius(8)
                            }
                            
                            // Stock progress bar & estimate
                            VStack(spacing: 4) {
                                ProgressView(
                                    value: min(med.currentStock, 60),
                                    total: 60
                                )
                                .tint(med.currentStock <= med.refillThreshold ? .orange : med.themeColor.color)
                                
                                HStack {
                                    Text("\(Int(med.currentStock)) pills in stock")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    let daysLeft = calculateDaysRemaining(for: med)
                                    Text(daysLeft > 0 ? "~\(daysLeft) days left" : "Depleted")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(daysLeft <= 5 ? .orange : .secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Pill Cabinet Inventory (\(storage.medications.count))")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Cabinet")
            .sheet(isPresented: $showingRefillSheet) {
                refillModalSheet
            }
        }
    }
    
    private var refillModalSheet: some View {
        NavigationView {
            Form {
                if let med = selectedMedicationForRefill {
                    Section {
                        HStack {
                            PillIconView(form: med.form, color: med.themeColor.color, size: 32)
                            VStack(alignment: .leading) {
                                Text(med.name).font(.headline)
                                Text("Current stock: \(Int(med.currentStock))").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Units to add")
                            Spacer()
                            TextField("30", text: $refillQuantityString)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        HStack(spacing: 12) {
                            Button("+15") { refillQuantityString = "15" }
                            Button("+30") { refillQuantityString = "30" }
                            Button("+60") { refillQuantityString = "60" }
                            Button("+90") { refillQuantityString = "90" }
                        }
                        .buttonStyle(.bordered)
                    } header: {
                        Text("Add Stock")
                    }
                }
            }
            .navigationTitle("Refill Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingRefillSheet = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm") {
                        if var med = selectedMedicationForRefill,
                           let amount = Double(refillQuantityString) {
                            med.currentStock += amount
                            storage.updateMedication(med)
                        }
                        showingRefillSheet = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func calculateDaysRemaining(for med: Medication) -> Int {
        let dailyConsumption = med.doseTimes.reduce(0.0) { $0 + $1.doseAmount }
        guard dailyConsumption > 0 else { return 99 }
        return Int(med.currentStock / dailyConsumption)
    }
}
