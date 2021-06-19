//
//  AppDelegate.swift
//  ForceClickToRightClick
//
//  Created by Jed Fox on 5/11/21.
//

import Cocoa
import SwiftUI

struct State {
  var mouseDownEvent: CGEvent
  var task: DispatchWorkItem
  var isRight = false
  var mouseMoves: [CGPoint] = []
}

extension UnsafeMutablePointer where Pointee == State? {
  var mouseDownEvent: CGEvent {
    get { pointee!.mouseDownEvent }
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
//    print("replay")
    pointee!.task.cancel()
    let source = CGEventSource(event: event)
    mouseDownEvent.copy()!.tapPostEvent(proxy)
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

//  var window: NSWindow!

  var state: State?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
//    // Create the SwiftUI view that provides the window contents.
//    let contentView = ContentView()
//
//    // Create the window and set the content view.
//    window = NSWindow(
//      contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
//      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
//      backing: .buffered, defer: false)
//    window.isReleasedWhenClosed = false
//    window.center()
//    window.setFrameAutosaveName("Main Window")
//    window.contentView = NSHostingView(rootView: contentView)
//    window.makeKeyAndOrderFront(nil)


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
            state.pointee = State(
              mouseDownEvent: cgEvent,
              task: DispatchWorkItem {
                state.replay(into: proxy, from: cgEvent)
              }
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: state.pointee!.task)
            return nil
          } else if state.pointee != nil {
            if event.type == .leftMouseUp {
//              print("replaying: mouse up")
              if state.isRight {
                let copy = cgEvent.copy()!
                copy.type = .rightMouseUp
                copy.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.right.rawValue))
                return Unmanaged.passRetained(copy)
              } else {
                state.replay(into: proxy, from: cgEvent)
                return Unmanaged.passUnretained(cgEvent)
              }
            } else if event.type == .leftMouseDragged {
              let distanceSq = pow(cgEvent.location.x - state.mouseDownEvent.location.x, 2) + pow(cgEvent.location.y - state.mouseDownEvent.location.y, 2)
              if state.isRight {
                let copy = cgEvent.copy()!
                copy.type = .rightMouseDragged
                copy.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.right.rawValue))
                return Unmanaged.passRetained(copy)
              } else if distanceSq >= pow(8, 2) {
//                print("replaying: out of bounds")
                state.replay(into: proxy, from: cgEvent)
                return Unmanaged.passUnretained(cgEvent)
              } else {
//                print("move: in bounds")
                state.mouseMoves.append(cgEvent.location)
                let copy = cgEvent.copy()!
                copy.type = .mouseMoved
                return Unmanaged.passRetained(copy)
              }
            } else if event.type == .pressure {
              if event.stage == 2 && !state.isRight {
//                print("right down!")
                state.isRight = true
                state.pointee!.task.cancel()
                let copy = cgEvent.copy()!
                copy.type = .rightMouseDown
                copy.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.right.rawValue))
                return Unmanaged.passRetained(copy)
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

