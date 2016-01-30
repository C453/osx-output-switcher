//
//  AppDelegate.swift
//  AudioSwitcher
//
//  Created by Case Wright on 1/29/16.
//  Copyright © 2016 Case Wright. All rights reserved.
//

import Cocoa
import CoreAudio

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    var previousOutputDevices: [EZAudioDevice]!
    let menu: NSMenu = NSMenu()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusItem.button?.title = "🔊"
        statusItem.menu = menu
        addMenuItems()
        
        addListenerBlock(audioObjectPropertyListenerBlock,
            onAudioObjectID: AudioObjectID(bitPattern: kAudioObjectSystemObject),
            forPropertyAddress: AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMaster))
        
        NSThread(target: self, selector: Selector("backgroundLoop"), object: nil).start()
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    //http://stackoverflow.com/a/26953667
    func applicationIsInStartUpItems() -> Bool {
        return (itemReferencesInLoginItems().existingReference != nil)
    }
    
    func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItemRef?, lastReference: LSSharedFileListItemRef?) {
        let itemUrl : UnsafeMutablePointer<Unmanaged<CFURL>?> = UnsafeMutablePointer<Unmanaged<CFURL>?>.alloc(1)
        if let appUrl : NSURL = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
            let loginItemsRef = LSSharedFileListCreate(
                nil,
                kLSSharedFileListSessionLoginItems.takeRetainedValue(),
                nil
                ).takeRetainedValue() as LSSharedFileListRef?
            if loginItemsRef != nil {
                let loginItems: NSArray = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as NSArray
                let lastItemRef: LSSharedFileListItemRef = loginItems.lastObject as! LSSharedFileListItemRef
                for var i = 0; i < loginItems.count; ++i {
                    let currentItemRef: LSSharedFileListItemRef = loginItems.objectAtIndex(i)as! LSSharedFileListItemRef
                    if LSSharedFileListItemResolve(currentItemRef, 0, itemUrl, nil) == noErr {
                        if let urlRef: NSURL =  itemUrl.memory?.takeRetainedValue() {
                            if urlRef.isEqual(appUrl) {
                                return (currentItemRef, lastItemRef)
                            }
                        }
                    }
                }
                //The application was not found in the startup list
                return (nil, lastItemRef)
            }
        }
        return (nil, nil)
    }
    
    func toggleLaunchAtStartup() {
        let itemReferences = itemReferencesInLoginItems()
        let shouldBeToggled = (itemReferences.existingReference == nil)
        let loginItemsRef = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
            ).takeRetainedValue() as LSSharedFileListRef?
        if loginItemsRef != nil {
            if shouldBeToggled {
                if let appUrl : CFURLRef = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
                    LSSharedFileListInsertItemURL(
                        loginItemsRef,
                        itemReferences.lastReference,
                        nil,
                        nil,
                        appUrl,
                        nil,
                        nil
                    )
                    menu.itemWithTag(2)!.state = NSOnState
                    print("Application was added to login items")
                }
            } else {
                if let itemRef = itemReferences.existingReference {
                    LSSharedFileListItemRemove(loginItemsRef,itemRef);
                    print("Application was removed from login items")
                    menu.itemWithTag(2)!.state = NSOffState
                }
            }
        }
    }
    
    func checkIfLaunchAtStartup() -> Bool {
        let itemReferences = itemReferencesInLoginItems()
        let shouldBeToggled = (itemReferences.existingReference == nil)
        let loginItemsRef = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
            ).takeRetainedValue() as LSSharedFileListRef?
        if loginItemsRef != nil {
            if shouldBeToggled {
            } else {
                if let itemRef = itemReferences.existingReference {
                    return true
                }
            }
        }
        return false
    }
    
    @IBAction func switchAudioDevice(sender: AnyObject) {
        let device = AudioDeviceID((sender.representedObject as! EZAudioDevice).deviceID)
        setDevice(device)
    }
    
    func backgroundLoop() {
        while true {
            sleep(5)
            if(checkForNewDevices()) {
                dispatch_async(dispatch_get_main_queue()) {
                    self.refreshMenu()
                }
            }
        }
    }
    
    //http://stackoverflow.com/a/32211296
    func addListenerBlock( listenerBlock: AudioObjectPropertyListenerBlock, onAudioObjectID: AudioObjectID, var forPropertyAddress: AudioObjectPropertyAddress) {
        if (kAudioHardwareNoError != AudioObjectAddPropertyListenerBlock(onAudioObjectID, &forPropertyAddress, nil, listenerBlock)) {
            print("Error calling: AudioObjectAddPropertyListenerBlock") }
    }
    
    func audioObjectPropertyListenerBlock (numberAddresses: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>) {
        
        var index: UInt32 = 0
        while index < numberAddresses {
            let address: AudioObjectPropertyAddress = addresses[0]
            switch address.mSelector {
            case kAudioHardwarePropertyDefaultOutputDevice:
                self.refreshMenu()
            default:
                print("THIS SHOULD NOT HAPPEN, YOU MESSED UP!")
            }
            index += 1
        }
        
        // Utility function to get default audio output device:
        func getDefaultAudioOutputDevice () -> AudioObjectID {
            
            var devicePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
            var deviceID: AudioObjectID = 0
            var dataSize = UInt32(truncatingBitPattern: sizeof(AudioDeviceID))
            let systemObjectID = AudioObjectID(bitPattern: kAudioObjectSystemObject)
            if (kAudioHardwareNoError != AudioObjectGetPropertyData(systemObjectID, &devicePropertyAddress, 0, nil, &dataSize, &deviceID)) { return 0 }
            return deviceID
        }
    }
    
    func refreshMenu() {
        self.menu.removeAllItems()
        self.addMenuItems()
    }
    
    func checkForNewDevices() -> Bool {
        let outputDevices: [EZAudioDevice] = EZAudioDevice.outputDevices() as! [EZAudioDevice]
        
        if(self.previousOutputDevices == nil) {
            self.previousOutputDevices = outputDevices
            return false
        }
        
        if(previousOutputDevices == outputDevices) {
            return false
        }
        else {
            previousOutputDevices = outputDevices
            return true
        }
    }
    
    func addMenuItems() -> Void {
        let outputDevices: [EZAudioDevice] = EZAudioDevice.outputDevices() as! [EZAudioDevice]
        
        for device in outputDevices {
            let menuItem = NSMenuItem(title: device.name, action: Selector("switchAudioDevice:"), keyEquivalent: "")
            menuItem.representedObject = device
            self.menu.addItem(menuItem)
        }
        
        menu.itemWithTitle(EZAudioDevice.currentOutputDevice().name)?.state = NSOnState
        
        let openAtLaunchBtn: NSMenuItem = NSMenuItem(title: "Open at Login", action: Selector("toggleLaunchAtStartup"), keyEquivalent: "")
        openAtLaunchBtn.state = checkIfLaunchAtStartup() ? NSOnState : NSOffState
        openAtLaunchBtn.tag = 2
        self.menu.addItem(openAtLaunchBtn)
        
        let quitBtn: NSMenuItem = NSMenuItem(title: "Quit", action: Selector("quit"), keyEquivalent: "Q")
        self.menu.addItem(quitBtn)
    }
    
    func quit() {
        exit(0)
    }
}
