import SwiftUI

public struct PillCardView: View {
    public let item: DailyDoseItem
    public let onTake: () -> Void
    public let onSnooze: () -> Void
    public let onSkip: () -> Void
    
    public init(
        item: DailyDoseItem,
        onTake: @escaping () -> Void,
        onSnooze: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.item = item
        self.onTake = onTake
        self.onSnooze = onSnooze
        self.onSkip = onSkip
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Pill Form & Color Icon
            PillIconView(
                form: item.medication.form,
                color: item.medication.themeColor.color,
                size: 38
            )
            
            // Medication Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.medication.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !item.medication.strength.isEmpty {
                        Text(item.medication.strength)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                        Text(item.formattedTime)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 3) {
                        Image(systemName: item.medication.instruction.icon)
                        Text(item.medication.instruction.rawValue)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action or Status
            switch item.status {
            case .taken:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Taken")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.12))
                .cornerRadius(12)
                
            case .skipped:
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                    Text("Skipped")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(12)
                
            case .snoozed:
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.orange)
                    Text("Snoozed")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(12)
                
            case .pending:
                HStack(spacing: 8) {
                    // Snooze Button
                    Button(action: onSnooze) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.orange)
                            .frame(width: 34, height: 34)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    // Skip Button
                    Button(action: onSkip) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 34, height: 34)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    // Take Button
                    Button(action: onTake) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(item.medication.themeColor.color)
                            .clipShape(Circle())
                            .shadow(color: item.medication.themeColor.color.opacity(0.4), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
    }
}
