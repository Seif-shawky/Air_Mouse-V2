import ApplicationServices
import CoreGraphics
import Foundation

final class MouseController {
    private let sensitivity = 1.15
    private let scrollSensitivity = 1.4
    private let eventSource = CGEventSource(stateID: .hidSystemState)
    private var lastMouseDownLocation: CGPoint?
    private var fractionalMove = CGPoint.zero

    func requestAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func moveBy(dx: Double, dy: Double) {
        guard let current = CGEvent(source: nil)?.location else {
            return
        }

        let scaledX = (dx * sensitivity) + fractionalMove.x
        let scaledY = (dy * sensitivity) + fractionalMove.y
        let wholeX = scaledX.rounded(.towardZero)
        let wholeY = scaledY.rounded(.towardZero)
        fractionalMove = CGPoint(x: scaledX - wholeX, y: scaledY - wholeY)

        guard wholeX != 0 || wholeY != 0 else {
            return
        }

        let next = CGPoint(
            x: current.x + wholeX,
            y: current.y + wholeY
        )

        let event = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .mouseMoved,
            mouseCursorPosition: next,
            mouseButton: .left
        )
        event?.setIntegerValueField(.mouseEventDeltaX, value: Int64(wholeX))
        event?.setIntegerValueField(.mouseEventDeltaY, value: Int64(wholeY))
        event?.post(tap: .cghidEventTap)
    }

    func leftClick(kind: RemoteMessage.ClickKind) {
        let location = CGEvent(source: nil)?.location ?? lastMouseDownLocation ?? .zero
        let eventType: CGEventType = kind == .start ? .leftMouseDown : .leftMouseUp

        if kind == .start {
            lastMouseDownLocation = location
        } else {
            lastMouseDownLocation = nil
        }

        let event = CGEvent(
            mouseEventSource: eventSource,
            mouseType: eventType,
            mouseCursorPosition: location,
            mouseButton: .left
        )
        event?.setIntegerValueField(.mouseEventClickState, value: 1)
        event?.post(tap: .cghidEventTap)
    }

    func scroll(dx: Double, dy: Double) {
        let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(-dy * scrollSensitivity),
            wheel2: Int32(-dx * scrollSensitivity),
            wheel3: 0
        )
        event?.setIntegerValueField(.scrollWheelEventScrollPhase, value: Int64(CGScrollPhase.changed.rawValue))
        event?.post(tap: .cghidEventTap)
    }
}
