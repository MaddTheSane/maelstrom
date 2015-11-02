//
//  SwiftHelping.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/2/15.
//
//

import Foundation

extension String {
	mutating func replaceAllInstancesOfCharacter(aChar: Character, withCharacter bChar: Character) {
		while let charRange = rangeOfString(String(aChar)) {
			replaceRange(charRange, with: String(bChar))
		}
	}
}
