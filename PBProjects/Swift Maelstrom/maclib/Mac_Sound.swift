//
//  Mac_Sound.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/2/15.
//
//

import Foundation

private func fillAudio(selfPtr: UnsafeMutablePointer<Void>, bytes: UnsafeMutablePointer<Uint8>, length: Int32) -> Void {
	//CGPathApply
}

final class Sound {
	private var intVol: UInt8 = 0
	var volume: UInt8 {
		get {
			return intVol
		}
		set(vol) {
			
		}
	}
	
	init(soundFileURL: NSURL, volume vol: UInt8 = 4) {
		volume = vol
	}
	//	Sound(const char *soundfile, Uint8 vol = 4);

}