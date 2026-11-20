import SwiftUI

public struct RootView: View {
    @ObservedObject var storage = StorageService.shared
    @ObservedObject var language = LanguageManager.shared
    @State private var selectedTab: Int = 0
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label(loc("tab_today"), systemImage: "calendar.day.timeline.left")
                }
                .tag(0)
            
            MedicationListView()
                .tabItem {
                    Label(loc("tab_meds"), systemImage: "pills.fill")
                }
                .tag(1)
            
            CabinetView()
                .tabItem {
                    Label(loc("tab_cabinet"), systemImage: "cross.case.fill")
                }
                .badge(storage.lowStockMeds.count > 0 ? "\(storage.lowStockMeds.count)" : nil)
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Label(loc("tab_progress"), systemImage: "chart.bar.xaxis")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label(loc("tab_settings"), systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color.accentColor)
    }
}
