import Foundation

final class VolumeController {
    func changeVolume(by delta: Double) {
        let step = delta > 0 ? 7 : -7
        let script = """
        set currentVolume to output volume of (get volume settings)
        set nextVolume to currentVolume + \(step)
        if nextVolume is greater than 100 then set nextVolume to 100
        if nextVolume is less than 0 then set nextVolume to 0
        set volume output volume nextVolume
        """

        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }
}
