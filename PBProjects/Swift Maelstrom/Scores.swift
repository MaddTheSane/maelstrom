//
//  Scores.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/10/15.
//
//

import Foundation
import SDL2

private var scoreLocation: URL!
private let NUM_SCORES			= 10		// Do not change this!

private let CLR_DIALOG_WIDTH: Int32 =	281
private let CLR_DIALOG_HEIGHT: Int32 =	111


let hScores = HighScores()

/// Best used for tuples of the same type, which Swift converts fixed-sized C arrays into.
/// Will crash if any type in the mirror doesn't match `X`.
///
/// - parameter mirror: The `MirrorType` to get the reflected values from.
/// - parameter lastObj: Best used for a fixed-size C array that expects to be NULL-terminated, like a C string. If passed `nil`, no object will be put on the end of the array. Default is `nil`.
private func getArrayFromMirror<X>(_ mirror: Mirror, appendLastObject lastObj: X? = nil) -> [X] {
	var anArray = [X]()
	for val in mirror.children {
		let aChar = val.value as! X
		anArray.append(aChar)
	}
	if let lastObj = lastObj {
		anArray.append(lastObj)
	}
	return anArray
}

enum ReflectError: Error {
	case unexpectedType(Any.Type)
}

private func arrayFromObject<X>(reflecting obj: Any, appendLastObject lastObj: X? = nil) throws -> [X] {
	var anArray = [X]()
	let mirror = Mirror(reflecting: obj)
	for val in mirror.children {
		guard let aChar = val.value as? X else {
			throw ReflectError.unexpectedType(type(of: (val.value) as AnyObject))
		}
		anArray.append(aChar)
	}
	if let lastObj = lastObj {
		anArray.append(lastObj)
	}
	return anArray
}


private struct OldScores {
	var name: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	var wave: Uint32 = 0
	var score: Uint32 = 0
}

func ==(lhs: HighScores.Score, rhs: HighScores.Score) -> Bool {
	return lhs.score == rhs.score
}

func <(lhs: HighScores.Score, rhs: HighScores.Score) -> Bool {
	return lhs.score < rhs.score
}

final class HighScores {
	static var netScores = false
	fileprivate var scoreList = [Score](repeating: Score(), count: NUM_SCORES)
	
	/** The high scores structure */
	struct Score: Comparable, Hashable, CustomStringConvertible {
		///The name of the player
		var name = ""
		///The wave, or level, that the player reached
		var wave: UInt32 = 0
		///The final score of the player
		var score: UInt32 = 0
		
		var hashValue: Int {
			return name.hashValue ^ wave.hashValue ^ score.hashValue
		}
		
		var description: String {
			return name + ": wave: \(wave), score: \(score)"
		}
	}
	
	func clearScores() {
		scoreList = [Score](repeating: Score(), count: NUM_SCORES)
	}
	
	func printHighScores() {
		//TODO: implement
	}
	
	func saveScores() {
		assert(scoreList.count == NUM_SCORES)
		var saveScoreArray = [[String: AnyObject]]()
		for score in scoreList {
			var scoreDict = [String: NSObject]()
			scoreDict["name"] = score.name as NSObject
			scoreDict["wave"] = Int(score.wave) as NSObject
			scoreDict["score"] = Int(score.score) as NSObject

			saveScoreArray.append(scoreDict)
		}
		let mutData = NSMutableData()
		let archiver = NSKeyedArchiver(forWritingWith: mutData)
		archiver.encode(saveScoreArray as NSArray, forKey: "Scores")
		archiver.finishEncoding()
		mutData.write(to: scoreLocation, atomically: true)
	}
	
	func beginCustomLevel() -> Int32 {
		//TODO: implement
		return 0
	}
	
	func zapHighScores() -> Bool {
		let x: Int32
		let y: Int32
		var doClear = false
		
		/* Set up all the components of the dialog box */
		#if CENTER_DIALOG
			x=(SCREEN_WIDTH-CLR_DIALOG_WIDTH)/2;
			y=(SCREEN_HEIGHT-CLR_DIALOG_HEIGHT)/2;
		#else	/* The way it is on the original Maelstrom */
			x=179;
			y=89;
		#endif
		guard let chicago = try? fontserv.newFont("Chicago", pointSize: 12) else {
			print("Can't use Chicago font!\n");
			return false;
		}
		guard let splash = loadTitle(screen, title_id: 102) else {
			print("Can't load score zapping splash!");
			return false;
		}
		let dialog = MaclikeDialog(x: x, y: y, width: CLR_DIALOG_WIDTH, height: CLR_DIALOG_HEIGHT,
			screen: screen);
		dialog.addImage(splash, x: 4, y: 4);
		
		let clear = try! MacButton(x: 99, y: 74, width: BUTTON_WIDTH, height: BUTTON_HEIGHT,
			text: "Clear", font: chicago, fontserv: fontserv) { () -> Bool in
				doClear = true
				return true
		}
		dialog.addDialog(clear);
		let cancel = try! MacDefaultButton(x: 99+BUTTON_WIDTH+14, y: 74,
			width: BUTTON_WIDTH, height: BUTTON_HEIGHT,
			text: "Cancel", font: chicago, fontserv: fontserv) { () -> Bool in
				doClear = false
				return true
		}
		dialog.addDialog(cancel);
		
		/* Run the dialog box */
		dialog.run();
		
		/* Clean up and return */
		screen.freeImage(splash);
		if doClear {
			clearScores()
			saveScores()
			gLastHigh = -1;
		}
		return doClear;
	}

	subscript (index: Int) -> Score {
		return scoreList[index]
	}

	func loadScores() {
		//We aren't going to write to our own files within our bundle: It's a bad idea, and would ruin code signing
		let fm = FileManager.default
		do {
			var ourDir = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
			for pathComp in ["Maelstrom", "Scores"] {
				ourDir = ourDir.appendingPathComponent(pathComp)
			}
			scoreLocation = ourDir
			
			guard (ourDir as NSURL).checkResourceIsReachableAndReturnError(nil) else {
				//Create the app support directory, just in case
				
				do {
					try fm.createDirectory(at: scoreLocation.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
				} catch _ {}
				
				//load old scores
				let MAELSTROM_SCORES	= "Maelstrom-Scores"
				
				defer {
					//save new scores
					saveScores()
				}
				
				guard let oldScorePath = Bundle.main.url(forResource: MAELSTROM_SCORES, withExtension: nil) else {
					//huh, okay...
					
					clearScores()
					
					return
				}
				
				guard let scores_src = SDL_RWFromFile((oldScorePath as NSURL).fileSystemRepresentation, "rb") else {
					//huh, okay...
					
					clearScores()
					
					return
				}
				
				defer {
					SDL_RWclose(scores_src);
				}
				
				var oldScores = [OldScores](repeating: OldScores(), count: NUM_SCORES)
				for i in 0..<NUM_SCORES {
					SDL_RWread(scores_src, &oldScores[i].name, MemoryLayout.size(ofValue: oldScores[i].name), 1)
					oldScores[i].wave = SDL_ReadBE32(scores_src)
					oldScores[i].score = SDL_ReadBE32(scores_src)
				}
				
				//import old scores
				loadOldScores(oldScores)
				
				return
			}
			
			//Load new scores
			do {
				let fileData = try Data(contentsOf: scoreLocation, options: [])
				let keyedUnarchiver = NSKeyedUnarchiver(forReadingWith: fileData)
				guard let preScores = keyedUnarchiver.decodeObject(forKey: "Scores") as? [[String: NSObject]] else {
					saveScores()
					return
				}
				
				assert(preScores.count == NUM_SCORES)
				for (i,aDict) in preScores.enumerated() {
					var aScore = Score()
					aScore.name = aDict["name"] as! String
					aScore.wave = UInt32(aDict["wave"] as! Int)
					aScore.score = UInt32(aDict["score"] as! Int)
					scoreList[i] = aScore
				}
				
				sortScores()
			} catch {
				print("Unable to load scores, error: \(error)")
				saveScores()
				return
			}
		} catch {
			fatalError("Fatal error: \(error)")
		}
	}
	
	fileprivate func loadOldScores(_ oldScores: [OldScores]) {
		for (i, oldscore) in oldScores.enumerated() {
			let cChar: [Int8] = try! arrayFromObject(reflecting: oldscore.name, appendLastObject: 0)
			let aName = String(cString: cChar)
			let newScore = Score(name: aName, wave: oldscore.wave, score: oldscore.score)
			scoreList[i] = newScore
		}
		sortScores()
	}
	
	fileprivate func sortScores() {
		scoreList.sort(by: >)
	}
}
