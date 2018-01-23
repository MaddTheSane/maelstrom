//
//  Player.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/11/15.
//
//

import Foundation
import SDL2

final class Player: MaelObject {
	///Special features of the player
	struct Features: OptionSet {
		let rawValue: UInt8
		init(rawValue rv: UInt8) {
			rawValue = rv
		}
		
		static var machineGuns: Features {
			return Features(rawValue: 0x01)
		}
		static var airBrakes: Features {
			return Features(rawValue: 0x02)
		}
		static var tripleFire: Features {
			return Features(rawValue: 0x04)
		}
		static var longRange: Features {
			return Features(rawValue: 0x08)
		}
		static var luckyIrish: Features {
			return Features(rawValue: 0x80)
		}
	}
	
	/// The players!!
	static var players = [Player?](repeating: nil, count: Int(MAX_PLAYERS))

	override var isPlayer: Bool {
		return true
	}
	
	func cutThrust(_ dur: Int32) {
		
	}
	
	override func setSpecial(_ spec: Player.Features) {
		
	}
	
	override func increaseShieldLevel(_ level: Int32) {
		
	}
	
	override func multiplier(_ multiplier: Int32) {
		
	}
	
	override func increaseBonus(_ bonus: Int32) {
		
	}
	
	override func increaseLives(_ lives: Int32) {
		
	}

	
	// MARK: The Shot sprites for the Shinobi and Player
	/// The Shot sprites for the Player
	static let playerShotColors: [UInt8] = [
		0xF0, 0xCC, 0xCC, 0xF0,
		0xCC, 0x96, 0xC6, 0xCC,
		0xCC, 0xC6, 0xC6, 0xCC,
		0xF0, 0xCC, 0xCC, 0xF0]
	
	/// The Shot sprites for the Shinobi.
	static let enemyShotColors: [UInt8] = [
		0xDC, 0xDA, 0xDA, 0xDC,
		0xDA, 0x17, 0x23, 0xDA,
		0xDA, 0x23, 0x23, 0xDA,
		0xDC, 0xDA, 0xDA, 0xDC]
}


var gPlayerShot: UnsafeMutablePointer<SDL_Surface>? = nil
var gEnemyShot: UnsafeMutablePointer<SDL_Surface>? = nil

