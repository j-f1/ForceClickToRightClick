//
//  WelcomeViewController.swift
//  ForceClickToRightClick
//
//  Created by Jed Fox on 6/19/21.
//

import Cocoa
import LaunchAtLogin

let HasSentPermissionPrompt = "HasSentPermissionPrompt"

class WelcomeViewController: NSViewController, NSWindowDelegate {

  @IBOutlet weak var button: NSButton!
  @IBOutlet weak var instructionsLabel: NSTextField!
  @IBOutlet weak var rationaleLabel: NSTextField!

  @IBOutlet weak var menuInstructions: NSView!
  @IBOutlet weak var launchAtLoginPref: NSView!

  @objc dynamic var launchAtLogin = LaunchAtLogin.kvo

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
      button.isHidden = true
      instructionsLabel.stringValue = "Access granted! Close this window to begin using ForceClickToRightClick."
      instructionsLabel.textColor = NSColor.systemGreen.blended(withFraction: 0.5, of: .labelColor)

      menuInstructions.isHidden = false
      launchAtLoginPref.isHidden = false
      rationaleLabel.isHidden = true
      return
    }
    if UserDefaults.standard.bool(forKey: HasSentPermissionPrompt) {
      button.title = "Open System Preferences"
      instructionsLabel.stringValue = """
      1. Click the “Open System Preferences” button above
      2. Click the lock at the bottom left to unlock the settings if necessary
      3. Scroll the list on the right until you see “ForceClickToRightClick”
      4. Check the checkbox next to “ForceClickToRightClick”
      5. Close System Preferences and return to this window
      """
    } else {
      button.title = "Request Access"
      instructionsLabel.stringValue = """
      1. Click “Request Access” above
      1. Click the “Open System Preferences” button in the dialog that appears
      2. Click the lock at the bottom left to unlock the settings if necessary
      3. Scroll the list on the right until you see “ForceClickToRightClick”
      4. Check the checkbox next to “ForceClickToRightClick”
      5. Close System Preferences and return to this window
      """
    }
  }

  func windowDidBecomeKey(_: Notification) {
    updateText()
  }
}
