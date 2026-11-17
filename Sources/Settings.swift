import Foundation
import Combine

final class TappySettings: ObservableObject {
    static let shared = TappySettings()
    private let defaults: UserDefaults

    @Published var mood: Double { didSet { defaults.set(mood, forKey: "mood") } }
    @Published var pointerSize: Double { didSet { defaults.set(pointerSize, forKey: "pointerSize") } }
    @Published var animateOnClick: Bool { didSet { defaults.set(animateOnClick, forKey: "animateOnClick") } }
    @Published var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "soundEnabled") } }
    @Published var volume: Double { didSet { defaults.set(volume, forKey: "volume") } }
    @Published var shadowEnabled: Bool { didSet { defaults.set(shadowEnabled, forKey: "shadowEnabled") } }
    @Published var pointerStyle: PointerStyle { didSet { defaults.set(pointerStyle.rawValue, forKey: "pointerStyle") } }
    var soundStyle: TapSound { pointerStyle.sound }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["mood": 0.65, "pointerSize": 1.0, "animateOnClick": true,
            "soundEnabled": true, "volume": 0.55, "shadowEnabled": true])
        mood = min(1, max(0, defaults.double(forKey: "mood")))
        pointerSize = min(1.6, max(0.65, defaults.object(forKey: "pointerSize") as? Double ?? 1))
        animateOnClick = defaults.bool(forKey: "animateOnClick")
        soundEnabled = defaults.bool(forKey: "soundEnabled")
        volume = min(1, max(0, defaults.double(forKey: "volume")))
        shadowEnabled = defaults.bool(forKey: "shadowEnabled")
        pointerStyle = PointerStyle(rawValue: defaults.string(forKey: "pointerStyle") ?? "") ?? .classic
    }
}

enum PointerStyle: String, CaseIterable, Identifiable {
    case classic = "Tiny hand", moonWand = "Moon wand", starWand = "Star wand", wizardWand = "Magic wand"
    var id: String { rawValue }
    var title: String {
        switch self { case .classic: return "Classic"; case .moonWand: return "Moon wand"; case .starWand: return "Star wand"; case .wizardWand: return "Magic wand" }
    }
    var subtitle: String {
        switch self {
        case .classic: return "A classic cartoon glove."
        case .moonWand: return "A little moon prism magic."
        case .starWand: return "A wand from another dimension."
        case .wizardWand: return "Every click casts a little spell."
        }
    }
    var sound: TapSound {
        switch self { case .classic: return .knock; case .moonWand: return .moon; case .starWand: return .star; case .wizardWand: return .spell }
    }
}

enum TapSound: String, CaseIterable, Identifiable {
    case knock = "Cartoon knock", moon = "Moon chime", star = "Star sparkle", spell = "Magic swish"
    var id: String { rawValue }
}
