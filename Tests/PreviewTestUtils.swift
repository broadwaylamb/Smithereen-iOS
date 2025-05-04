import Testing
import SnapshotTesting
import SwiftUI
import Prefire

extension PreviewTests {
    func assertSnapshots<Content: View>(
        for prefireSnapshot: PrefireSnapshot<Content>,
        sourceLocation: SourceLocation = #_sourceLocation,
    ) {
        if snapshotDevices.isEmpty {
            assertSnapshot(for: prefireSnapshot, sourceLocation: sourceLocation)
            return
        }

        for deviceName in snapshotDevices {
            var snapshot = prefireSnapshot
            guard let device: DeviceConfig = PreviewDevice(rawValue: deviceName).snapshotDevice() else {
                fatalError("Unknown device name from configuration file: \(deviceName)")
            }

            snapshot.name = "\(prefireSnapshot.name)-\(deviceName)"
            snapshot.device = device

            // Ignore specific device safe area
            snapshot.device.safeArea = .zero

            // Ignore specific device display scale
            snapshot.traits = UITraitCollection(displayScale: 2.0)

            assertSnapshot(for: snapshot, sourceLocation: sourceLocation)
        }
    }

    func assertSnapshot<Content: View>(
        for prefireSnapshot: PrefireSnapshot<Content>,
        sourceLocation: SourceLocation = #_sourceLocation,
    ) {
        let (previewView, preferences) = prefireSnapshot.loadViewWithPreferences()

        if let failure = verifySnapshot(
            of: previewView,
            as: .wait(
                for: preferences.delay,
                on: .image(
                    precision: preferences.precision,
                    perceptualPrecision: preferences.perceptualPrecision,
                    layout: prefireSnapshot.isScreen ? .device(config: prefireSnapshot.device.imageConfig) : .sizeThatFits,
                    traits: prefireSnapshot.traits
                )
            ),
            record: preferences.record,
            file: fileForSnapshots,
            testName: prefireSnapshot.name,
        ) {
            Issue.record(Comment(rawValue: failure), sourceLocation: sourceLocation)
        }

        #if canImport(AccessibilitySnapshot)
        let vc = UIHostingController(rootView: previewView)
        vc.view.frame = UIScreen.main.bounds

        if let failure = verifySnapshot(
            matching: vc,
            as: .wait(for: preferences.delay, on: .accessibilityImage(showActivationPoints: .always)),
            record: preferences.record,
            file: fileForSnapshots,
            testName: prefireSnapshot.name + ".accessibility",
        ) {
            Issue.record(Comment(rawValue: failure), sourceLocation: sourceLocation)
        }
        #endif
    }

    /// Check environments to avoid problems with snapshots on different devices or OS.
    func checkEnvironments() {
        if let simulatorDevice, let deviceModel = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            guard deviceModel.contains(simulatorDevice) else {
                fatalError("Switch to using \(simulatorDevice) for these tests. (You are using \(deviceModel))")
            }
        }

        if let requiredOSVersion {
            let osVersion = ProcessInfo().operatingSystemVersion
            guard osVersion.majorVersion == requiredOSVersion else {
                fatalError("Switch to iOS \(requiredOSVersion) for these tests. (You are using \(osVersion))")
            }
        }
    }
}

extension DeviceConfig {
    var imageConfig: ViewImageConfig { ViewImageConfig(safeArea: safeArea, size: size, traits: traits) }
}

extension ViewImageConfig {
    var deviceConfig: DeviceConfig { DeviceConfig(safeArea: safeArea, size: size, traits: traits) }
}

extension PreviewDevice {
    func snapshotDevice() -> ViewImageConfig? {
        switch rawValue {
        case "iPhone 16 Pro Max", "iPhone 15 Pro Max", "iPhone 14 Pro Max", "iPhone 13 Pro Max", "iPhone 12 Pro Max":
            return .iPhone13ProMax
        case "iPhone 16 Pro", "iPhone 15 Pro", "iPhone 14 Pro", "iPhone 13 Pro", "iPhone 12 Pro":
            return .iPhone13Pro
        case "iPhone 16", "iPhone 15", "iPhone 14", "iPhone 13", "iPhone 12", "iPhone 11", "iPhone 10", "iPhone X":
            return .iPhoneX
        case "iPhone 6", "iPhone 6s", "iPhone 7", "iPhone 8", "iPhone SE (2nd generation)", "iPhone SE (3rd generation)":
            return .iPhone8
        case "iPhone 6 Plus", "iPhone 6s Plus", "iPhone 8 Plus":
            return .iPhone8Plus
        case "iPhone SE (1st generation)":
            return .iPhoneSe
        case "iPad":
            return .iPad10_2
        case "iPad Mini":
            return .iPadMini
        case "iPad Pro 11":
            return .iPadPro11
        case "iPad Pro 12.9":
            return .iPadPro12_9
        default: return nil
        }
    }

    func snapshotDevice() -> DeviceConfig? {
        (self.snapshotDevice())?.deviceConfig
    }
}

