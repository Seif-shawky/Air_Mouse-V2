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

## run

cd "/Users/seifshawky/seif_projects/Mouse_proj V2"

xcodebuild -project MousePhone.xcodeproj -scheme MacMouseHost -configuration Debug -destination platform=macOS build
open ~/Library/Developer/Xcode/DerivedData/MousePhone-bnhfppueftdngacizcwipptfoory/Build/Products/Debug/MacMouseHost.app

xcodebuild -allowProvisioningUpdates -project MousePhone.xcodeproj -scheme PhoneMousePad -configuration Debug -destination platform=iOS,id=00008020-000845E90E06002E build

xcrun devicectl device install app --device C429EB5B-04EC-5059-B127-F41237D6A21B ~/Library/Developer/Xcode/DerivedData/MousePhone-bnhfppueftdngacizcwipptfoory/Build/Products/Debug-iphoneos/PhoneMousePad.app

xcrun devicectl device process launch --device C429EB5B-04EC-5059-B127-F41237D6A21B com.mousepad.phone.client
