//
//  SDLMain.swift
//  Maelstrom
//
//  Created by C.W. Betts on 10/31/15.
//
//

import Cocoa
import SDL2

private var pid: Int32 = -1;

func colorsAtGamma(_ gamma: UInt8) -> UnsafeBufferPointer<SDL_Color> {
	let toRet2 = __colorsAtGamma(gamma)
	return UnsafeBufferPointer(start: toRet2, count: 256)
}

class SDLMain : NSObject, NSApplicationDelegate {
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
	
	fileprivate var serverStarted = false
	
	@IBAction func cancel(_ sender: AnyObject?) {
		NSApp.abortModal()
		window.close()
		exit(0);
	}
	
	@IBAction func quit(_ sender: AnyObject?) {
		var event = SDL_Event()
		event.type = SDL_QUIT.rawValue;
		SDL_PushEvent(&event);
	}
	
	@IBAction func startGame(_ sender: AnyObject!) {
		// extract settings, add them to arguments array
		if fullscreen.state == .on {
			ADD_ARG("-fullscreen");
		}
		
		// enable realtime scheduling to get more CPU time.
		if realtime.state == .on {
			var policy: Int32 = 0
			var param = sched_param()
			let thread = pthread_self();
			pthread_getschedparam (thread, &policy, &param);
			policy = SCHED_RR;
			param.sched_priority = 47;
			pthread_setschedparam (thread, policy, &param);
			pthread_getschedparam (thread, &policy, &param);
		}
		
		if worldScores.state == .on {
			ADD_ARG("-netscores");
		}
		
		if joinGame.state == .on {
			//char *storage[1024];
			//char *buffer = (char*)storage;
			var buffer = ""
			
			ADD_ARG("-player");
			buffer = String(playerNumber.intValue)
			ADD_ARG(buffer);
			ADD_ARG("-server");
			buffer = "\(numberOfPlayers.intValue)@\(netAddress.stringValue)"
			ADD_ARG(buffer);
			
			if playDeathmatch.state == .on {
				ADD_ARG("-deathmatch");
				buffer = String(fragCount.intValue)
				ADD_ARG(buffer);
			}
		}
		
		NSApp.abortModal()
		window.close()
	}
	
	@IBAction func startServer(_ sender: NSButton) {
		if !serverStarted {
			var newPid: pid_t = 0
			//var args = [UnsafePointer<Int8>](count: 2, repeatedValue: nil)
			let servLoc = Bundle.main.url(forResource: "Maelstrom_Server", withExtension: nil)!
			posix_spawn(&newPid, (servLoc as NSURL).fileSystemRepresentation, nil, nil, nil, nil);
			if ( newPid == 0 ) {
			} else {
				pid = newPid;
				if ( waitpid (pid, nil, WNOHANG) == 0 ) {
					serverStarted = true;
					sender.title = "Stop Server"
				}
			}
		} else {
			if ( kill (pid, SIGTERM) == 0) {
				serverStarted = false
				sender.title = "Start Server"
				pid = -1;
			}
		}
	}
	
	@IBAction func toggleFullscreen(_ sender: AnyObject!) {
		
	}
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		//#if DEBUG
		//	assert(chdir(NSBundle.mainBundle().bundleURL.URLByDeletingLastPathComponent!.fileSystemRepresentation) == 0)
		//#else
			assert(chdir((Bundle.main.resourceURL! as NSURL).fileSystemRepresentation) == 0)
		//#endif
		//Bundle.main.executablePath
		//var parentdir = [Int8](count: Int(MAXPATHLEN), repeatedValue: 0)
		//strcpy(&parentdir, gArgv[0])
		gArgv[0] = Bundle.main.resourceURL!.appendingPathComponent("Maelstrom.app").withUnsafeFileSystemRepresentation { (path) -> UnsafeMutablePointer<Int8> in
			return strdup(path)
		}
		gArgc = 1
		
		atexit_b { () -> Void in
			if pid != -1 {
				kill(pid, SIGTERM)
			}
		}
		
		NSApp.runModal(for: window)
		
		Swift_Maelstrom.SDL_main(gArgc, &gArgv)
		exit(0)
	}
}
