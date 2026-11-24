import Foundation
import SwiftUI

// MARK: - Medication Form
public enum MedicationForm: String, CaseIterable, Codable, Identifiable {
    case capsule = "Capsule"
    case tablet = "Tablet"
    case liquid = "Liquid / Syrup"
    case drops = "Drops"
    case injection = "Injection"
    case inhaler = "Inhaler"
    case patch = "Patch"
    case spray = "Spray"
    
    public var id: String { rawValue }
    
    public var localizedTitle: String {
        switch self {
        case .capsule: return loc("form_capsule")
        case .tablet: return loc("form_tablet")
        case .liquid: return loc("form_liquid")
        case .drops: return loc("form_drops")
        case .injection: return loc("form_injection")
        case .inhaler: return loc("form_inhaler")
        case .patch: return loc("form_patch")
        case .spray: return loc("form_spray")
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .capsule: return "pill.fill"
        case .tablet: return "circle.fill"
        case .liquid: return "drop.fill"
        case .drops: return "eyedropper.halffull"
        case .injection: return "cross.vial.fill"
        case .inhaler: return "lungs.fill"
        case .patch: return "bandage.fill"
        case .spray: return "bubbles.and.sparkles.fill"
        }
    }
}

// MARK: - Meal Instruction
public enum MealInstruction: String, CaseIterable, Codable, Identifiable {
    case anytime = "Anytime"
    case beforeMeal = "Before meal"
    case withMeal = "With meal"
    case afterMeal = "After meal"
    
    public var id: String { rawValue }
    
    public var localizedTitle: String {
        switch self {
        case .anytime: return loc("meal_anytime")
        case .beforeMeal: return loc("meal_before")
        case .withMeal: return loc("meal_with")
        case .afterMeal: return loc("meal_after")
        }
    }
    
    public var icon: String {
        switch self {
        case .anytime: return "clock"
        case .beforeMeal: return "fork.knife.circle"
        case .withMeal: return "fork.knife"
        case .afterMeal: return "cup.and.saucer.fill"
        }
    }
}

// MARK: - Frequency Type
public enum FrequencyType: String, CaseIterable, Codable, Identifiable {
    case everyday = "Every day"
    case specificDays = "Specific days of week"
    case everyXHours = "Every X hours"
    case asNeeded = "As needed (PRN)"
    
    public var id: String { rawValue }
    
    public var localizedTitle: String {
        switch self {
        case .everyday: return loc("freq_everyday")
        case .specificDays: return loc("freq_specific_days")
        case .everyXHours: return loc("freq_every_x_hours")
        case .asNeeded: return loc("freq_as_needed")
        }
    }
}

// MARK: - Pill Color Preset
public enum PillThemeColor: String, CaseIterable, Codable, Identifiable {
    case sapphire = "Sapphire Blue"
    case coral = "Coral Red"
    case emerald = "Emerald Green"
    case amber = "Amber Orange"
    case violet = "Amethyst Purple"
    case teal = "Teal Cyan"
    case pink = "Bubblegum Pink"
    
    public var id: String { rawValue }
    
    public var localizedTitle: String {
        switch self {
        case .sapphire: return loc("color_sapphire")
        case .coral: return loc("color_coral")
        case .emerald: return loc("color_emerald")
        case .amber: return loc("color_amber")
        case .violet: return loc("color_violet")
        case .teal: return loc("color_teal")
        case .pink: return loc("color_pink")
        }
    }
    
    public var color: Color {
        switch self {
        case .sapphire: return Color(red: 0.12, green: 0.53, blue: 0.95)
        case .coral: return Color(red: 0.96, green: 0.35, blue: 0.35)
        case .emerald: return Color(red: 0.18, green: 0.80, blue: 0.44)
        case .amber: return Color(red: 0.98, green: 0.65, blue: 0.15)
        case .violet: return Color(red: 0.62, green: 0.35, blue: 0.92)
        case .teal: return Color(red: 0.15, green: 0.78, blue: 0.85)
        case .pink: return Color(red: 0.96, green: 0.42, blue: 0.68)
        }
    }
}

// MARK: - Dose Time Item
public struct DoseTime: Codable, Identifiable, Hashable {
    public var id: UUID = UUID()
    public var hour: Int
    public var minute: Int
    public var doseAmount: Double
    
    public init(hour: Int, minute: Int, doseAmount: Double = 1.0) {
        self.id = UUID()
        self.hour = hour
        self.minute = minute
        self.doseAmount = doseAmount
    }
    
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        if let date = Calendar.current.date(from: comps) {
            return formatter.string(from: date)
        }
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - Medication Model
public struct Medication: Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var strength: String
    public var form: MedicationForm
    public var themeColor: PillThemeColor
    public var instruction: MealInstruction
    public var frequency: FrequencyType
    public var selectedDays: Set<Int>
    public var doseTimes: [DoseTime]
    public var intervalHours: Int?
    
    // Inventory / Refill
    public var currentStock: Double
    public var refillThreshold: Double
    public var refillAlertEnabled: Bool
    
    public var notes: String
    public var isActive: Bool
    public var createdAt: Date
    public var alertSound: AlertSound
    
    enum CodingKeys: String, CodingKey {
        case id, name, strength, form, themeColor, instruction, frequency
        case selectedDays, doseTimes, intervalHours, currentStock, refillThreshold
        case refillAlertEnabled, notes, isActive, createdAt, alertSound
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.strength = try container.decode(String.self, forKey: .strength)
        self.form = try container.decode(MedicationForm.self, forKey: .form)
        self.themeColor = try container.decode(PillThemeColor.self, forKey: .themeColor)
        self.instruction = try container.decode(MealInstruction.self, forKey: .instruction)
        self.frequency = try container.decode(FrequencyType.self, forKey: .frequency)
        self.selectedDays = try container.decode(Set<Int>.self, forKey: .selectedDays)
        self.doseTimes = try container.decode([DoseTime].self, forKey: .doseTimes)
        self.intervalHours = try container.decodeIfPresent(Int.self, forKey: .intervalHours)
        self.currentStock = try container.decode(Double.self, forKey: .currentStock)
        self.refillThreshold = try container.decode(Double.self, forKey: .refillThreshold)
        self.refillAlertEnabled = try container.decode(Bool.self, forKey: .refillAlertEnabled)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.alertSound = try container.decodeIfPresent(AlertSound.self, forKey: .alertSound) ?? .default
    }
    
    public init(
        id: UUID = UUID(),
        name: String = "",
        strength: String = "",
        form: MedicationForm = .capsule,
        themeColor: PillThemeColor = .sapphire,
        instruction: MealInstruction = .anytime,
        frequency: FrequencyType = .everyday,
        selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7],
        doseTimes: [DoseTime] = [DoseTime(hour: 8, minute: 0)],
        intervalHours: Int? = 8,
        currentStock: Double = 30,
        refillThreshold: Double = 5,
        refillAlertEnabled: Bool = true,
        notes: String = "",
        isActive: Bool = true,
        createdAt: Date = Date(),
        alertSound: AlertSound = .default
    ) {
        self.id = id
        self.name = name
        self.strength = strength
        self.form = form
        self.themeColor = themeColor
        self.instruction = instruction
        self.frequency = frequency
        self.selectedDays = selectedDays
        self.doseTimes = doseTimes
        self.intervalHours = intervalHours
        self.currentStock = currentStock
        self.refillThreshold = refillThreshold
        self.refillAlertEnabled = refillAlertEnabled
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.alertSound = alertSound
    }
}
