import SwiftUI

enum Theme {
    static let cortanaBlue = Color(red: 0.0, green: 0.55, blue: 1.0)
    static let cyan = Color(red: 0.35, green: 0.85, blue: 1.0)
    static let backgroundTop = Color(red: 0.02, green: 0.05, blue: 0.12)
    static let backgroundBottom = Color.black
    static let assistantBubble = Color.white.opacity(0.08)
    static let userBubble = cortanaBlue.opacity(0.85)

    static var background: some View {
        LinearGradient(colors: [backgroundTop, backgroundBottom], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}
