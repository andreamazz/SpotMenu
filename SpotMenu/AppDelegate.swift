//
//  AppDelegate.swift
//  SpotMenu
//
//  Created by Miklós Kristyán on 02/09/16.
//  Copyright © 2016 KM. All rights reserved.
//

import Cocoa
import Spotify

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    var eventMonitor: EventMonitor?

    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let popover = NSPopover()
    var timer: Timer?
    
    var lastTitle = ""
    var lastArtist = ""
    var lastState = PlayerState.playing
    
    var initialWidth:CGFloat = 0

    var hiddenView: NSView = NSView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusBarButtonImage")
            button.action = #selector(AppDelegate.togglePopover(_:))
            button.addSubview(hiddenView)
            updateTitle()
            initialWidth = statusItem.button!.bounds.width
            updateHidden()
        }
        
        popover.contentViewController = ViewController(nibName: "ViewController", bundle: nil)
        //popover.appearance = NSAppearance(named: NSAppearanceNameAqua)
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [unowned self] event in
            if self.popover.isShown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
        
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(AppDelegate.postUpdateNotification), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.updateTitleAndPopover), name: NSNotification.Name(rawValue: InternalNotification.key), object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        eventMonitor?.stop()
        NotificationCenter.default.removeObserver(self)
        timer!.invalidate()
    }

    
    func postUpdateNotification(){
        NotificationCenter.default.post(name: Notification.Name(rawValue: InternalNotification.key), object: self)
    }
    
    func updateTitle(){
        let state = Spotify.playerState
        if let artist = Spotify.currentTrack.artist {
            if let title = Spotify.currentTrack.title , lastTitle != title || lastArtist != artist || lastState != state {
                switch state {
                case .playing:
                    statusItem.title = ""
                default:
                    statusItem.title = ""
                }
                
                lastArtist = artist
                lastTitle = title
                lastState = state
            }
        } else {
            statusItem.title = nil
        }
        
    }
    
    func updateHidden(){
        hiddenView.frame = NSRect(x: statusItem.button!.bounds.width-initialWidth/2, y: statusItem.button!.bounds.height-1, width: 1, height: 1)
        statusItem.button!.updateLayer()
    }
    
    func updateTitleAndPopover() {
        updateTitle()
        updateHidden()
    }
    
    
    
    
    // MARK: - Popover

    func showPopover(_ sender: AnyObject?) {
        initialWidth = statusItem.button!.bounds.width
        updateHidden()
        popover.show(relativeTo: hiddenView.bounds, of: hiddenView, preferredEdge: NSRectEdge.minY)
        eventMonitor?.start()
    }
    
    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
    
    func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
}

