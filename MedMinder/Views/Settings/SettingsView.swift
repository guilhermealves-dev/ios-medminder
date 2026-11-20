import SwiftUI
import UserNotifications

public struct SettingsView: View {
    @ObservedObject var storage = StorageService.shared
    @State private var notificationsAuthorized = false
    @State private var showingTestNotificationAlert = false
    @State private var showingResetConfirmation = false
    
    public var body: some View {
        NavigationView {
            List {
                // Section 1: Notifications
                Section {
                    HStack {
                        Label("Notification Reminders", systemImage: "bell.badge.fill")
                            .foregroundColor(.accentColor)
                        Spacer()
                        if notificationsAuthorized {
                            Text("Enabled")
                                .foregroundColor(.green)
                                .font(.subheadline)
                        } else {
                            Button("Enable") {
                                requestNotificationPermission()
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        }
                    }
                    
                    Button {
                        sendTestNotification()
                    } label: {
                        Label("Send Test Reminder (5 sec)", systemImage: "timer")
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("MedMinder uses local iOS notifications to alert you when it's time for each dose.")
                }
                
                // Section 2: App Preferences
                Section {
                    HStack {
                        Label("Snooze Duration", systemImage: "clock")
                        Spacer()
                        Text("15 minutes")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Refill Alert Buffer", systemImage: "shippingbox.fill")
                        Spacer()
                        Text("5 doses remaining")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Preferences")
                }
                
                // Section 3: Data Management
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset to Sample Data", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Data")
                }
                
                // Section 4: About
                Section {
                    HStack {
                        Label("App Name", systemImage: "info.circle")
                        Spacer()
                        Text("MedMinder")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Version", systemImage: "number")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Platform", systemImage: "applelogo")
                        Spacer()
                        Text("iOS 16.0+")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .onAppear {
                checkNotificationStatus()
            }
            .alert("Test Notification Scheduled", isPresented: $showingTestNotificationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Lock your device or switch apps to see the MedMinder reminder notification in 5 seconds.")
            }
            .alert("Reset Data?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetData()
                }
            } message: {
                Text("This will restore the sample medications and clear your custom logs.")
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
        let content = UNMutableNotificationContent()
        content.title = "Time for your Vitamin D3"
        content.body = "2000 IU • With meal"
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
    
    private func resetData() {
        storage.medications = []
        storage.doseLogs = []
        storage.saveData()
        storage.loadData()
    }
}
