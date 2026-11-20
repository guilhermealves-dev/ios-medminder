import SwiftUI

public struct HistoryView: View {
    @ObservedObject var storage = StorageService.shared
    @ObservedObject var language = LanguageManager.shared
    
    private var adherence7Days: Double {
        storage.adherenceRate(days: 7)
    }
    
    private var adherence30Days: Double {
        storage.adherenceRate(days: 30)
    }
    
    private var sortedLogs: [DoseLog] {
        storage.doseLogs.sorted { $0.scheduledDate > $1.scheduledDate }
    }
    
    public var body: some View {
        NavigationView {
            List {
                // Section 1: Score & Adherence Rings
                Section {
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            // 7 Days Metric
                            VStack(spacing: 6) {
                                Text("\(Int(adherence7Days * 100))%")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.accentColor)
                                Text(loc("adherence_7_days"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(12)
                            
                            // 30 Days Metric
                            VStack(spacing: 6) {
                                Text("\(Int(adherence30Days * 100))%")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.18, green: 0.80, blue: 0.44))
                                Text(loc("adherence_30_days"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                        // Motivational badge
                        HStack(spacing: 10) {
                            Image(systemName: "flame.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc("consistency_title"))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text(loc("consistency_msg"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text(loc("adherence_overview"))
                }
                
                // Section 2: Recent Activity Logs
                Section {
                    if sortedLogs.isEmpty {
                        Text(loc("no_logs_msg"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(sortedLogs.prefix(30)) { log in
                            let med = storage.medications.first { $0.id == log.medicationId }
                            HStack(spacing: 12) {
                                PillIconView(
                                    form: med?.form ?? .capsule,
                                    color: med?.themeColor.color ?? .blue,
                                    size: 28
                                )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(med?.name ?? loc("medications_title"))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text(formattedLogDate(log.scheduledDate))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                statusBadge(log.status)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text(loc("dose_activity_log"))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(loc("progress_title"))
        }
    }
    
    private func statusBadge(_ status: DoseStatus) -> some View {
        HStack(spacing: 4) {
            switch status {
            case .taken:
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            case .skipped:
                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
            case .snoozed:
                Image(systemName: "clock.arrow.circlepath").foregroundColor(.orange)
            case .pending:
                Image(systemName: "circle").foregroundColor(.blue)
            }
            Text(status.localizedTitle)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor(status))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(8)
    }
    
    private func statusColor(_ status: DoseStatus) -> Color {
        switch status {
        case .taken: return .green
        case .skipped: return .secondary
        case .snoozed: return .orange
        case .pending: return .blue
        }
    }
    
    private func formattedLogDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.currentLanguage == .ptBR ? Locale(identifier: "pt_BR") : Locale(identifier: "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
