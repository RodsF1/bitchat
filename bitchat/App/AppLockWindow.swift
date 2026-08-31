//
// AppLockWindow.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

#if os(iOS)
import SwiftUI
import UIKit

/// Hosts the app-lock gate in a dedicated `UIWindow` above the main window's
/// entire presentation stack.
///
/// The gate is also rendered as a ZStack sibling of `ContentView` (see
/// `BitchatApp`), which covers the cold-launch case with no flash. But a
/// `.sheet` / `.fullScreenCover` presented from `ContentView` is a UIKit modal
/// above the SwiftUI root, so the sibling cannot cover a modal that was open
/// when the app went to the background and re-locked — settings (relay names,
/// the panic-wipe button), the QR sheet, location channels, etc. would sit on
/// top of the lock on return. A separate window at `.alert + 1` is the only
/// surface guaranteed to sit above that modal layer.
///
/// Driven from SwiftUI by `AppLockModel.isLocked` so the model stays UIKit-free
/// and testable; the window is created on the false→true transition (the
/// background re-lock, the only time a modal can already be open) and torn down
/// on unlock. Mirrors the window-lifecycle approach of `PrivacyScreen`.
@MainActor
final class AppLockWindow {
    static let shared = AppLockWindow()

    private var window: UIWindow?

    private init() {}

    /// Show or hide the lock window. `model` and `appTheme` are only read when
    /// a window is created.
    func setLocked(_ isLocked: Bool, model: AppLockModel, appTheme: AppTheme) {
        if isLocked {
            guard window == nil, let scene = Self.activeWindowScene() else { return }
            let host = UIHostingController(
                rootView: AppLockScreen(model: model)
                    .environment(\.appTheme, appTheme)
            )
            let window = UIWindow(windowScene: scene)
            // Above the main window's presented sheets/covers (which live at
            // the normal level) and above system alerts.
            window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue + 1)
            window.rootViewController = host
            window.makeKeyAndVisible()
            self.window = window
        } else {
            window?.isHidden = true
            window?.rootViewController = nil
            window = nil
        }
    }

    private static func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }
}
#endif
