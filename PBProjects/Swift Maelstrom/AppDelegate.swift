//
//  AppDelegate.swift
//  Swift Maelstrom
//
//  Created by C.W. Betts on 11/1/15.
//
//

import Cocoa

private var pid: Int32 = -1

//@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var fragCount: NSTextField!
	@IBOutlet weak var fullscreen: NSButton!
	@IBOutlet weak var joinGame: NSButton!
	@IBOutlet weak var netAddress: NSTextField!
	@IBOutlet weak var numberOfPlayers: NSTextField!
	@IBOutlet weak var playDeathmatch: NSButton!
	@IBOutlet weak var playerNumber: NSTextField!
	@IBOutlet weak var realtime: NSButton!
	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var worldScores: NSButton!
	
	private var serverStarted = false

	@IBAction func cancel(sender: AnyObject?) {
		NSApp.abortModal()
		window.close()
		exit(0);
	}
	
	@IBAction func quit(sender: AnyObject?) {
		var event = SDL_Event()
		event.type = SDL_QUIT.rawValue;
		SDL_PushEvent(&event);
	}

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		//#if DEBUG
		//	assert(chdir(NSBundle.mainBundle().bundleURL.URLByDeletingLastPathComponent!.fileSystemRepresentation) == 0)
		//#else
		assert(chdir(NSBundle.mainBundle().resourceURL!.fileSystemRepresentation) == 0)
		//#endif
		NSBundle.mainBundle().executablePath
		//var parentdir = [Int8](count: Int(MAXPATHLEN), repeatedValue: 0)
		//strcpy(&parentdir, gArgv[0])
		gArgv[0] = strdup(NSBundle.mainBundle().resourceURL!.URLByAppendingPathComponent("Maelstrom.app").fileSystemRepresentation)
		gArgc = 1
		
		atexit_b { () -> Void in
			if pid != -1 {
				kill(pid, SIGTERM)
			}
		}
		
		NSApp.runModalForWindow(window)
		
		SDL_main(gArgc, &gArgv)
		exit(0)
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}


}

