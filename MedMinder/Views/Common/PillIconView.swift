import SwiftUI

public struct PillIconView: View {
    public let form: MedicationForm
    public let color: Color
    public var size: CGFloat = 36
    
    public init(form: MedicationForm, color: Color, size: CGFloat = 36) {
        self.form = form
        self.color = color
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Soft glowing background circle
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: size * 1.3, height: size * 1.3)
            
            switch form {
            case .capsule:
                CapsuleShapeView(color: color, size: size)
            case .tablet:
                TabletShapeView(color: color, size: size)
            default:
                Image(systemName: form.systemIcon)
                    .font(.system(size: size * 0.55, weight: .semibold))
                    .foregroundColor(color)
            }
        }
    }
}

// Custom 2-Tone Capsule
private struct CapsuleShapeView: View {
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.46, height: size * 0.95)
                .rotationEffect(.degrees(45))
                .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
            
            // Bottom half highlight (gives the distinct capsule two-half look)
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: size * 0.46, height: size * 0.45)
                .offset(y: size * 0.22)
                .rotationEffect(.degrees(45))
        }
    }
}

// Custom Round Tablet with Embossed Center Line
private struct TabletShapeView: View {
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.9), color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.85, height: size * 0.85)
                .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
            
            // Center groove line
            Rectangle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 2, height: size * 0.65)
                .rotationEffect(.degrees(30))
        }
    }
}
