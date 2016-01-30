//
//  AppDelegate.swift
//  AudioSwitcher
//
//  Created by Case Wright on 1/29/16.
//  Copyright © 2016 Case Wright. All rights reserved.
//

import Cocoa
import CoreAudio
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    var previousOutputDevices: [EZAudioDevice]!
    let menu: NSMenu = NSMenu()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusItem.button?.title = "🔊"
        statusItem.menu = menu
        addMenuItems()
        let thread = NSThread(target: self, selector: "backgroundLoop", object: nil)
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func switchAudioDevice(sender: AnyObject) {
        let device = AudioDeviceID((sender.representedObject as! EZAudioDevice).deviceID)
        setDevice(device)
        refreshMenu()
    }
    
    func backgroundLoop() {
        while true {
            sleep(5)
            if(checkForChanges()) {
                dispatch_async(dispatch_get_main_queue()) {
                    self.refreshMenu()
                }
            }
        }
    }
    
    func refreshMenu() {
        self.menu.removeAllItems()
        self.addMenuItems()
    }
    
    func checkForChanges() -> Bool {
        let outputDevices: [EZAudioDevice] = EZAudioDevice.outputDevices() as! [EZAudioDevice]
        
        if(self.previousOutputDevices == nil) {
            self.previousOutputDevices = outputDevices
            return false
        }
        
        return previousOutputDevices == outputDevices
    }
    
    func addMenuItems() -> Void {
        let outputDevices: [EZAudioDevice] = EZAudioDevice.outputDevices() as! [EZAudioDevice]
        let currentDeviceMenuItem = NSMenuItem(title: "Current: \(EZAudioDevice.currentOutputDevice().name)", action: nil, keyEquivalent: "")
        self.menu.addItem(currentDeviceMenuItem)
        
        for device in outputDevices {
            let menuItem = NSMenuItem(title: device.name, action: Selector("switchAudioDevice:"), keyEquivalent: "")
            menuItem.representedObject = device
            self.menu.addItem(menuItem)
        }
        
        let quitBtn: NSMenuItem = NSMenuItem(title: "Quit", action: Selector("quit"), keyEquivalent: "Q")
        self.menu.addItem(quitBtn)
    }
    
    func quit() {
        exit(0)
    }
}
