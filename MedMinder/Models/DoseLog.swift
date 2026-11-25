import Foundation
import SwiftUI

// MARK: - Dose Status
public enum DoseStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case taken = "Taken"
    case skipped = "Skipped"
    case snoozed = "Snoozed"
    
    public var localizedTitle: String {
        switch self {
        case .pending: return loc("status_pending")
        case .taken: return loc("status_taken")
        case .skipped: return loc("status_skipped")
        case .snoozed: return loc("status_snoozed")
        }
    }
}

// MARK: - Day Period for Grouping
public enum DayPeriod: String, CaseIterable, Identifiable {
    case dawn = "Dawn"
    case morning = "Morning"
    case afternoon = "Afternoon"
    case night = "Night"
    
    public var id: String { rawValue }
    
    public var localizedTitle: String {
        switch self {
        case .dawn: return loc("period_dawn")
        case .morning: return loc("period_morning")
        case .afternoon: return loc("period_afternoon")
        case .night: return loc("period_night")
        }
    }
    
    public var icon: String {
        switch self {
        case .dawn: return "moon.zzz.fill"
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .night: return "moon.stars.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .dawn: return .purple
        case .morning: return .orange
        case .afternoon: return .yellow
        case .night: return .indigo
        }
    }
    
    public static func forHour(_ hour: Int) -> DayPeriod {
        switch hour {
        case 0..<5: return .dawn
        case 5..<12: return .morning
        case 12..<18: return .afternoon
        default: return .night
        }
    }
}

// MARK: - Dose Log Entry
public struct DoseLog: Codable, Identifiable {
    public var id: UUID
    public var medicationId: UUID
    public var scheduledDate: Date
    public var status: DoseStatus
    public var actualTime: Date?
    public var doseAmount: Double
    public var snoozeUntil: Date?
    
    public init(
        id: UUID = UUID(),
        medicationId: UUID,
        scheduledDate: Date,
        status: DoseStatus = .pending,
        actualTime: Date? = nil,
        doseAmount: Double = 1.0,
        snoozeUntil: Date? = nil
    ) {
        self.id = id
        self.medicationId = medicationId
        self.scheduledDate = scheduledDate
        self.status = status
        self.actualTime = actualTime
        self.doseAmount = doseAmount
        self.snoozeUntil = snoozeUntil
    }
}

// MARK: - Resolved Daily Dose Item
public struct DailyDoseItem: Identifiable {
    public var id: String { "\(medication.id.uuidString)-\(scheduledDate.timeIntervalSince1970)" }
    public let medication: Medication
    public let scheduledDate: Date
    public let doseTime: DoseTime
    public var status: DoseStatus
    public var log: DoseLog?
    
    public var hour: Int { doseTime.hour }
    public var minute: Int { doseTime.minute }
    
    public var period: DayPeriod {
        DayPeriod.forHour(hour)
    }
    
    public var formattedTime: String {
        doseTime.formattedTime
    }
}
