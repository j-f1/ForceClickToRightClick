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

  lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

  var eventTap: CFMachPort?

  func applicationDidFinishLaunching(_: Notification) {
    if AXIsProcessTrusted() {
      createEventTap()
      enableEventTap()
      initStatusItem()
    } else {
      if let controller = NSStoryboard.main?.instantiateController(withIdentifier: "WelcomeWindow") as? NSWindowController {
        controller.showWindow(self)
        if let vc = controller.contentViewController as? WelcomeViewController {
          vc.onComplete = { [weak self] in
            self?.createEventTap()
            self?.enableEventTap()
            self?.initStatusItem()
          }
        }
      }
    }
  }

  func initStatusItem() {
    statusItem.menu = NSMenu(buildMenu)
    statusItem.button?.image = NSImage(named: "Menu Bar Icon")
  }

  @MenuBuilder func buildMenu() -> [NSMenuItem] {
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String]!
    MenuItem("About \(appName)…")
      .onSelect {
        NSWorkspace.shared.open(URL(string: "https://github.com/j-f1/ForceClickToRightClick")!)
      }
    MenuItem("Send Feedback…")
      .onSelect {
        NSWorkspace.shared.open(URL(string: "https://github.com/j-f1/ForceClickToRightClick/blob/main/contact.md")!)
      }
    SeparatorItem()
    MenuItem("Open at Login")
      .state(LaunchAtLogin.isEnabled ? .on : .off)
      .onSelect {
        LaunchAtLogin.isEnabled.toggle()
        self.statusItem.menu?.replaceItems(with: self.buildMenu)
      }
    MenuItem("Accessibility Preferences…")
      .onSelect {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
      }
    SeparatorItem()
    MenuItem("Quit \(appName)")
      .shortcut("q")
      .onSelect { NSApp.terminate(nil) }
  }

  func createEventTap() {
    eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: [.leftMouseDown, .leftMouseUp, .pressure, .leftMouseDragged],
      callback: { proxy, _, cgEvent, ctx in
        if cgEvent.type == .tapDisabledByTimeout || cgEvent.type == .tapDisabledByUserInput {
          (NSApp.delegate as? AppDelegate)?.enableEventTap()
          return .passUnretained(cgEvent)
        }
        if let event = NSEvent(cgEvent: cgEvent),
           let wrapper = ctx?.load(as: Wrapper.self) {
          if let newEvent = handle(event: event, cgEvent: cgEvent, wrapper: wrapper, proxy: proxy) {
            /// Quoting from https://developer.apple.com/documentation/coregraphics/cgeventtapcallback?language=swift
            /// Your callback function should return one of the following:
            /// - The (possibly modified) event that is passed in. This event is passed back to the event system.
            ///   - [we call passUnretained here since the event system is retaining the original event]
            /// - A newly-constructed event. After the new event has been passed back to the event system, the new event will be released along with the original event.
            ///   - [we call passRetained here because the event system will eventually release the event we return]
            /// - `NULL` if the event passed in is to be deleted.
            if newEvent == cgEvent {
              return .passUnretained(cgEvent)
            } else {
              return .passRetained(newEvent)
            }
          } else {
            return nil
          }
        } else {
          print("Unexpected failure to construct state or NSEvent")
          return .passUnretained(cgEvent)
        }
      }, userInfo: &state)
  }
  func enableEventTap() {
    if let eventTap = eventTap {
      RunLoop.current.add(eventTap, forMode: .common)
      CGEvent.tapEnable(tap: eventTap, enable: true)
    }
  }
}

