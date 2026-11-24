import Foundation
import AVFoundation
import AudioToolbox

public final class SoundPreviewPlayer {
    public static let shared = SoundPreviewPlayer()
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    public func play(_ sound: AlertSound) {
        guard let filename = sound.filename else {
            // System default sound preview
            AudioServicesPlaySystemSound(1007)
            return
        }
        
        let parts = filename.split(separator: ".")
        guard parts.count == 2,
              let url = Bundle.main.url(forResource: String(parts[0]), withExtension: String(parts[1])) else {
            AudioServicesPlaySystemSound(1007)
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing sound preview: \(error.localizedDescription)")
            AudioServicesPlaySystemSound(1007)
        }
    }
}
