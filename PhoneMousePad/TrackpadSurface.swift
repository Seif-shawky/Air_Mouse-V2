import SwiftUI
import UIKit

struct TrackpadSurface: UIViewRepresentable {
    let onMove: (Double, Double) -> Void
    let onClick: () -> Void
    let onScroll: (Double, Double) -> Void

    func makeUIView(context: Context) -> TouchSurfaceView {
        let view = TouchSurfaceView()
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        view.onTouchUpdate = context.coordinator.handle(update:)
        return view
    }

    func updateUIView(_ uiView: TouchSurfaceView, context: Context) {
        context.coordinator.onMove = onMove
        context.coordinator.onClick = onClick
        context.coordinator.onScroll = onScroll
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onMove: onMove,
            onClick: onClick,
            onScroll: onScroll
        )
    }

    final class Coordinator {
        var onMove: (Double, Double) -> Void
        var onClick: () -> Void
        var onScroll: (Double, Double) -> Void

        private var touchStartDate: Date?
        private var movedEnoughToCancelTap = false
        private var activeTouchCount = 0
        private var pendingMove = CGPoint.zero
        private var pendingScroll = CGPoint.zero
        private var isFlushScheduled = false

        init(
            onMove: @escaping (Double, Double) -> Void,
            onClick: @escaping () -> Void,
            onScroll: @escaping (Double, Double) -> Void
        ) {
            self.onMove = onMove
            self.onClick = onClick
            self.onScroll = onScroll
        }

        func handle(update: TouchSurfaceView.TouchUpdate) {
            switch update.phase {
            case .began:
                flushPendingDeltas()
                activeTouchCount = update.touchCount
                touchStartDate = Date()
                movedEnoughToCancelTap = false

            case .moved:
                if activeTouchCount != update.touchCount {
                    flushPendingDeltas()
                    activeTouchCount = update.touchCount
                    return
                }

                let dx = update.delta.x
                let dy = update.delta.y

                if abs(dx) > 0.25 || abs(dy) > 0.25 {
                    movedEnoughToCancelTap = true
                }

                if update.touchCount >= 2 {
                    if abs(dx) > 0.1 || abs(dy) > 0.1 {
                        pendingScroll.x += dx
                        pendingScroll.y += dy
                        scheduleFlush()
                    }
                } else if update.touchCount == 1 {
                    if abs(dx) > 0.1 || abs(dy) > 0.1 {
                        pendingMove.x += dx
                        pendingMove.y += dy
                        scheduleFlush()
                    }
                }

            case .ended:
                flushPendingDeltas()
                let elapsed = touchStartDate.map { Date().timeIntervalSince($0) } ?? 0
                if update.previousTouchCount == 1,
                   elapsed < 0.28,
                   !movedEnoughToCancelTap {
                    onClick()
                }

                touchStartDate = nil
                movedEnoughToCancelTap = false
                activeTouchCount = 0
            }
        }

        private func scheduleFlush() {
            guard !isFlushScheduled else {
                return
            }

            isFlushScheduled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.012) { [weak self] in
                self?.flushPendingDeltas()
            }
        }

        private func flushPendingDeltas() {
            isFlushScheduled = false

            if abs(pendingMove.x) > 0.01 || abs(pendingMove.y) > 0.01 {
                onMove(Double(pendingMove.x), Double(pendingMove.y))
                pendingMove = .zero
            }

            if abs(pendingScroll.x) > 0.01 || abs(pendingScroll.y) > 0.01 {
                onScroll(Double(pendingScroll.x), Double(pendingScroll.y))
                pendingScroll = .zero
            }
        }
    }
}

final class TouchSurfaceView: UIView {
    enum Phase {
        case began
        case moved
        case ended
    }

    struct TouchUpdate {
        let phase: Phase
        let touchCount: Int
        let previousTouchCount: Int
        let delta: CGPoint
    }

    var onTouchUpdate: ((TouchUpdate) -> Void)?
    private var lastTouchCount = 0

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        sendUpdate(phase: .began, touches: touches, event: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let coalescedTouches = touches.flatMap { touch in
            event?.coalescedTouches(for: touch) ?? [touch]
        }

        for touch in coalescedTouches {
            sendUpdate(phase: .moved, touches: [touch], event: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        sendUpdate(phase: .ended, touches: touches, event: event, forcePreviousCount: lastTouchCount)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        sendUpdate(phase: .ended, touches: touches, event: event, forcePreviousCount: lastTouchCount)
    }

    private func sendUpdate(phase: Phase, touches changedTouches: Set<UITouch>, event: UIEvent?, forcePreviousCount: Int? = nil) {
        let activeTouches = Array(event?.allTouches?.filter { $0.phase != .ended && $0.phase != .cancelled } ?? [])
        let touchCount = activeTouches.count
        let previousTouchCount = forcePreviousCount ?? lastTouchCount
        let delta = Self.averageDelta(for: Array(changedTouches))

        onTouchUpdate?(
            TouchUpdate(
                phase: phase,
                touchCount: touchCount,
                previousTouchCount: previousTouchCount,
                delta: delta
            )
        )

        lastTouchCount = touchCount
    }

    private static func averageDelta(for touches: [UITouch]) -> CGPoint {
        guard !touches.isEmpty else {
            return .zero
        }

        let total = touches.reduce(CGPoint.zero) { partial, touch in
            let location = touch.location(in: touch.view)
            let previous = touch.previousLocation(in: touch.view)
            return CGPoint(
                x: partial.x + location.x - previous.x,
                y: partial.y + location.y - previous.y
            )
        }

        return CGPoint(
            x: total.x / CGFloat(touches.count),
            y: total.y / CGFloat(touches.count)
        )
    }
}
