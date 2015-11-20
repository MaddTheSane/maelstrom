//
//  Player.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/11/15.
//
//

import Foundation

final class Player: MaelObject {
	///Special features of the player
	struct PlayerFeatures: OptionSetType {
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
}
