//
//  EventHandler.swift
//  ForceClickToRightClick
//
//  Created by Jed Fox on 6/19/21.
//

import Cocoa

class Wrapper {
  var state: State?

  class State {
    init(mouseDownEvent: CGEvent) {
      self.mouseDownEvent = mouseDownEvent
    }
    var mouseDownEvent: CGEvent
    var task: DispatchWorkItem!
    var isRight = false
    var mouseMoves: [CGPoint] = []

    func replay(into proxy: CGEventTapProxy, from event: CGEvent) {
//      print("replay")
      task.cancel()
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
    }
  }
}

func handle(event: NSEvent, cgEvent: CGEvent, wrapper: Wrapper, proxy: CGEventTapProxy) -> CGEvent? {
  if event.type == .leftMouseDown {
    let state = Wrapper.State(mouseDownEvent: cgEvent)
    state.task = DispatchWorkItem {
      state.replay(into: proxy, from: cgEvent)
      wrapper.state = nil
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: state.task)
    wrapper.state = state
    return nil
  } else if let state = wrapper.state {
    if event.type == .leftMouseUp {
      defer { wrapper.state = nil }
//      print("replaying: mouse up")
      if state.isRight {
        let copy = cgEvent.copy()!
        copy.type = .rightMouseUp
        copy.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.right.rawValue))
        return copy
      } else {
        state.replay(into: proxy, from: cgEvent)
        return cgEvent
      }
    } else if event.type == .leftMouseDragged {
      let distanceSq = pow(cgEvent.location.x - state.mouseDownEvent.location.x, 2) + pow(cgEvent.location.y - state.mouseDownEvent.location.y, 2)
      if state.isRight {
        let copy = cgEvent.copy()!
        copy.type = .rightMouseDragged
        copy.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.right.rawValue))
        return copy
      } else if distanceSq >= pow(8, 2) {
//        print("replaying: out of bounds")
        state.replay(into: proxy, from: cgEvent)
        return cgEvent
      } else {
//        print("move: in bounds")
        state.mouseMoves.append(cgEvent.location)
        let copy = cgEvent.copy()!
        copy.type = .mouseMoved
        return copy
      }
    } else if event.type == .pressure {
      if event.stage == 2 && !state.isRight {
//        print("right down!")
        state.isRight = true
        state.task.cancel()
        let copy = cgEvent.copy()!
        copy.type = .rightMouseDown
        copy.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.right.rawValue))
        return copy
      } else {
        return nil
      }
    } else {
      return cgEvent
    }
  } else {
    return cgEvent
  }
}
