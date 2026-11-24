import Foundation
import UserNotifications

public final class NotificationManager {
    public static let shared = NotificationManager()
    
    public static let categoryId = "MED_REMINDER_CATEGORY"
    public static let actionTakeId = "ACTION_TAKE"
    public static let actionSnoozeId = "ACTION_SNOOZE"
    public static let actionSkipId = "ACTION_SKIP"
    
    private init() {}
    
    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.setupNotificationCategories()
                }
                completion(granted)
            }
        }
    }
    
    public func setupNotificationCategories() {
        let isPt = LanguageManager.shared.currentLanguage == .ptBR
        
        let takeAction = UNNotificationAction(
            identifier: Self.actionTakeId,
            title: isPt ? "Tomar Agora" : "Take Now",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: Self.actionSnoozeId,
            title: isPt ? "Adiar (15m)" : "Snooze (15m)",
            options: []
        )
        
        let skipAction = UNNotificationAction(
            identifier: Self.actionSkipId,
            title: isPt ? "Pular" : "Skip",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: Self.categoryId,
            actions: [takeAction, snoozeAction, skipAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    public func rescheduleAllReminders(for medications: [Medication]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for med in medications where med.isActive {
            scheduleReminders(for: med)
        }
    }
    
    public func scheduleReminders(for medication: Medication) {
        guard medication.isActive else { return }
        
        let isPt = LanguageManager.shared.currentLanguage == .ptBR
        let center = UNUserNotificationCenter.current()
        
        // Remove existing reminders for this medication
        cancelReminders(for: medication.id)
        
        // As-needed (SOS) medications don't have scheduled recurring alarms
        guard medication.frequency != .asNeeded else { return }
        
        // Resolve sound: specific medication sound, or global sound from Settings
        let globalSoundRaw = UserDefaults.standard.string(forKey: "selected_global_sound") ?? "default"
        let globalSound = AlertSound(rawValue: globalSoundRaw) ?? .default
        let effectiveSound = (medication.alertSound != .default) ? medication.alertSound : globalSound
        
        for dose in medication.doseTimes {
            let content = UNMutableNotificationContent()
            content.title = isPt ? "Hora de tomar \(medication.name)" : "Time for your \(medication.name)"
            content.body = "\(medication.strength) • \(medication.instruction.localizedTitle)"
            content.sound = effectiveSound.notificationSound
            content.categoryIdentifier = Self.categoryId
            content.userInfo = [
                "medicationId": medication.id.uuidString,
                "doseTimeId": dose.id.uuidString
            ]
            
            switch medication.frequency {
            case .specificDays:
                // Schedule recurring alarms ONLY on the selected days of the week
                for day in medication.selectedDays {
                    var dateComponents = DateComponents()
                    dateComponents.weekday = day
                    dateComponents.hour = dose.hour
                    dateComponents.minute = dose.minute
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let identifier = "med-\(medication.id.uuidString)-\(dose.id.uuidString)-day-\(day)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    center.add(request) { error in
                        if let error = error {
                            print("Error scheduling reminder for day \(day): \(error.localizedDescription)")
                        }
                    }
                }
                
            case .everyday, .everyXHours:
                // Daily repeating alarm
                var dateComponents = DateComponents()
                dateComponents.hour = dose.hour
                dateComponents.minute = dose.minute
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let identifier = "med-\(medication.id.uuidString)-\(dose.id.uuidString)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling daily reminder: \(error.localizedDescription)")
                    }
                }
                
            case .asNeeded:
                break
            }
        }
    }
    
    public func cancelReminders(for medicationId: UUID) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.contains(medicationId.uuidString) }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    public func scheduleRefillAlert(for medication: Medication) {
        guard medication.refillAlertEnabled, medication.currentStock <= medication.refillThreshold else { return }
        
        let isPt = LanguageManager.shared.currentLanguage == .ptBR
        let content = UNMutableNotificationContent()
        content.title = isPt ? "Aviso de Reposição: \(medication.name)" : "Refill Reminder: \(medication.name)"
        content.body = isPt ? "Restam apenas \(Int(medication.currentStock)) doses. Hora de repor o estoque!" : "You only have \(Int(medication.currentStock)) doses remaining. Time to restock!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "refill-\(medication.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
