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
    
    private func setupNotificationCategories() {
        let takeAction = UNNotificationAction(
            identifier: Self.actionTakeId,
            title: "Take Now",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: Self.actionSnoozeId,
            title: "Snooze (15m)",
            options: []
        )
        
        let skipAction = UNNotificationAction(
            identifier: Self.actionSkipId,
            title: "Skip",
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
    
    public func scheduleReminders(for medication: Medication) {
        guard medication.isActive else { return }
        
        let center = UNUserNotificationCenter.current()
        
        // Remove existing reminders for this medication
        cancelReminders(for: medication.id)
        
        for dose in medication.doseTimes {
            let content = UNMutableNotificationContent()
            content.title = "Time for your \(medication.name)"
            content.body = "\(medication.strength) • \(medication.instruction.rawValue)"
            content.sound = .default
            content.categoryIdentifier = Self.categoryId
            content.userInfo = [
                "medicationId": medication.id.uuidString,
                "doseTimeId": dose.id.uuidString
            ]
            
            var dateComponents = DateComponents()
            dateComponents.hour = dose.hour
            dateComponents.minute = dose.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "med-\(medication.id.uuidString)-\(dose.id.uuidString)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling reminder: \(error.localizedDescription)")
                }
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
        
        let content = UNMutableNotificationContent()
        content.title = "Refill Reminder: \(medication.name)"
        content.body = "You only have \(Int(medication.currentStock)) doses remaining. Time to restock!"
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
