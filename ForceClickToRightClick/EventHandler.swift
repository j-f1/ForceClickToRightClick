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

    func replay(into proxy: CGEventTapProxy, from event: CGEvent, isRight: Bool) {
//      print("replay")
      task.cancel()
      let source = CGEventSource(event: event)
      let mouseDownEvent = mouseDownEvent.copy()!
      if isRight {
        mouseDownEvent.type = .rightMouseDown
        mouseDownEvent.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.right.rawValue))
      }
      mouseDownEvent.tapPostEvent(proxy)
      mouseMoves.forEach {
        CGEvent(
          mouseEventSource: source,
          mouseType: isRight ? .rightMouseDragged : .leftMouseDragged,
          mouseCursorPosition: $0,
          mouseButton: isRight ? .right : .left
        )?.tapPostEvent(proxy)
      }
    }
  }
}

extension CGEvent {
  fileprivate func switchToRight() -> CGEvent? {
    guard let copy = self.copy() else { return nil }
    switch copy.type {
    case .leftMouseDown: copy.type = .rightMouseDown
    case .leftMouseDragged: copy.type = .rightMouseDragged
    case .leftMouseUp: copy.type = .rightMouseUp
    default: return nil
    }
    copy.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.right.rawValue))
    return copy
  }
}

func handle(event: NSEvent, cgEvent: CGEvent, wrapper: Wrapper, proxy: CGEventTapProxy) -> CGEvent? {
  if event.type == .leftMouseDown {
//    print("mouse down")
    let state = Wrapper.State(mouseDownEvent: cgEvent)
    state.task = DispatchWorkItem {
      state.replay(into: proxy, from: cgEvent, isRight: false)
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
        return cgEvent.switchToRight()!
      } else {
        state.replay(into: proxy, from: cgEvent, isRight: false)
        return cgEvent
      }
    } else if event.type == .leftMouseDragged {
      let distanceSq = pow(cgEvent.location.x - state.mouseDownEvent.location.x, 2) + pow(cgEvent.location.y - state.mouseDownEvent.location.y, 2)
      if state.isRight {
        return cgEvent.switchToRight()!
      } else if distanceSq >= pow(8, 2) {
//        print("replaying: out of bounds")
        state.replay(into: proxy, from: cgEvent, isRight: false)
        wrapper.state = nil
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
        state.replay(into: proxy, from: cgEvent, isRight: true)
        return nil
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
