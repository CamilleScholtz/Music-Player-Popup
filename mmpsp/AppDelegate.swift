//
//  AppDelegate.swift
//  mmpsp
//
//  Created by Camille Scholtz on 10/01/2021.
//

import SwiftUI

@main struct MusicPlayerPopupApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var player = Player()

    private var statusItemStub: NSStatusItem!
    private var statusItem: NSStatusItem!
    var popover = NSPopover()

    func applicationDidFinishLaunching(_: Notification) {
        configureStatusItem()
        configurePopover()
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(buttonAction(_:))
        statusItem.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])

        statusItem.button?.postsFrameChangedNotifications = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayerDidChange(_:)),
            name: Notification.Name("PlayerDidChangeNotification"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFrameChanged(_:)),
            name: NSView.frameDidChangeNotification,
            object: statusItem.button
        )

        setStatusItemTitle()
    }

    private func configurePopover() {
        popover.contentViewController = NSViewController()
        popover.contentViewController!.view = NSHostingView(
            rootView: PopoverView()
                .environmentObject(player)
        )
        popover.behavior = .semitransient
    }

    private func setStatusItemTitle() {
        statusItem?.button?.title = player.song.description
    }

    private func togglePopover(_ sender: NSStatusBarButton?) {
        guard let sender = sender else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover(sender)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showPopover(_ sender: NSStatusBarButton?) {
        guard let sender = sender else {
            return
        }

        let positioningRect = NSRect(
            origin: NSPoint(x: sender.frame.origin.x + (sender.frame.width - 75), y: sender.frame.origin.y),
            size: sender.frame.size
        )

        if popover.isShown {
            popover.positioningRect = positioningRect

            // TODO: hack, some race issue or something
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.popover.positioningRect = positioningRect
            }
        } else {
            popover.show(
                relativeTo: positioningRect,
                of: sender,
                preferredEdge: .maxY
            )
        }
    }

    @objc private func handlePlayerDidChange(_: Notification) {
        setStatusItemTitle()
    }

    @objc func handleFrameChanged(_ notfication: Notification) {
        guard popover.isShown, let sender = notfication.object as? NSStatusBarButton else {
            return
        }

        showPopover(sender)
    }

    @objc func buttonAction(_ sender: NSStatusBarButton?) {
        guard let event = NSApp.currentEvent else {
            return
        }

        // TODO: `case .scrollWheel` doesn't work.
        switch event.type {
        case .rightMouseDown:
            player.pause(player.status.isPlaying!)
        default:
            togglePopover(sender)
        }
    }
}
