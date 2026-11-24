import Foundation
import SwiftUI

@MainActor
public final class StorageService: ObservableObject {
    public static let shared = StorageService()
    
    @Published public var medications: [Medication] = []
    @Published public var doseLogs: [DoseLog] = []
    @Published public var selectedDate: Date = Date()
    
    private let medicationsFileName = "medications.json"
    private let logsFileName = "dose_logs.json"
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var medicationsURL: URL {
        documentsDirectory.appendingPathComponent(medicationsFileName)
    }
    
    private var logsURL: URL {
        documentsDirectory.appendingPathComponent(logsFileName)
    }
    
    public init() {
        loadData()
        
        // One-time cleanup of legacy demo medications if present
        cleanupLegacySampleDataIfNeeded()
        
        // Refresh all notification triggers to ensure correct weekday matching
        NotificationManager.shared.rescheduleAllReminders(for: medications)
    }
    
    // MARK: - Persistence
    
    public func loadData() {
        // Load Medications
        if let data = try? Data(contentsOf: medicationsURL),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            self.medications = decoded
        }
        
        // Load Logs
        if let data = try? Data(contentsOf: logsURL),
           let decoded = try? JSONDecoder().decode([DoseLog].self, from: data) {
            self.doseLogs = decoded
        }
    }
    
    public func saveData() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        if let data = try? encoder.encode(medications) {
            try? data.write(to: medicationsURL)
        }
        
        if let data = try? encoder.encode(doseLogs) {
            try? data.write(to: logsURL)
        }
    }
    
    public func clearAllData() {
        medications.removeAll()
        doseLogs.removeAll()
        saveData()
    }
    
    private func cleanupLegacySampleDataIfNeeded() {
        let demoNames = ["Vitamin D3", "Omega-3 Fish Oil", "Magnesium Glycinate"]
        if medications.count == 3 && medications.allSatisfy({ demoNames.contains($0.name) }) {
            clearAllData()
        }
    }
    
    // MARK: - Medication Management
    
    public func addMedication(_ med: Medication) {
        medications.append(med)
        saveData()
        NotificationManager.shared.scheduleReminders(for: med)
    }
    
    public func updateMedication(_ med: Medication) {
        if let index = medications.firstIndex(where: { $0.id == med.id }) {
            medications[index] = med
            saveData()
            NotificationManager.shared.scheduleReminders(for: med)
        }
    }
    
    public func deleteMedication(id: UUID) {
        medications.removeAll { $0.id == id }
        doseLogs.removeAll { $0.medicationId == id }
        saveData()
        NotificationManager.shared.cancelReminders(for: id)
    }
    
    public func toggleActive(id: UUID) {
        if let index = medications.firstIndex(where: { $0.id == id }) {
            medications[index].isActive.toggle()
            saveData()
            if medications[index].isActive {
                NotificationManager.shared.scheduleReminders(for: medications[index])
            } else {
                NotificationManager.shared.cancelReminders(for: id)
            }
        }
    }
    
    // MARK: - Dose Resolving for a Specific Date
    
    public func doseItems(for date: Date) -> [DailyDoseItem] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        var items: [DailyDoseItem] = []
        
        for med in medications where med.isActive {
            // Check frequency
            var shouldInclude = false
            switch med.frequency {
            case .everyday:
                shouldInclude = true
            case .specificDays:
                shouldInclude = med.selectedDays.contains(weekday)
            case .everyXHours, .asNeeded:
                shouldInclude = true
            }
            
            guard shouldInclude else { continue }
            
            for dose in med.doseTimes {
                var comps = calendar.dateComponents([.year, .month, .day], from: date)
                comps.hour = dose.hour
                comps.minute = dose.minute
                comps.second = 0
                guard let scheduledDate = calendar.date(from: comps) else { continue }
                
                // Find matching log if any
                let log = doseLogs.first { item in
                    item.medicationId == med.id &&
                    calendar.isDate(item.scheduledDate, equalTo: scheduledDate, toGranularity: .minute)
                }
                
                let status = log?.status ?? .pending
                items.append(DailyDoseItem(
                    medication: med,
                    scheduledDate: scheduledDate,
                    doseTime: dose,
                    status: status,
                    log: log
                ))
            }
        }
        
        // Sort chronologically
        return items.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    // MARK: - Dose Logging Actions
    
    public func recordDose(medicationId: UUID, scheduledDate: Date, status: DoseStatus, doseAmount: Double = 1.0) {
        let calendar = Calendar.current
        
        if let index = doseLogs.firstIndex(where: {
            $0.medicationId == medicationId &&
            calendar.isDate($0.scheduledDate, equalTo: scheduledDate, toGranularity: .minute)
        }) {
            doseLogs[index].status = status
            doseLogs[index].actualTime = Date()
        } else {
            let newLog = DoseLog(
                medicationId: medicationId,
                scheduledDate: scheduledDate,
                status: status,
                actualTime: Date(),
                doseAmount: doseAmount
            )
            doseLogs.append(newLog)
        }
        
        // If taken, decrement stock
        if status == .taken {
            if let medIndex = medications.firstIndex(where: { $0.id == medicationId }) {
                medications[medIndex].currentStock = max(0, medications[medIndex].currentStock - doseAmount)
                
                // Check if refill warning needed
                if medications[medIndex].refillAlertEnabled &&
                    medications[medIndex].currentStock <= medications[medIndex].refillThreshold {
                    NotificationManager.shared.scheduleRefillAlert(for: medications[medIndex])
                }
            }
        }
        
        saveData()
    }
    
    public func takeAllPending(for period: DayPeriod? = nil, on date: Date = Date()) {
        let items = doseItems(for: date)
        for item in items where item.status == .pending {
            if let targetPeriod = period {
                if item.period == targetPeriod {
                    recordDose(medicationId: item.medication.id, scheduledDate: item.scheduledDate, status: .taken, doseAmount: item.doseTime.doseAmount)
                }
            } else {
                recordDose(medicationId: item.medication.id, scheduledDate: item.scheduledDate, status: .taken, doseAmount: item.doseTime.doseAmount)
            }
        }
    }
    
    // MARK: - Adherence & Stats
    
    public func adherenceRate(days: Int = 7) -> Double {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return 1.0 }
        
        var totalScheduled = 0
        var totalTaken = 0
        
        var curDate = startDate
        while curDate <= Date() {
            let items = doseItems(for: curDate)
            for item in items {
                // If in past
                if item.scheduledDate <= Date() {
                    totalScheduled += 1
                    if item.status == .taken {
                        totalTaken += 1
                    }
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: curDate) else { break }
            curDate = next
        }
        
        guard totalScheduled > 0 else { return 1.0 }
        return Double(totalTaken) / Double(totalScheduled)
    }
    
    public var lowStockMeds: [Medication] {
        medications.filter { $0.isActive && $0.refillAlertEnabled && $0.currentStock <= $0.refillThreshold }
    }
}
