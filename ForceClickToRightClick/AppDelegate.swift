//
//  AppDelegate.swift
//  ForceClickToRightClick
//
//  Created by Jed Fox on 5/11/21.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  var state: State?

  func applicationDidFinishLaunching(_: Notification) {
    let eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: [.leftMouseDown, .leftMouseUp, .pressure, .leftMouseDragged],
      callback: { proxy, type, cgEvent, state in
//        print(cgEvent)
        if let event = NSEvent(cgEvent: cgEvent),
           let state = state?.assumingMemoryBound(to: State?.self) {
          return handle(event: event, cgEvent: cgEvent, state: state, proxy: proxy)
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

