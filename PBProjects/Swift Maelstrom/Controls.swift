//
//  Controls.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/10/15.
//
//

import Foundation

func loadControls() {
	
}

var gSoundLevel: UInt8 = 4
var gGammaCorrect: UInt8 = 3

func saveControls() {
	
}

func showDawn() {
	
}

func configureControls() {
	
}

func dropEvents() -> Int32 {
	var event = SDL_Event()
	var keys: Int32 = 0;
	
	while SDL_PollEvent(&event) != 0 {
		if event.type == SDL_KEYDOWN.rawValue {
			++keys;
		}
	}
	return keys
}

