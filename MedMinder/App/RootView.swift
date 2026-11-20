import SwiftUI

public struct RootView: View {
    @ObservedObject var storage = StorageService.shared
    @State private var selectedTab: Int = 0
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar.day.timeline.left")
                }
                .tag(0)
            
            MedicationListView()
                .tabItem {
                    Label("Meds", systemImage: "pills.fill")
                }
                .tag(1)
            
            CabinetView()
                .tabItem {
                    Label("Cabinet", systemImage: "cross.case.fill")
                }
                .badge(storage.lowStockMeds.count > 0 ? "\(storage.lowStockMeds.count)" : nil)
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.xaxis")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color.accentColor)
    }
}
