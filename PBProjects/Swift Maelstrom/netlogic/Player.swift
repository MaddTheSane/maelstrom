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
	struct PlayerFeatures: OptionSet {
		let rawValue: UInt8
		init(rawValue rv: UInt8) {
			rawValue = rv
		}
		
		static let MachineGuns = PlayerFeatures(rawValue: 0x01)
		static let AirBrakes = PlayerFeatures(rawValue: 0x02)
		static let TripleFire = PlayerFeatures(rawValue: 0x04)
		static let LongRange = PlayerFeatures(rawValue: 0x08)
		static let LuckyIrish = PlayerFeatures(rawValue: 0x80)
	}
	
	override var isPlayer: Bool {
		return true
	}
	
	// MARK: The Shot sprites for the Shinobi and Player
	static let playerShotColors: [UInt8] = [
		0xF0, 0xCC, 0xCC, 0xF0,
		0xCC, 0x96, 0xC6, 0xCC,
		0xCC, 0xC6, 0xC6, 0xCC,
		0xF0, 0xCC, 0xCC, 0xF0]
	
	static let enemyShotColors: [UInt8] = [
		0xDC, 0xDA, 0xDA, 0xDC,
		0xDA, 0x17, 0x23, 0xDA,
		0xDA, 0x23, 0x23, 0xDA,
		0xDC, 0xDA, 0xDA, 0xDC]
}


var gPlayerShot: UnsafeMutablePointer<SDL_Surface>? = nil
var gEnemyShot: UnsafeMutablePointer<SDL_Surface>? = nil

