//
//  AppDelegate.swift
//  RightForce
//
//  Created by Jed Fox on 5/11/21.
//

import Cocoa
import SwiftUI

struct State {
  var mouseDownLoc: CGPoint
  var isRight = false
  var mouseMoves: [CGPoint] = []
}

extension UnsafeMutablePointer where Pointee == State? {
  var mouseDownLoc: CGPoint {
    get { pointee!.mouseDownLoc }
    set { pointee = State(mouseDownLoc: newValue) }
  }
  var mouseMoves: [CGPoint] {
    get { pointee!.mouseMoves }
    set { pointee!.mouseMoves = newValue }
  }
  var isRight: Bool {
    get { pointee?.isRight ?? false }
    set { pointee!.isRight = newValue }
  }

  func replay(into proxy: CGEventTapProxy, from event: CGEvent) {
    print("replay")
    let source = CGEventSource(event: event)
    CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: mouseDownLoc, mouseButton: .left)?.tapPostEvent(proxy)
    mouseMoves.forEach {
      CGEvent(
        mouseEventSource: source,
        mouseType: .leftMouseDragged,
        mouseCursorPosition: $0,
        mouseButton: .left
      )?.tapPostEvent(proxy)
    }
    pointee = nil
  }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  var window: NSWindow!

  var state: State?

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


    let eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: [.leftMouseDown, .leftMouseUp, .pressure, .leftMouseDragged],
      callback: { proxy, type, cgEvent, state in
//        print(cgEvent)
        if let event = NSEvent(cgEvent: cgEvent),
           var state = state?.assumingMemoryBound(to: State?.self) {
          if event.type == .leftMouseDown {

            state.pointee = State(mouseDownLoc: cgEvent.location)
            return nil
          } else if state.pointee != nil {
            if event.type == .leftMouseUp {
//              print("replaying: mouse up")
              if state.isRight {
                return Unmanaged.passRetained(
                  CGEvent(
                    mouseEventSource: CGEventSource(event: cgEvent),
                    mouseType: .rightMouseUp,
                    mouseCursorPosition: cgEvent.location,
                    mouseButton: .right
                  )!
                )
              } else {
                state.replay(into: proxy, from: cgEvent)
                return Unmanaged.passUnretained(cgEvent)
              }
            } else if event.type == .leftMouseDragged {
              let distanceSq = pow(cgEvent.location.x - state.mouseDownLoc.x, 2) + pow(cgEvent.location.y - state.mouseDownLoc.y, 2)
              if state.isRight {
                return Unmanaged.passRetained(
                  CGEvent(
                    mouseEventSource: CGEventSource(event: cgEvent),
                    mouseType: .rightMouseDragged,
                    mouseCursorPosition: cgEvent.location,
                    mouseButton: .right
                  )!
                )
              } else if distanceSq >= pow(8, 2) {
//                print("replaying: out of bounds")
                state.replay(into: proxy, from: cgEvent)
                return Unmanaged.passUnretained(cgEvent)
              } else {
//                print("move: in bounds")
                state.mouseMoves.append(cgEvent.location)
                return Unmanaged.passRetained(
                  CGEvent(
                    mouseEventSource: CGEventSource(event: cgEvent),
                    mouseType: .mouseMoved,
                    mouseCursorPosition: cgEvent.location,
                    mouseButton: .left
                  )!
                )
              }
            } else if event.type == .pressure {
              if event.stage == 2 && !state.isRight {
                print("right down!")
                state.isRight = true
                return Unmanaged.passRetained(
                  CGEvent(
                    mouseEventSource: CGEventSource(event: cgEvent),
                    mouseType: .rightMouseDown,
                    mouseCursorPosition: state.mouseDownLoc,
                    mouseButton: .right
                  )!
                )
              } else {
                return nil
              }
            } else {
              return Unmanaged.passUnretained(cgEvent)
            }
          } else {
            return Unmanaged.passUnretained(cgEvent)
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

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }


}

