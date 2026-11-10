import SwiftUI

/// The menu-bar icon and its popover, in AppKit rather than a SwiftUI
/// MenuBarExtra: MenuBarExtra's panel grows with its content but never shrinks
/// back, so after Parametric → Graphic (or closing Diagnostics) the controls
/// floated in a band of empty glass. NSPopover follows the hosting
/// controller's preferred size in both directions.
@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let controller: EQController
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()

    init(controller: EQController) {
        self.controller = controller
        super.init()
        popover.behavior = .transient
        popover.delegate = self
        guard let button = statusItem.button else {
            fatalError("NSStatusItem was created without a button")
        }
        // White template glyph: speaker protected by a small padlock badge.
        // Template rendering lets macOS adapt it to light/dark menu bars.
        let speaker = NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: "Sunrise Limiter")!
        let lock = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil)!
        let mark = NSImage(size: NSSize(width: 22, height: 19))
        mark.lockFocus()
        speaker.draw(in: NSRect(x: 0, y: 1, width: 17, height: 17))
        lock.draw(in: NSRect(x: 13, y: 0, width: 9, height: 10))
        mark.unlockFocus()
        mark.isTemplate = true
        button.image = mark
        button.image?.isTemplate = true
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        // AppKit status items do not create a context menu automatically.
        // Explicitly request an action for both mouse buttons so right-click
        // can show a native NSMenu while left-click continues to open the panel.
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked(_ button: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu(for: button)
        } else {
            togglePopover(button)
        }
    }

    private func showContextMenu(for button: NSStatusBarButton) {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Open Sunrise Limiter", action: #selector(openFromMenu), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = controller.launchAtLogin ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Sunrise Limiter", action: #selector(quitFromMenu), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        // Anchor the standard macOS menu to the status-bar icon.
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
    }

    @objc private func openFromMenu() {
        guard let button = statusItem.button else { return }
        togglePopover(button)
    }

    @objc private func toggleLaunchAtLogin() {
        controller.launchAtLogin.toggle()
    }

    @objc private func quitFromMenu() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func togglePopover(_ button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        // A fresh view per opening, released on close: the popover's own
        // onAppear/onDisappear (and the spectrum's) are what start and stop
        // the display timers, and a view that outlives the popover never
        // disappears.
        let hostingController = NSHostingController(rootView: EQPopoverView(controller: controller))
        hostingController.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hostingController
        // A menu-bar click doesn't activate the app, and without that the
        // popover never becomes key, so its text fields can't be typed into.
        NSApplication.shared.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        button.highlight(true)
    }

    func popoverDidClose(_ notification: Notification) {
        statusItem.button?.highlight(false)
        popover.contentViewController = nil
    }
}
