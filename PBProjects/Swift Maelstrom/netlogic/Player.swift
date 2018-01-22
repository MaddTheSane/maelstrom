//
//  Player.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/11/15.
//
//

import Foundation
import SDL2

let MAX_PLAYERS = 3

final class Player: MaelObject {
	///Special features of the player
	struct Features: OptionSet {
		let rawValue: UInt8
		init(rawValue rv: UInt8) {
			rawValue = rv
		}
		
		/// The players!!
		static var players = [Player?](repeating: nil, count: MAX_PLAYERS)
		
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
	
	override var isPlayer: Bool {
		return true
	}
	
	func cutThrust(_ dur: Int32) {
		
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

