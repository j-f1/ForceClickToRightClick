//
//  CGEventExtension.swift
//  ForceClickToRightClick
//
//  Created by Jed Fox on 5/11/21.
//

import Foundation

extension CGEventType {
  static var pressure = CGEventType(rawValue: 29)!

  fileprivate var mask: CGEventMask { 1 << rawValue }

  var description: String {
    switch self {
    case .null: return "CGEventType.null"
    case .leftMouseDown: return "CGEventType.leftMouseDown"
    case .leftMouseUp: return "CGEventType.leftMouseUp"
    case .rightMouseDown: return "CGEventType.rightMouseDown"
    case .rightMouseUp: return "CGEventType.rightMouseUp"
    case .mouseMoved: return "CGEventType.mouseMoved"
    case .leftMouseDragged: return "CGEventType.leftMouseDragged"
    case .rightMouseDragged: return "CGEventType.rightMouseDragged"
    case .keyDown: return "CGEventType.keyDown"
    case .keyUp: return "CGEventType.keyUp"
    case .flagsChanged: return "CGEventType.flagsChanged"
    case .scrollWheel: return "CGEventType.scrollWheel"
    case .tabletPointer: return "CGEventType.tabletPointer"
    case .tabletProximity: return "CGEventType.tabletProximity"
    case .otherMouseDown: return "CGEventType.otherMouseDown"
    case .otherMouseUp: return "CGEventType.otherMouseUp"
    case .otherMouseDragged: return "CGEventType.otherMouseDragged"
    case .tapDisabledByTimeout: return "CGEventType.tapDisabledByTimeout"
    case .tapDisabledByUserInput: return "CGEventType.tapDisabledByUserInput"
    @unknown default: return "CGEventType(\(rawValue))"
    }
  }
}

extension CGEventMask: OptionSet {
  public static let all: CGEventMask = ~0

  public var rawValue: Self { self }

  public typealias Element = CGEventType

  public init() { self = 0 }

  public init(rawValue: Self) {
    self = rawValue
  }

  public func contains(_ member: CGEventType) -> Bool {
    (self & member.mask) != 0
  }

  public mutating func insert(_ newMember: __owned CGEventType) -> (inserted: Bool, memberAfterInsert: CGEventType) {
    let result = (inserted: contains(newMember), memberAfterInsert: newMember)
    self |= newMember.mask
    return result
  }

  public mutating func remove(_ member: CGEventType) -> CGEventType? {
    if contains(member) {
      self ^= member.mask
      return member
    } else {
      return nil
    }
  }

  public mutating func update(with newMember: __owned CGEventType) -> CGEventType? {
    let result = insert(newMember)
    return result.inserted ? nil : newMember

  }
}
