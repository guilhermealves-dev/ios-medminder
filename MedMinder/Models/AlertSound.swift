import Foundation
import UserNotifications
import AudioToolbox

public enum AlertSound: String, CaseIterable, Codable, Identifiable {
    case `default` = "default"
    case chime = "chime"
    case marimba = "marimba"
    case crystal = "crystal"
    case pulse = "pulse"
    case zen = "zen"
    
    public var id: String { rawValue }
    
    public var localizedTitle: String {
        switch self {
        case .default: return loc("sound_default")
        case .chime: return loc("sound_chime")
        case .marimba: return loc("sound_marimba")
        case .crystal: return loc("sound_crystal")
        case .pulse: return loc("sound_pulse")
        case .zen: return loc("sound_zen")
        }
    }
    
    public var filename: String? {
        switch self {
        case .default: return nil
        case .chime: return "chime.wav"
        case .marimba: return "marimba.wav"
        case .crystal: return "crystal.wav"
        case .pulse: return "pulse.wav"
        case .zen: return "zen.wav"
        }
    }
    
    public var notificationSound: UNNotificationSound {
        if let filename = filename {
            return UNNotificationSound(named: UNNotificationSoundName(filename))
        }
        return .default
    }
}
