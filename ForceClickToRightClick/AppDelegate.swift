//
//  AppDelegate.swift
//  ForceClickToRightClick
//
//  Created by Jed Fox on 5/11/21.
//

import Cocoa
import MenuBuilder
import LaunchAtLogin

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  var state = Wrapper()

  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

  func applicationDidFinishLaunching(_: Notification) {
    createEventTap()
    initStatusItem()
  }

  func initStatusItem() {
    statusItem.menu = NSMenu(buildMenu)
    statusItem.button?.image = NSImage(named: "Menu Bar Icon")
  }

  @MenuBuilder func buildMenu() -> [NSMenuItem] {
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String]!
    MenuItem("About \(appName)")
      .onSelect {
        NSWorkspace.shared.open(URL(string: "https://github.com/j-f1/ForceClickToRightClick")!)
      }
    MenuItem("Send Feedback…")
      .onSelect {
        NSWorkspace.shared.open(URL(string: "https://j-f1.github.io/ForceClickToRightClick/contact.html")!)
      }
    SeparatorItem()
    MenuItem("Launch At Login")
      .state(LaunchAtLogin.isEnabled ? .on : .off)
      .onSelect {
        LaunchAtLogin.isEnabled.toggle()
        self.statusItem.menu?.replaceItems(with: self.buildMenu)
      }
    SeparatorItem()
    MenuItem("Quit \(appName)")
      .shortcut("q")
      .onSelect { NSApp.terminate(nil) }
  }

  func createEventTap() {
    let eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: [.leftMouseDown, .leftMouseUp, .pressure, .leftMouseDragged],
      callback: { proxy, _, cgEvent, ctx in
//        print(cgEvent)
        if let event = NSEvent(cgEvent: cgEvent),
           let wrapper = ctx?.load(as: Wrapper.self) {
          if let newEvent = handle(event: event, cgEvent: cgEvent, wrapper: wrapper, proxy: proxy) {
            if newEvent == cgEvent {
              return .passUnretained(cgEvent)
            } else {
              return .passRetained(newEvent)
            }
          } else {
            return nil
          }
        } else {
          fatalError("Unexpected failure to construct state or NSEvent")
        }
      }, userInfo: &state)
    if let eventTap = eventTap {
      RunLoop.current.add(eventTap, forMode: .common)
      CGEvent.tapEnable(tap: eventTap, enable: true)
    }
  }
}

