import Foundation
import SwiftUI

struct MidiTrack: Identifiable, Hashable {
    let id: UUID = UUID()
    let title: String
    let category: String
    let duration: TimeInterval
    let fileName: String
    let color: Color
}

class MidiTrackList {
    static let list: [MidiTrack] = [
        MidiTrack(title: "Serenade", category: "Classic Pop", duration: 45.0, fileName: "Serenade", color: .pink),
        MidiTrack(title: "Clarity", category: "K-Pop", duration: 40.0, fileName: "Clarity", color: .red),
        MidiTrack(title: "Solitude", category: "Pop", duration: 42.0, fileName: "Solitude", color: .orange),
        MidiTrack(title: "Velvet Glow", category: "Techno", duration: 35.0, fileName: "Velvet", color: .blue),
        MidiTrack(title: "Ethereal Echoes", category: "Ambient", duration: 38.0, fileName: "Ethereal", color: .purple),
        MidiTrack(title: "Luminous Wind", category: "Chill", duration: 32.0, fileName: "Luminous", color: .cyan),
        MidiTrack(title: "Halcyon Days", category: "Retro", duration: 30.0, fileName: "Halcyon", color: .yellow),
        MidiTrack(title: "Solace Garden", category: "Minimal", duration: 25.0, fileName: "Solace", color: .green),
        MidiTrack(title: "Whispering Bells", category: "Ambient", duration: 28.0, fileName: "Whisper", color: .mint),
        MidiTrack(title: "Nebula Dream", category: "Space", duration: 35.0, fileName: "Nebula", color: .indigo),
        MidiTrack(title: "Midnight Drive", category: "Jazz", duration: 40.0, fileName: "Midnight", color: .slate),
        MidiTrack(title: "Aurora Borealis", category: "Latin", duration: 32.0, fileName: "Aurora", color: .orange),
        MidiTrack(title: "Symphony of Lights", category: "Classical", duration: 42.0, fileName: "Symphony", color: .red),
        MidiTrack(title: "Retrograde Arcade", category: "Synthwave", duration: 36.0, fileName: "Retrograde", color: .pink),
        MidiTrack(title: "Nostalgia Lane", category: "Epic", duration: 45.0, fileName: "Nostalgia", color: .blue),
        MidiTrack(title: "Devotion Waltz", category: "Acoustic", duration: 40.0, fileName: "Devotion", color: .teal),
        MidiTrack(title: "Harmony Breeze", category: "Lofi", duration: 38.0, fileName: "Harmony", color: .purple),
        MidiTrack(title: "Jubilee Day", category: "Ballad", duration: 42.0, fileName: "Jubilee", color: .magenta),
        MidiTrack(title: "Horizon Waves", category: "Nature", duration: 35.0, fileName: "Horizon", color: .cyan),
        MidiTrack(title: "Affinity Spark", category: "R&B", duration: 32.0, fileName: "Affinity", color: .green)
    ]
}

extension Color {
    static let slate = Color(red: 0.18, green: 0.24, blue: 0.35)
    static let magenta = Color(red: 0.85, green: 0.08, blue: 0.52)
}
