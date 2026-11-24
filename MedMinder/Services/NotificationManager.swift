import Foundation
import UserNotifications

public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()
    
    public static let categoryId = "MED_REMINDER_CATEGORY"
    public static let actionTakeId = "ACTION_TAKE"
    public static let actionSnoozeId = "ACTION_SNOOZE"
    public static let actionSkipId = "ACTION_SKIP"
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
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
        
        // Check persistent reminder preferences
        let persistentEnabled = UserDefaults.standard.object(forKey: "persistent_reminders_enabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "persistent_reminders_enabled")
        let maxFollowUps = persistentEnabled
            ? max(1, min(6, UserDefaults.standard.integer(forKey: "persistent_reminders_count") == 0 ? 4 : UserDefaults.standard.integer(forKey: "persistent_reminders_count")))
            : 0
        
        for dose in medication.doseTimes {
            switch medication.frequency {
            case .specificDays:
                // Schedule recurring alarms ONLY on the selected days of the week
                for day in medication.selectedDays {
                    // 1. Main Alarm at exact dose time
                    scheduleDoseNotification(
                        medication: medication,
                        dose: dose,
                        weekday: day,
                        hour: dose.hour,
                        minute: dose.minute,
                        sound: effectiveSound,
                        step: 0,
                        isPt: isPt,
                        center: center
                    )
                    
                    // 2. Follow-up Nag Reminders (every 10 minutes)
                    if maxFollowUps > 0 {
                        for step in 1...maxFollowUps {
                            let totalMinutes = dose.hour * 60 + dose.minute + (step * 10)
                            let nagHour = (totalMinutes / 60) % 24
                            let nagMinute = totalMinutes % 60
                            
                            scheduleDoseNotification(
                                medication: medication,
                                dose: dose,
                                weekday: day,
                                hour: nagHour,
                                minute: nagMinute,
                                sound: effectiveSound,
                                step: step,
                                isPt: isPt,
                                center: center
                            )
                        }
                    }
                }
                
            case .everyday, .everyXHours:
                // 1. Main Daily Alarm
                scheduleDoseNotification(
                    medication: medication,
                    dose: dose,
                    weekday: nil,
                    hour: dose.hour,
                    minute: dose.minute,
                    sound: effectiveSound,
                    step: 0,
                    isPt: isPt,
                    center: center
                )
                
                // 2. Follow-up Nag Reminders (every 10 minutes)
                if maxFollowUps > 0 {
                    for step in 1...maxFollowUps {
                        let totalMinutes = dose.hour * 60 + dose.minute + (step * 10)
                        let nagHour = (totalMinutes / 60) % 24
                        let nagMinute = totalMinutes % 60
                        
                        scheduleDoseNotification(
                            medication: medication,
                            dose: dose,
                            weekday: nil,
                            hour: nagHour,
                            minute: nagMinute,
                            sound: effectiveSound,
                            step: step,
                            isPt: isPt,
                            center: center
                        )
                    }
                }
                
            case .asNeeded:
                break
            }
        }
    }
    
    private func scheduleDoseNotification(
        medication: Medication,
        dose: DoseTime,
        weekday: Int?,
        hour: Int,
        minute: Int,
        sound: AlertSound,
        step: Int,
        isPt: Bool,
        center: UNUserNotificationCenter
    ) {
        let content = UNMutableNotificationContent()
        
        if step == 0 {
            content.title = isPt ? "Hora de tomar \(medication.name)" : "Time for your \(medication.name)"
            content.body = "\(medication.strength) • \(medication.instruction.localizedTitle)"
        } else {
            let elapsedMinutes = step * 10
            if isPt {
                content.title = "Lembrete (\(elapsedMinutes) min): \(medication.name)"
                content.body = "Você ainda não confirmou sua dose das \(dose.formattedTime). Não esqueça de tomar!"
            } else {
                content.title = "Reminder (\(elapsedMinutes)m): \(medication.name)"
                content.body = "You haven't confirmed your dose at \(dose.formattedTime) yet. Don't forget!"
            }
        }
        
        content.sound = sound.notificationSound
        content.categoryIdentifier = Self.categoryId
        content.userInfo = [
            "medicationId": medication.id.uuidString,
            "doseTimeId": dose.id.uuidString,
            "step": step
        ]
        
        var dateComponents = DateComponents()
        if let weekday = weekday {
            dateComponents.weekday = weekday
        }
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let daySuffix = weekday != nil ? "-day-\(weekday!)" : ""
        let stepSuffix = step > 0 ? "-nag-\(step)" : ""
        let identifier = "med-\(medication.id.uuidString)-\(dose.id.uuidString)\(stepSuffix)\(daySuffix)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error.localizedDescription)")
            }
        }
    }
    
    public func cancelNagReminders(for medicationId: UUID, doseTimeId: UUID? = nil) {
        let center = UNUserNotificationCenter.current()
        
        // 1. Remove delivered notifications from Notification Center / lock screen
        center.getDeliveredNotifications { notifications in
            let deliveredIds = notifications
                .filter { notif in
                    let id = notif.request.identifier
                    if let doseId = doseTimeId {
                        return id.contains(medicationId.uuidString) && id.contains(doseId.uuidString)
                    }
                    return id.contains(medicationId.uuidString)
                }
                .map { $0.request.identifier }
            center.removeDeliveredNotifications(withIdentifiers: deliveredIds)
        }
        
        // 2. Remove pending nag notifications for today
        center.getPendingNotificationRequests { requests in
            let nagIds = requests
                .filter { req in
                    let id = req.identifier
                    if id.contains("-nag-") {
                        if let doseId = doseTimeId {
                            return id.contains(medicationId.uuidString) && id.contains(doseId.uuidString)
                        }
                        return id.contains(medicationId.uuidString)
                    }
                    return false
                }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: nagIds)
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
        center.getDeliveredNotifications { notifications in
            let identifiers = notifications
                .filter { $0.request.identifier.contains(medicationId.uuidString) }
                .map { $0.request.identifier }
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
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
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Display banner and play sound even when app is active in foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification action buttons (Take, Snooze, Skip) from lock screen
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let medIdStr = userInfo["medicationId"] as? String,
              let medId = UUID(uuidString: medIdStr) else {
            completionHandler()
            return
        }
        
        let doseTimeIdStr = userInfo["doseTimeId"] as? String
        let doseTimeId = doseTimeIdStr != nil ? UUID(uuidString: doseTimeIdStr!) : nil
        
        switch response.actionIdentifier {
        case Self.actionTakeId:
            Task { @MainActor in
                StorageService.shared.recordDose(medicationId: medId, scheduledDate: Date(), status: .taken)
                self.cancelNagReminders(for: medId, doseTimeId: doseTimeId)
            }
            
        case Self.actionSkipId:
            Task { @MainActor in
                StorageService.shared.recordDose(medicationId: medId, scheduledDate: Date(), status: .skipped)
                self.cancelNagReminders(for: medId, doseTimeId: doseTimeId)
            }
            
        case Self.actionSnoozeId:
            // Snooze for 15 minutes
            let snoozeContent = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: snoozeContent, trigger: trigger)
            center.add(request)
            
        default:
            break
        }
        
        completionHandler()
    }
}
