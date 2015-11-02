//
//  Mac_Compat.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/1/15.
//
//

import Foundation

/// Delay(x) -- sleep for x number of 1/60 second slices
func Delay(x: UInt32) {
	SDL_Delay(((x)*1000)/60)
}

/// Ticks -- a global variable containing current time in 1/60 second slices
var Ticks: UInt32 {
	return SDL_GetTicks() * 60 / 1000
}
