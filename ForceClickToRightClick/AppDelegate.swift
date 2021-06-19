//
//  AppDelegate.swift
//  ForceClickToRightClick
//
//  Created by Jed Fox on 5/11/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  var state = Wrapper()

  func applicationDidFinishLaunching(_: Notification) {
    let eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: [.leftMouseDown, .leftMouseUp, .pressure, .leftMouseDragged],
      callback: { proxy, _, cgEvent, ctx in
//        print(cgEvent)
        if let event = NSEvent(cgEvent: cgEvent),
           let wrapper = ctx?.load(as: Wrapper.self) {
          return handle(event: event, cgEvent: cgEvent, wrapper: wrapper, proxy: proxy)
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

