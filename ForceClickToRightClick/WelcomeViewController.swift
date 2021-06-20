//
//  WelcomeViewController.swift
//  ForceClickToRightClick
//
//  Created by Jed Fox on 6/19/21.
//

import Cocoa

let HasSentPermissionPrompt = "HasSentPermissionPrompt"

class WelcomeViewController: NSViewController, NSWindowDelegate {

  @IBOutlet weak var button: NSButton!
  @IBOutlet weak var instructions: NSTextField!

  var onComplete: (() -> ())?

  override func viewDidLoad() {
    super.viewDidLoad()
    updateText()
  }

  override func viewDidAppear() {
    NSApp.activate(ignoringOtherApps: true)
    view.window?.makeKeyAndOrderFront(nil)
    view.window?.delegate = self
  }

  @IBAction func requestAccess(_ sender: NSButton) {
    if let tap = CGEvent.tapCreate(tap: .cgAnnotatedSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: [.leftMouseDown], callback: { _,_,_,_  in nil }, userInfo: nil) {
      CFMachPortInvalidate(tap)
    }
    if UserDefaults.standard.bool(forKey: HasSentPermissionPrompt) {
      NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    } else {
      UserDefaults.standard.set(true, forKey: HasSentPermissionPrompt)
    }
  }

  func updateText() {
    if AXIsProcessTrusted() {
      onComplete?()
      button.isEnabled = false
      instructions.stringValue = "Access granted! Close this window to begin using ForceClickToRightClick."
      instructions.textColor = NSColor.systemGreen
      return
    }
    if UserDefaults.standard.bool(forKey: HasSentPermissionPrompt) {
      button.title = "Open System Preferences"
      instructions.stringValue = "Then check the “ForceClickToRightClick” checkbox in Security & Privacy \u{2192} Privacy \u{2192} Accessibility to grant access."
    } else {
      button.title = "Request Access"
      instructions.stringValue = "Then click “Open System Preferences” and check the “ForceClickToRightClick” checkbox in Security & Privacy \u{2192} Privacy \u{2192} Accessibility to grant access."
    }
  }

  func windowDidBecomeKey(_: Notification) {
    updateText()
  }
}