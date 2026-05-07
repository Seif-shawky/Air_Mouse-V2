# MousePhone

MousePhone contains two SwiftUI apps:

- `MacMouseHost`: a macOS receiver that advertises a nearby peer, moves/clicks the Mac pointer, scrolls, and changes Mac volume.
- `PhoneMousePad`: an iPhone sender that discovers the Mac over `MultipeerConnectivity`, using nearby Wi-Fi or Bluetooth automatically.

## Run It

1. Open `MousePhone.xcodeproj` in Xcode.
2. Select the `MacMouseHost` scheme and run it on `My Mac`.
3. Select the `PhoneMousePad` scheme, choose the connected iPhone XS, and run it.
4. Keep both apps open. The iPhone app will search for the Mac and connect.

## Permissions

On the Mac, allow Accessibility access for `MacMouseHost` when prompted. This is required for pointer movement and mouse clicks.

On the iPhone, allow Local Network and Bluetooth prompts if iOS shows them.

## Behavior

- Drag on the iPhone screen to move the Mac pointer.
- Tap the iPhone screen to send a left mouse click. The click-down message is encoded as `start`.
- Press the iPhone volume buttons to send volume up/down changes to the Mac.
