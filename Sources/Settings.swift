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
    @Published var armOpacity: Double { didSet { defaults.set(armOpacity, forKey: "armOpacity") } }
    @Published var armExtension: Double { didSet { defaults.set(armExtension, forKey: "armExtension") } }
    @Published var theme: AppTheme { didSet { defaults.set(theme.rawValue, forKey: "theme") } }
    @Published var idleEnabled: Bool { didSet { defaults.set(idleEnabled, forKey: "idleEnabled") } }
    @Published var idleDelay: Double { didSet { defaults.set(idleDelay, forKey: "idleDelay") } }
    @Published var pointerStyle: PointerStyle { didSet { defaults.set(pointerStyle.rawValue, forKey: "pointerStyle") } }
    var soundStyle: TapSound { pointerStyle.sound }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["mood": 0.65, "pointerSize": 1.0, "animateOnClick": true,
            "soundEnabled": true, "volume": 0.55, "shadowEnabled": true, "armOpacity": 0.2,
            "idleEnabled": true, "idleDelay": 60.0])
        mood = min(1, max(0, defaults.double(forKey: "mood")))
        pointerSize = min(1.6, max(0.65, defaults.object(forKey: "pointerSize") as? Double ?? 1))
        animateOnClick = defaults.bool(forKey: "animateOnClick")
        soundEnabled = defaults.bool(forKey: "soundEnabled")
        volume = min(1, max(0, defaults.double(forKey: "volume")))
        shadowEnabled = defaults.bool(forKey: "shadowEnabled")
        armOpacity = min(1, max(0, defaults.double(forKey: "armOpacity")))
        armExtension = min(1, max(0, defaults.double(forKey: "armExtension")))
        theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .system
        idleEnabled = defaults.bool(forKey: "idleEnabled")
        idleDelay = min(60, max(3, defaults.double(forKey: "idleDelay")))
        pointerStyle = PointerStyle(rawValue: defaults.string(forKey: "pointerStyle") ?? "") ?? .classic
    }
}

enum PointerStyle: String, CaseIterable, Identifiable {
    case classic = "Tiny hand", moonWand = "Moon wand", starWand = "Star wand", wizardWand = "Magic wand"
    case witch = "Witch hand", finnSword = "Finn sword", redLightsaber = "Red lightsaber", greenLightsaber = "Green lightsaber"
    static let rows: [[PointerStyle]] = [[.classic, .moonWand, .starWand, .wizardWand], [.witch, .finnSword, .redLightsaber, .greenLightsaber]]
    var id: String { rawValue }
    var isFingerHand: Bool { self == .classic || self == .witch }
    var title: String {
        switch self {
        case .classic: return "Classic"
        case .moonWand: return "Moon wand"
        case .starWand: return "Star wand"
        case .wizardWand: return "Magic wand"
        case .witch: return "Witch"
        case .finnSword: return "Finn sword"
        case .redLightsaber: return "Red saber"
        case .greenLightsaber: return "Green saber"
        }
    }
    var subtitle: String {
        switch self {
        case .classic: return "A classic cartoon glove."
        case .moonWand: return "A little moon prism magic."
        case .starWand: return "A wand from another dimension."
        case .wizardWand: return "Every click casts a little spell."
        case .witch: return "A little nightmare at your fingertips."
        case .finnSword: return "Adventure is just a click away."
        case .redLightsaber: return "A little power from the dark side."
        case .greenLightsaber: return "Let the Force guide your clicks."
        }
    }
    var sound: TapSound {
        switch self {
        case .classic: return .knock
        case .moonWand: return .moon
        case .starWand: return .star
        case .wizardWand: return .spell
        case .witch: return .witch
        case .finnSword: return .sword
        case .redLightsaber: return .redSaber
        case .greenLightsaber: return .greenSaber
        }
    }
}

enum TapSound: String, CaseIterable, Identifiable {
    case knock = "Cartoon knock", moon = "Moon chime", star = "Star sparkle", spell = "Magic swish"
    case witch = "Witch whisper", sword = "Adventure clang", redSaber = "Dark saber", greenSaber = "Force swish"
    var id: String { rawValue }
}
