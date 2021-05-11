//
//  AppDelegate.swift
//  RightForce
//
//  Created by Jed Fox on 5/11/21.
//

import Cocoa
import SwiftUI

struct State: Codable {
  var mouseDownTime: TimeInterval?
  var currentEvent: ClickEvent?
  var history: [ClickEvent] = []
  var isUp = false

  struct ClickEvent: Codable {
    let event: Event
    var pressures: [Pressure] = []
    struct Pressure: Codable {
      let dt: TimeInterval
      let pressure: Float
      let stage: Int
    }
    enum Event: Int, Codable {
      case primary
      case secondary
    }
  }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  var window: NSWindow!

  var state = State()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Create the SwiftUI view that provides the window contents.
    let contentView = ContentView()

    // Create the window and set the content view.
    window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.center()
    window.setFrameAutosaveName("Main Window")
    window.contentView = NSHostingView(rootView: contentView)
    window.makeKeyAndOrderFront(nil)


    if let eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .listenOnly,
      eventsOfInterest: .all,
      callback: { proxy, type, cgEvent, state in
        if let event = NSEvent(cgEvent: cgEvent),
           let state = state?.assumingMemoryBound(to: State.self) {
          if event.type == .leftMouseDown {
            state.pointee.isUp = false
            state.pointee.mouseDownTime = event.timestamp
            state.pointee.currentEvent = .init(event: .primary)
          } else if event.type == .pressure {
            state.pointee.currentEvent!.pressures.append(
              State.ClickEvent.Pressure(
                dt: state.pointee.mouseDownTime!.distance(to: event.timestamp),
                pressure: event.pressure,
                stage: event.stage
              )
            )
            if state.pointee.isUp {
              state.pointee.history.append(state.pointee.currentEvent!)
              state.pointee.currentEvent = nil
              state.pointee.mouseDownTime = nil
            }
          } else if event.type == .leftMouseUp {
            state.pointee.isUp = true
          }
        }
        return Unmanaged.passUnretained(cgEvent)
      }, userInfo: &state) {
      RunLoop.current.add(eventTap, forMode: .common)
      CGEvent.tapEnable(tap: eventTap, enable: true)
    }
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
    let result = try! JSONEncoder().encode(state.history)
    try! result.write(to: URL(fileURLWithPath: "/Users/jed/Downloads/clicks.json"))
  }


}

