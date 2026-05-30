import AppKit
import SwiftUI

final class OverlayPanel: NSPanel {
    var handleOverlayKeyEvent: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown,
           handleOverlayKeyEvent?(event) == true {
            return
        }
        super.sendEvent(event)
    }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

final class OverlayWindowController {
    struct Dependencies {
        let shouldStageAsAccessory: () -> Bool
        let isSettingsVisible: () -> Bool
        let settingsWindow: () -> NSWindow?
        let canHideOverlay: () -> Bool
        let currentOverlayLevel: () -> NSWindow.Level
        let overlayLevel: (_ initialQuickSearchSource: String?) -> NSWindow.Level
        let makeContentView: (_ initialQuickSearchSource: String?) -> NSView
        let handleOverlayKeyEvent: (NSEvent) -> Bool
        let installOverlayKeyMonitor: () -> Void
        let removeOverlayKeyMonitor: () -> Void
        let removeQuickSearchMouseMonitor: () -> Void
        let detachSettingsWindow: (NSWindow) -> Void
        let prepareSettingsWindow: (NSWindow) -> Void
        let refreshChromeState: (_ activate: Bool, _ avoidSpaceSwitch: Bool) -> Void
        let onWillHide: () -> Void
        let onDidHide: () -> Void
        let onDidShow: () -> Void
    }

    private struct OverlayPlacementContext {
        let screen: NSScreen
        let frame: NSRect
    }

    private struct ForeignWindowFrame {
        let owner: String
        let frame: NSRect
    }

    private let dependencies: Dependencies

    private(set) var window: NSWindow?
    private(set) var generation = 0
    var avoidsSpaceSwitch = false

    var isVisible: Bool {
        window?.isVisible == true
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func toggle(preferredScreen: NSScreen?) {
        if window?.isVisible == true {
            hide(force: true)
        } else {
            show(preferredScreen: preferredScreen)
        }
    }

    func showOrFocus(preferredScreen: NSScreen? = nil) {
        let placement = overlayPlacementContextForNextOverlay(preferredScreen: preferredScreen)
        let shouldAvoidSpaceSwitch = placement.map { hasFullscreenWindowOnScreen($0.screen) } ?? false
        if let window, window.isVisible {
            avoidsSpaceSwitch = shouldAvoidSpaceSwitch
            moveToCurrentPlacement(preferredScreen: preferredScreen)
            window.level = dependencies.currentOverlayLevel()
            dependencies.refreshChromeState(!shouldAvoidSpaceSwitch, shouldAvoidSpaceSwitch)
            orderFront(window)
            if let settingsWindow = dependencies.settingsWindow(), settingsWindow.isVisible {
                dependencies.prepareSettingsWindow(settingsWindow)
            }
            return
        }
        show(preferredScreen: preferredScreen)
    }

    func show(
        initialQuickSearchSource: String? = nil,
        preferredScreen: NSScreen? = nil,
        stagedForAllSpaces: Bool = false
    ) {
        guard let placement = overlayPlacementContextForNextOverlay(preferredScreen: preferredScreen) else { return }

        let shouldAvoidSpaceSwitch = hasFullscreenWindowOnScreen(placement.screen)
        let shouldStageAsAccessory = dependencies.shouldStageAsAccessory() || shouldAvoidSpaceSwitch

        if !stagedForAllSpaces && shouldStageAsAccessory {
            if NSApp.activationPolicy() != .accessory {
                NSApp.setActivationPolicy(.accessory)
            }
            if NSApp.isActive {
                NSApp.deactivate()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                self?.show(
                    initialQuickSearchSource: initialQuickSearchSource,
                    preferredScreen: placement.screen,
                    stagedForAllSpaces: true
                )
            }
            return
        }

        if window?.isVisible == true {
            hide(force: true)
        } else if let existingWindow = window {
            existingWindow.orderOut(nil)
            window = nil
        }
        avoidsSpaceSwitch = shouldAvoidSpaceSwitch

        let newWindow = makeOverlayWindow(
            on: placement.screen,
            initialQuickSearchSource: initialQuickSearchSource
        )
        generation &+= 1
        window = newWindow
        dependencies.installOverlayKeyMonitor()
        if shouldStageAsAccessory {
            if NSApp.isActive {
                NSApp.deactivate()
            }
            if NSApp.activationPolicy() != .accessory {
                NSApp.setActivationPolicy(.accessory)
            }
        }

        let targetLevel = dependencies.overlayLevel(initialQuickSearchSource)
        newWindow.setFrame(placement.frame, display: true)
        newWindow.level = targetLevel
        orderFront(newWindow)

        let placementFrame = placement.frame
        let finishForegroundClaim: () -> Void = { [weak self, weak newWindow] in
            guard let self, let newWindow, self.window === newWindow else { return }
            self.dependencies.refreshChromeState(!shouldAvoidSpaceSwitch, shouldAvoidSpaceSwitch)
            if newWindow.frame != placementFrame {
                newWindow.setFrame(placementFrame, display: true)
                self.orderFront(newWindow)
            }
            for delay in [0.2, 0.5] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak newWindow] in
                    guard let self, let newWindow, self.window === newWindow else { return }
                    guard newWindow.frame != placementFrame else { return }
                    newWindow.setFrame(placementFrame, display: true)
                    self.orderFront(newWindow)
                }
            }
            if let settingsWindow = self.dependencies.settingsWindow(), settingsWindow.isVisible {
                self.dependencies.prepareSettingsWindow(settingsWindow)
            }
            self.dependencies.onDidShow()
        }

        if !dependencies.isSettingsVisible() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: finishForegroundClaim)
        } else {
            finishForegroundClaim()
        }
    }

    func hide(force: Bool = false, discardWindow: Bool = false) {
        guard force || dependencies.canHideOverlay() else { return }
        generation &+= 1
        dependencies.onWillHide()
        if let settingsWindow = dependencies.settingsWindow(), settingsWindow.parent == window {
            dependencies.detachSettingsWindow(settingsWindow)
        }
        window?.orderOut(nil)
        dependencies.removeOverlayKeyMonitor()
        dependencies.removeQuickSearchMouseMonitor()
        avoidsSpaceSwitch = false
        dependencies.refreshChromeState(false, false)
        dependencies.onDidHide()
        if discardWindow {
            window = nil
        }
    }

    func screenUnderMouse() -> NSScreen? {
        overlayPlacementContextForNextOverlay(preferredScreen: nil)?.screen
    }

    func screenContainingCurrentPointer() -> NSScreen? {
        let mousePoint = NSEvent.mouseLocation
        return NSScreen.screens.first(where: {
            NSMouseInRect(mousePoint, $0.frame, false)
        })
    }

    private func moveToCurrentPlacement(preferredScreen: NSScreen?) {
        guard let window,
              let placement = overlayPlacementContextForNextOverlay(preferredScreen: preferredScreen),
              window.frame != placement.frame
        else { return }
        window.setFrame(placement.frame, display: true)
    }

    private func makeOverlayWindow(on screen: NSScreen, initialQuickSearchSource: String?) -> NSWindow {
        let panel = OverlayPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .transient,
            .ignoresCycle
        ]
        panel.isOpaque = false
        panel.backgroundColor = NSColor.black.withAlphaComponent(0.001)
        panel.hasShadow = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isReleasedWhenClosed = false
        panel.handleOverlayKeyEvent = dependencies.handleOverlayKeyEvent
        panel.contentView = dependencies.makeContentView(initialQuickSearchSource)
        return panel
    }

    private func orderFront(_ window: NSWindow) {
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func overlayPlacementContextForNextOverlay(preferredScreen: NSScreen?) -> OverlayPlacementContext? {
        if let screen = preferredScreen {
            return OverlayPlacementContext(screen: screen, frame: screen.frame)
        }
        guard let screen = screenContainingCurrentPointer() ?? NSScreen.main ?? NSScreen.screens.first else {
            return nil
        }
        return OverlayPlacementContext(screen: screen, frame: screen.frame)
    }

    private func hasFullscreenWindowOnScreen(_ screen: NSScreen) -> Bool {
        let screenFrame = screen.frame
        let windowFrames = foreignLayerZeroWindows(on: screenFrame)

        if windowFrames.contains(where: { isSingleFullscreenWindow($0.frame, on: screenFrame) }) {
            return true
        }

        return hasSplitViewFullscreenWindows(windowFrames, on: screenFrame)
    }

    private func foreignLayerZeroWindows(on screenFrame: NSRect) -> [ForeignWindowFrame] {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        return windows.compactMap { info in
            guard let owner = info[kCGWindowOwnerName as String] as? String,
                  owner != AppIdentity.displayName,
                  owner != "Window Server",
                  owner != "Dock",
                  owner != "loginwindow",
                  let layer = info[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let bounds = info[kCGWindowBounds as String] as? NSDictionary
            else { return nil }

            let frame = NSRect(
                x: cgWindowDimension(bounds, "X"),
                y: cgWindowDimension(bounds, "Y"),
                width: cgWindowDimension(bounds, "Width"),
                height: cgWindowDimension(bounds, "Height")
            )
            guard frame.intersects(screenFrame) else { return nil }
            return ForeignWindowFrame(owner: owner, frame: frame)
        }
    }

    private func isSingleFullscreenWindow(_ windowFrame: NSRect, on screenFrame: NSRect) -> Bool {
        let widthMatches = abs(windowFrame.width - screenFrame.width) <= 12
        let heightMatches = windowFrame.height >= screenFrame.height * 0.88
        let horizontallyAligned = abs(windowFrame.midX - screenFrame.midX) <= 12
        let verticallyAligned = abs(windowFrame.maxY - screenFrame.maxY) <= 32
        return widthMatches && heightMatches && horizontallyAligned && verticallyAligned
    }

    private func hasSplitViewFullscreenWindows(_ windows: [ForeignWindowFrame], on screenFrame: NSRect) -> Bool {
        let clippedWindows = windows.map {
            ForeignWindowFrame(owner: $0.owner, frame: $0.frame.intersection(screenFrame))
        }
        let tallWindows = clippedWindows
            .filter { window in
                let frame = window.frame
                return frame.height >= screenFrame.height * 0.86
                    && frame.width >= screenFrame.width * 0.20
                    && frame.width <= screenFrame.width * 0.86
                    && abs(frame.maxY - screenFrame.maxY) <= 32
            }
            .sorted { $0.frame.minX < $1.frame.minX }

        guard tallWindows.count >= 2 else { return false }

        for startIndex in tallWindows.indices {
            var union = tallWindows[startIndex].frame
            var lastMaxX = union.maxX

            for window in tallWindows.dropFirst(startIndex + 1) {
                let gap = window.frame.minX - lastMaxX
                if gap < -32 || gap > 48 {
                    break
                }
                union = union.union(window.frame)
                lastMaxX = max(lastMaxX, window.frame.maxX)

                let touchesLeft = abs(union.minX - screenFrame.minX) <= 32
                let touchesRight = abs(union.maxX - screenFrame.maxX) <= 32
                let coversWidth = union.width >= screenFrame.width * 0.92
                let coversHeight = union.height >= screenFrame.height * 0.86
                if touchesLeft && touchesRight && coversWidth && coversHeight {
                    return true
                }
            }
        }

        return false
    }

    private func cgWindowDimension(_ bounds: NSDictionary, _ key: String) -> CGFloat {
        if let value = bounds[key] as? CGFloat {
            return value
        }
        if let value = bounds[key] as? NSNumber {
            return CGFloat(truncating: value)
        }
        return 0
    }
}
