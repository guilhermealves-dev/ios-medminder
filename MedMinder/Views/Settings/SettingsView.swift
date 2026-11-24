import SwiftUI
import UserNotifications

public struct SettingsView: View {
    @ObservedObject var storage = StorageService.shared
    @ObservedObject var language = LanguageManager.shared
    @State private var notificationsAuthorized = false
    @State private var showingTestNotificationAlert = false
    @State private var showingClearConfirmation = false
    
    public var body: some View {
        NavigationView {
            List {
                // Section 0: Language Selector
                Section {
                    Picker(loc("app_language"), selection: $language.currentLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(loc("language_section"))
                }
                
                // Section 1: Notifications
                Section {
                    HStack {
                        Label(loc("notification_reminders"), systemImage: "bell.badge.fill")
                            .foregroundColor(.accentColor)
                        Spacer()
                        if notificationsAuthorized {
                            Text(loc("status_enabled"))
                                .foregroundColor(.green)
                                .font(.subheadline)
                        } else {
                            Button(loc("action_enable")) {
                                requestNotificationPermission()
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        }
                    }
                    
                    Button {
                        sendTestNotification()
                    } label: {
                        Label(loc("send_test_reminder"), systemImage: "timer")
                    }
                } header: {
                    Text(loc("reminders_section"))
                } footer: {
                    Text(loc("reminders_footer"))
                }
                
                // Section 2: App Preferences
                Section {
                    HStack {
                        Label(loc("snooze_duration"), systemImage: "clock")
                        Spacer()
                        Text(loc("snooze_time_val"))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label(loc("refill_buffer"), systemImage: "shippingbox.fill")
                        Spacer()
                        Text(loc("refill_buffer_val"))
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(loc("preferences_section"))
                }
                
                // Section 3: Data Management
                Section {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label(loc("clear_all_data"), systemImage: "trash")
                    }
                } header: {
                    Text(loc("data_section"))
                }
                
                // Section 4: About
                Section {
                    HStack {
                        Label(loc("app_name_label"), systemImage: "info.circle")
                        Spacer()
                        Text("MedMinder")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label(loc("version_label"), systemImage: "number")
                        Spacer()
                        Text("1.0.2")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label(loc("platform_label"), systemImage: "applelogo")
                        Spacer()
                        Text("iOS 16.0+")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(loc("about_section"))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(loc("settings_title"))
            .onAppear {
                checkNotificationStatus()
            }
            .alert(loc("test_notification_scheduled"), isPresented: $showingTestNotificationAlert) {
                Button(loc("ok"), role: .cancel) {}
            } message: {
                Text(loc("test_notification_msg"))
            }
            .alert(loc("clear_all_confirm_title"), isPresented: $showingClearConfirmation) {
                Button(loc("cancel"), role: .cancel) {}
                Button(loc("clear_button"), role: .destructive) {
                    storage.clearAllData()
                }
            } message: {
                Text(loc("clear_all_confirm_msg"))
            }
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    private func requestNotificationPermission() {
        NotificationManager.shared.requestAuthorization { granted in
            self.notificationsAuthorized = granted
        }
    }
    
    private func sendTestNotification() {
        let isPt = language.currentLanguage == .ptBR
        let content = UNMutableNotificationContent()
        content.title = isPt ? "Hora do seu Medicamento" : "Time for your Medication"
        content.body = isPt ? "1 comprimido • Com a refeição" : "1 pill • With meal"
        content.sound = .default
        content.categoryIdentifier = NotificationManager.categoryId
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in
            DispatchQueue.main.async {
                self.showingTestNotificationAlert = true
            }
        }
    }
}
