import SwiftUI

/// The animated blue ring. Idle breathes slowly; thinking spins faster and glows brighter.
struct CortanaOrb: View {
    let phase: ChatPhase
    var size: CGFloat = 72

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let speed: Double = phase == .idle ? 0.25 : (phase == .thinking ? 1.4 : 0.8)
            let pulse = 1 + 0.04 * sin(t * (phase == .idle ? 1.2 : 3))
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Theme.cortanaBlue.opacity(phase == .idle ? 0.25 : 0.5), .clear],
                                         center: .center, startRadius: 0, endRadius: size * 0.7))
                ring(width: size * 0.09, angle: t * speed * 360, trim: 0.75, color: Theme.cortanaBlue)
                ring(width: size * 0.05, angle: -t * speed * 240, trim: 0.5, color: Theme.cyan)
                    .scaleEffect(0.72)
                Circle()
                    .fill(Theme.cyan.opacity(0.9))
                    .frame(width: size * 0.16, height: size * 0.16)
                    .blur(radius: 1)
            }
            .frame(width: size, height: size)
            .scaleEffect(pulse)
            .shadow(color: Theme.cortanaBlue.opacity(phase == .idle ? 0.4 : 0.9), radius: size * 0.2)
        }
        .accessibilityHidden(true)
    }

    private func ring(width: CGFloat, angle: Double, trim: CGFloat, color: Color) -> some View {
        Circle()
            .trim(from: 0, to: trim)
            .stroke(AngularGradient(colors: [color.opacity(0), color], center: .center),
                    style: StrokeStyle(lineWidth: width, lineCap: .round))
            .rotationEffect(.degrees(angle))
    }
}

#Preview {
    HStack(spacing: 24) {
        CortanaOrb(phase: .idle)
        CortanaOrb(phase: .thinking)
    }
    .padding()
    .background(Theme.background)
}
