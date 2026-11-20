import SwiftUI

public struct TodayView: View {
    @ObservedObject var storage = StorageService.shared
    @State private var showingAddMedication = false
    
    private var calendar: Calendar { Calendar.current }
    
    // Week days around selected date
    private var currentWeekDays: [Date] {
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private var dosesForSelectedDate: [DailyDoseItem] {
        storage.doseItems(for: storage.selectedDate)
    }
    
    private var completedDosesCount: Int {
        dosesForSelectedDate.filter { $0.status == .taken }.count
    }
    
    private var totalDosesCount: Int {
        dosesForSelectedDate.count
    }
    
    private var progressRatio: Double {
        guard totalDosesCount > 0 else { return 1.0 }
        return Double(completedDosesCount) / Double(totalDosesCount)
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    // 1. Horizontal Date Strip
                    dateStripView
                    
                    // 2. Refill Warning Banner if any
                    if !storage.lowStockMeds.isEmpty {
                        refillBannerView
                    }
                    
                    // 3. Progress Card
                    progressCardView
                    
                    // 4. Period Groups (Morning, Afternoon, Evening, Night)
                    if dosesForSelectedDate.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(DayPeriod.allCases) { period in
                            let items = dosesForSelectedDate.filter { $0.period == period }
                            if !items.isEmpty {
                                periodSectionView(period: period, items: items)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddMedication = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddMedication) {
                AddEditMedicationView()
            }
        }
    }
    
    // MARK: - Date Strip View
    private var dateStripView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(currentWeekDays, id: \.self) { day in
                    let isSelected = calendar.isDate(day, inSameDayAs: storage.selectedDate)
                    let isToday = calendar.isDateInToday(day)
                    
                    Button {
                        storage.selectedDate = day
                    } label: {
                        VStack(spacing: 6) {
                            Text(dayOfWeekLetter(for: day))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(isSelected ? .white : .secondary)
                            
                            Text(dayOfMonthString(for: day))
                                .font(.headline)
                                .fontWeight(isSelected ? .bold : .semibold)
                                .foregroundColor(isSelected ? .white : .primary)
                            
                            if isToday {
                                Circle()
                                    .fill(isSelected ? .white : Color.accentColor)
                                    .frame(width: 5, height: 5)
                            } else {
                                Spacer().frame(height: 5)
                            }
                        }
                        .frame(width: 44, height: 68)
                        .background(isSelected ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Progress Card
    private var progressCardView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 54, height: 54)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(progressRatio, 1.0)))
                    .stroke(
                        LinearGradient(
                            colors: [Color.accentColor, Color(red: 0.15, green: 0.78, blue: 0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 54, height: 54)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progressRatio)
                
                Text("\(Int(progressRatio * 100))%")
                    .font(.system(size: 13, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Daily Adherence")
                    .font(.headline)
                
                Text(totalDosesCount == 0 ? "No meds scheduled" : "\(completedDosesCount) of \(totalDosesCount) doses taken")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if totalDosesCount > 0 && completedDosesCount < totalDosesCount {
                Button("Take All") {
                    storage.takeAllPending(on: storage.selectedDate)
                }
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.accentColor)
                .cornerRadius(12)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Refill Warning Banner
    private var refillBannerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(storage.lowStockMeds) { med in
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Low Stock: \(med.name)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Only \(Int(med.currentStock)) doses left. Refill soon!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("+30") {
                        var updated = med
                        updated.currentStock += 30
                        storage.updateMedication(updated)
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }
                .padding(12)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Period Section
    private func periodSectionView(period: DayPeriod, items: [DailyDoseItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: period.icon)
                        .foregroundColor(period.color)
                    Text(period.rawValue)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                let pendingCount = items.filter { $0.status == .pending }.count
                if pendingCount > 1 {
                    Button("Take All") {
                        storage.takeAllPending(for: period, on: storage.selectedDate)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.top, 6)
            
            ForEach(items) { item in
                PillCardView(
                    item: item,
                    onTake: {
                        storage.recordDose(medicationId: item.medication.id, scheduledDate: item.scheduledDate, status: .taken, doseAmount: item.doseTime.doseAmount)
                    },
                    onSnooze: {
                        storage.recordDose(medicationId: item.medication.id, scheduledDate: item.scheduledDate, status: .snoozed, doseAmount: item.doseTime.doseAmount)
                    },
                    onSkip: {
                        storage.recordDose(medicationId: item.medication.id, scheduledDate: item.scheduledDate, status: .skipped, doseAmount: item.doseTime.doseAmount)
                    }
                )
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Medications Scheduled")
                .font(.headline)
            Text("Enjoy your free day or add medications to track your treatment.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Medication") {
                showingAddMedication = true
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(Color.accentColor)
            .cornerRadius(12)
            .padding(.top, 6)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helpers
    private func dayOfWeekLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func dayOfMonthString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
