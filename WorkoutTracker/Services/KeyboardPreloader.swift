import UIKit

@MainActor
enum KeyboardPreloader {
    private static var hasPreloaded = false

    static func preload() {
        guard !hasPreloaded else { return }
        hasPreloaded = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))

            for _ in 0..<5 {
                if preloadUsingAvailableWindow() {
                    return
                }
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    @discardableResult
    private static func preloadUsingAvailableWindow() -> Bool {
        guard let window = activeWindow() else { return false }

        let dummyField = UITextField(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        dummyField.alpha = 0.01
        dummyField.keyboardType = .decimalPad
        dummyField.isAccessibilityElement = false
        window.addSubview(dummyField)
        dummyField.becomeFirstResponder()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            dummyField.resignFirstResponder()
            dummyField.removeFromSuperview()
        }

        return true
    }

    private static func activeWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ??
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first
    }
}
