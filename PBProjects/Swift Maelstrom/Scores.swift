//
//  Scores.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/10/15.
//
//

import Foundation

private var scoreLocation: NSURL!
private let NUM_SCORES			= 10		// Do not change this!

let hScores = HighScores()

/// Best used for tuples of the same type, which Swift converts fixed-sized C arrays into.
/// Will crash if any type in the mirror doesn't match `X`.
///
/// - parameter mirror: The `MirrorType` to get the reflected values from.
/// - parameter lastObj: Best used for a fixed-size C array that expects to be NULL-terminated, like a C string. If passed `nil`, no object will be put on the end of the array. Default is `nil`.
private func getArrayFromMirror<X>(mirror: Mirror, appendLastObject lastObj: X? = nil) -> [X] {
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

enum ReflectError: ErrorType {
	case UnexpectedType(Any.Type)
}

private func arrayFromObjectByMirroring<X>(obj: Any, appendLastObject lastObj: X? = nil) throws -> [X] {
	var anArray = [X]()
	let mirror = Mirror(reflecting: obj)
	for val in mirror.children {
		guard let aChar = val.value as? X else {
			throw ReflectError.UnexpectedType(val.value.dynamicType)
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
	private var scoreList = [Score](count: NUM_SCORES, repeatedValue: Score())
	
	/** The high scores structure */
	struct Score: Comparable, Hashable {
		///The name of the player
		var name = ""
		///The wave, or level, that the player reached
		var wave: UInt32 = 0
		///The final score of the player
		var score: UInt32 = 0
		
		var hashValue: Int {
			return name.hashValue ^ wave.hashValue ^ score.hashValue
		}
	}
	
	func clearScores() {
		scoreList = [Score](count: NUM_SCORES, repeatedValue: Score())
	}
	
	func printHighScores() {
		
	}
	
	func saveScores() {
		assert(scoreList.count == NUM_SCORES)
		var saveScoreArray = [[String: AnyObject]]()
		for score in scoreList {
			var scoreDict = [String: NSObject]()
			scoreDict["name"] = score.name
			scoreDict["wave"] = Int(score.wave)
			scoreDict["score"] = Int(score.score)

			saveScoreArray.append(scoreDict)
		}
		let mutData = NSMutableData()
		let archiver = NSKeyedArchiver(forWritingWithMutableData: mutData)
		archiver.encodeObject(saveScoreArray as NSArray, forKey: "Scores")
	}
	
	func beginCustomLevel() -> Int32 {
		return 0
	}
	
	func zapHighScores() -> Bool {
		return false
	}

	var anArr: Array<Int> = []
	subscript (index: Int) -> Score {
		return Score(name: "hi", wave: 0, score: 0)
	}

	func loadScores() {
		//We aren't going to write to our own files within our bundle: It's a bad idea, and would ruin code signing
		let fm = NSFileManager.defaultManager()
		do {
			var ourDir = try fm.URLForDirectory(.ApplicationSupportDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
			for pathComp in ["Maelstrom", "Scores"] {
				ourDir = ourDir.URLByAppendingPathComponent(pathComp)
			}
			scoreLocation = ourDir
			
			guard ourDir.checkResourceIsReachableAndReturnError(nil) else {
				//load old scores
				let MAELSTROM_SCORES	= "Maelstrom-Scores"
				
				guard let oldScorePath = NSBundle.mainBundle().URLForResource(MAELSTROM_SCORES, withExtension: nil) else {
					//huh, okay...
					
					hScores.clearScores()
					hScores.saveScores()
					
					return
				}
				
				let scores_src = SDL_RWFromFile(oldScorePath.fileSystemRepresentation, "rb")
				guard scores_src != nil else {
					//huh, okay...
					
					hScores.clearScores()
					hScores.saveScores()
					
					return
				}
				
				var oldScores = [OldScores](count: NUM_SCORES, repeatedValue: OldScores())
				for i in 0..<NUM_SCORES {
					SDL_RWread(scores_src, &oldScores[i].name, sizeofValue(oldScores[i].name), 1)
					oldScores[i].wave = SDL_ReadBE32(scores_src)
					oldScores[i].score = SDL_ReadBE32(scores_src)
				}
				SDL_RWclose(scores_src);
				
				//import old scores
				
				//save new scores
				hScores.saveScores()
				
				return
			}
			
			//Load new scores
			
		} catch {
			fatalError("Fatal error: \(error)")
		}
	}
	
	private func loadOldScores(oldScores: [OldScores]) {
		for (i, oldscore) in oldScores.enumerate() {
			let cChar: [Int8] = try! arrayFromObjectByMirroring(oldscore.name, appendLastObject: 0)
			let aName = String(cChar)
			let newScore = Score(name: aName, wave: oldscore.wave, score: oldscore.score)
			scoreList[i] = newScore
		}
	}
}
