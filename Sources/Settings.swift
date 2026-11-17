import Foundation
import Combine

final class TappySettings: ObservableObject {
    static let shared = TappySettings()

    @Published var mood: Double = 0.5
    @Published var animateOnClick: Bool = true
    @Published var soundEnabled: Bool = true
    @Published var pointerStyle: PointerStyle = .tinyHand

    private init() {}
}

enum PointerStyle: String, CaseIterable, Identifiable {
    case tinyHand = "Tiny hand"
    case catPaw = "Cat paw"
    case middleChild = "Middle child"

    var id: String { rawValue }
}
