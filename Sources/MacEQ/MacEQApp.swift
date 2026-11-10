import AppKit
import MacEQCore
import SwiftUI

/// Sunrise Limiter is a menu-bar-only utility. The Core Audio engine starts
/// immediately so system audio is protected as soon as permission is granted.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let controller = EQController()
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItemController = StatusItemController(controller: Self.controller)
        Self.controller.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        Self.controller.stop()
    }
}

@main
struct SunriseLimiterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The app has no regular windows or Dock presence. Its only surface is
        // the compact NSPopover attached to the menu-bar status item.
        MenuBarExtra("Sunrise Limiter", systemImage: "water.waves", isInserted: .constant(false)) {
            EmptyView()
        }
    }
}

struct EQPopoverView: View {
    @ObservedObject var controller: EQController

    private let aqua = Color(red: 1.0000, green: 0.7020, blue: 0.2784)
    private let deepWater = Color(red: 0.0549, green: 0.1020, blue: 0.2275)
    private let sand = Color(red: 1.0000, green: 0.8200, blue: 0.5700)
    private let muted = Color(red: 0.76, green: 0.78, blue: 0.86).opacity(0.78)
    private let divider = Color(red: 1.0, green: 0.76, blue: 0.48).opacity(0.16)

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            header
            sectionDivider
            ceilingControl
            sectionDivider
            gainReduction
            sectionDivider
            peakReadings
            if let error = controller.errorMessage {
                Text(error)
                    .font(LimiterType.mono(10, weight: .medium))
                    .foregroundStyle(Color(red: 1, green: 0.48, blue: 0.42))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 18)
        .frame(width: 360, alignment: .leading)
        .background {
            SunriseMountainBackdrop()
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Audio Limiter")
                .font(LimiterType.mono(14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.94))
                .lineLimit(1)
            Spacer(minLength: 8)
            Toggle("Limiter", isOn: $controller.limiterEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(aqua)
                .help("Enable or bypass the limiter")
        }
        .frame(height: 24)
    }

    private var ceilingControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("CEILING")
                    .font(LimiterType.mono(10, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(muted)
                Spacer()
                Text(String(format: "%.1f dBFS", controller.limiterThresholdDB))
                    .font(LimiterType.mono(14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(sand)
                    .lineLimit(1)
                    .fixedSize()
            }
            Slider(value: $controller.limiterThresholdDB, in: -24 ... -3, step: 0.5)
                .controlSize(.regular)
                .tint(aqua)
                .disabled(!controller.limiterEnabled)
            HStack {
                Text("−24 dBFS")
                Spacer()
                Text("−3 dBFS")
            }
            .font(LimiterType.mono(9, weight: .regular))
            .foregroundStyle(muted)
        }
    }

    private var gainReduction: some View {
        let live = controller.limiterEnabled ? controller.limiterGainReductionDB : 0
        let maximum = controller.limiterMaxGainReductionDB
        return VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text("GAIN REDUCTION")
                    .font(LimiterType.mono(10, weight: .medium))
                    .tracking(0.35)
                    .foregroundStyle(muted)
                Spacer(minLength: 8)
                valuePair(label: "LIVE", value: live, color: .white.opacity(0.92))
                valuePair(label: "MAX", value: maximum, color: aqua)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule()
                        .fill(LinearGradient(colors: [aqua, deepWater, sand], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, proxy.size.width * min(max(live / 24, 0), 1)))
                }
            }
            .frame(height: 7)
        }
    }

    private func valuePair(label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(LimiterType.mono(8, weight: .medium))
                .foregroundStyle(muted)
            Text(value < 0.05 ? "0.0" : String(format: "−%.1f", value))
                .font(LimiterType.mono(10, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize()
            Text("dB")
                .font(LimiterType.mono(8, weight: .regular))
                .foregroundStyle(muted)
        }
        .fixedSize()
    }

    private var peakReadings: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text("PEAK LEVELS")
                    .font(LimiterType.mono(10, weight: .medium))
                    .tracking(0.35)
                    .foregroundStyle(muted)
                Text("dBFS")
                    .font(LimiterType.mono(9, weight: .regular))
                    .foregroundStyle(muted.opacity(0.8))
                Spacer()
                Button {
                    controller.resetLimiterMeterPeaks()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("RESET")
                    }
                    .font(LimiterType.mono(9, weight: .medium))
                    .foregroundStyle(aqua)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 7)
                    .background(aqua.opacity(0.10), in: RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help("Reset held maximum readings")
            }
            HStack(alignment: .top, spacing: 0) {
                peakColumn(title: "INPUT", peak: controller.limiterMaxInputPeakDBFS, live: controller.limiterInputPeakDBFS, valueColor: .white.opacity(0.95))
                Rectangle()
                    .fill(divider)
                    .frame(width: 1, height: 43)
                    .padding(.horizontal, 15)
                peakColumn(title: "OUTPUT", peak: controller.limiterMaxOutputPeakDBFS, live: controller.limiterOutputPeakDBFS, valueColor: sand)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func peakColumn(title: String, peak: Double, live: Double, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(LimiterType.mono(9, weight: .medium))
                .tracking(0.45)
                .foregroundStyle(muted)
            Text(String(format: "%.1f", peak))
                .font(LimiterType.mono(20, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: true, vertical: false)
            HStack(spacing: 4) {
                Text("NOW")
                    .foregroundStyle(muted)
                Text(String(format: "%.1f", live))
                    .foregroundStyle(.white.opacity(0.76))
            }
            .font(LimiterType.mono(9, weight: .regular))
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(divider)
            .frame(height: 1)
    }
}

/// A quiet Sunrise landscape: deep twilight sky, warm horizon and layered
/// mountain silhouettes. Deliberately no sun disk or decorative logo.
private struct SunriseMountainBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.035, green: 0.055, blue: 0.12), location: 0),
                        .init(color: Color(red: 0.075, green: 0.12, blue: 0.23), location: 0.58),
                        .init(color: Color(red: 0.30, green: 0.16, blue: 0.16), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.55, blue: 0.25).opacity(0.18), .clear],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
                Canvas { context, size in
                    func ridge(_ points: [CGPoint], color: Color) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: size.height))
                        path.addLine(to: CGPoint(x: points[0].x * size.width, y: points[0].y * size.height))
                        for point in points.dropFirst() {
                            path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
                        }
                        path.addLine(to: CGPoint(x: size.width, y: size.height))
                        path.closeSubpath()
                        context.fill(path, with: .color(color))
                    }
                    ridge([CGPoint(x: 0.00, y: 0.72), CGPoint(x: 0.17, y: 0.55), CGPoint(x: 0.31, y: 0.68), CGPoint(x: 0.48, y: 0.49), CGPoint(x: 0.66, y: 0.69), CGPoint(x: 0.83, y: 0.53), CGPoint(x: 1.00, y: 0.68)], color: Color(red: 0.10, green: 0.13, blue: 0.22).opacity(0.76))
                    ridge([CGPoint(x: 0.00, y: 0.83), CGPoint(x: 0.20, y: 0.68), CGPoint(x: 0.38, y: 0.80), CGPoint(x: 0.58, y: 0.63), CGPoint(x: 0.76, y: 0.78), CGPoint(x: 1.00, y: 0.65)], color: Color(red: 0.055, green: 0.075, blue: 0.14).opacity(0.94))
                    ridge([CGPoint(x: 0.00, y: 0.91), CGPoint(x: 0.23, y: 0.82), CGPoint(x: 0.44, y: 0.89), CGPoint(x: 0.70, y: 0.78), CGPoint(x: 1.00, y: 0.88)], color: Color(red: 0.025, green: 0.04, blue: 0.085).opacity(0.98))
                }
                LinearGradient(colors: [.clear, Color(red: 0.018, green: 0.028, blue: 0.065).opacity(0.68)], startPoint: .center, endPoint: .bottom)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

/// JetBrains Mono is used for the complete control surface. If the font is not
/// installed, AppKit/SwiftUI falls back to the platform's monospaced face.
private enum LimiterType {
    static func mono(_ size: CGFloat, weight: Weight = .regular) -> Font {
        let face: String
        switch weight {
        case .medium: face = "JetBrainsMono-Medium"
        case .semibold: face = "JetBrainsMono-SemiBold"
        case .bold: face = "JetBrainsMono-Bold"
        default: face = "JetBrainsMono-Regular"
        }
        return .custom(face, size: size, relativeTo: .body)
    }

    enum Weight { case regular, medium, semibold, bold }
}

struct StatusFooterView: View {
    let isRunning: Bool
    @ObservedObject var statusModel: EngineStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isRunning ? Color.green : Color.red)
                    .frame(width: 7, height: 7)
                Text(statusModel.summary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(statusModel.diagnosticLines, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } label: {
                Text("Diagnostics")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

/// Center-zero vertical slider: fill grows from the middle, gradient accent,
/// double-click resets to 0, drag snaps to 0.5 dB.
struct VerticalSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    private let trackWidth: CGFloat = 5
    private let knobSize: CGFloat = 13
    private static let accent = LinearGradient(
        colors: [Color.purple, Color.blue],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let knobY = yPosition(for: value, height: height)
            let centerY = height / 2

            ZStack(alignment: .top) {
                Capsule()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: trackWidth)
                    .frame(maxWidth: .infinity)
                Rectangle()
                    .fill(Self.accent)
                    .frame(width: trackWidth)
                    .frame(height: abs(centerY - knobY))
                    .offset(y: min(knobY, centerY))
                    .frame(maxWidth: .infinity)
                Rectangle()
                    .fill(Color.primary.opacity(0.35))
                    .frame(width: trackWidth + 6, height: 1)
                    .offset(y: centerY)
                    .frame(maxWidth: .infinity)
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                    .frame(width: knobSize, height: knobSize)
                    .offset(y: knobY - knobSize / 2)
                    .frame(maxWidth: .infinity)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        value = valueFor(y: gesture.location.y, height: height)
                    }
            )
            .onTapGesture(count: 2) {
                value = 0
            }
        }
    }

    private func yPosition(for value: Double, height: CGFloat) -> CGFloat {
        let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return height * CGFloat(1 - fraction)
    }

    private func valueFor(y: CGFloat, height: CGFloat) -> Double {
        let fraction = 1 - Double(min(max(y, 0), height) / height)
        let raw = range.lowerBound + fraction * (range.upperBound - range.lowerBound)
        return (raw * 2).rounded() / 2
    }
}
