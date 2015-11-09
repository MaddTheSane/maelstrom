//
//  SwiftHelping.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/2/15.
//
//

import Foundation

//MARK: - SDL macros

typealias SDL_WindowPtr = COpaquePointer
typealias SDL_ThreadPtr = COpaquePointer

func SDL_WINDOWPOS_CENTERED_DISPLAY(X: Int32) -> Int32 {
	return SDL_WINDOWPOS_CENTERED_MASK | 0
}

var SDL_WINDOWPOS_CENTERED: Int32 {
	return SDL_WINDOWPOS_CENTERED_DISPLAY(0)
}

func SDL_LoadBMP(file: UnsafePointer<CChar>) -> UnsafeMutablePointer<SDL_Surface> {
	return SDL_LoadBMP_RW(SDL_RWFromFile(file, "rb"), 1)
}

func SDL_LoadWAV(file: UnsafePointer<CChar>, inout _ spec: SDL_AudioSpec, _ audio_buf: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>, inout _ audio_len: UInt32) -> UnsafeMutablePointer<SDL_AudioSpec> {
	return SDL_LoadWAV_RW(SDL_RWFromFile(file, "rb"),1, &spec,audio_buf,&audio_len)
}

//MARK: -

extension String {
	mutating func replaceAllInstancesOfCharacter(aChar: Character, withCharacter bChar: Character) {
		if aChar == bChar {
			return
		}
		while let charRange = rangeOfString(String(aChar)) {
			replaceRange(charRange, with: String(bChar))
		}
	}
}

func ==(lhs: MaelOSType, rhs: MaelOSType) -> Bool {
	return lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c && lhs.d == rhs.d
}

struct MaelOSType: Hashable {
	//TODO: make this endian-safe
	var a: UInt8
	var b: UInt8
	var c: UInt8
	var d: UInt8
	
	init?(stringValue: String) {
		if var aStr = stringValue.cStringUsingEncoding(NSMacOSRomanStringEncoding) {
			while aStr.count < 4 {
				aStr.append(0)
			}
			a = UInt8(bitPattern: aStr[0])
			b = UInt8(bitPattern: aStr[1])
			c = UInt8(bitPattern: aStr[2])
			d = UInt8(bitPattern: aStr[3])
		} else {
			return nil
		}
	}
	
	var rawOSType: OSType {
		get {
			//TODO: make this endian-safe
			var toRet: OSType = 0
			toRet |= OSType(a) << 24
			toRet |= OSType(b) << 16
			toRet |= OSType(c) << 8
			toRet |= OSType(d)
			
			return toRet
		}
		set(aType) {
			//TODO: make this endian-safe
			a = UInt8((aType >> 24) & 0xFF)
			b = UInt8((aType >> 16) & 0xFF)
			c = UInt8((aType >> 8) & 0xFF)
			d = UInt8((aType >> 0) & 0xFF)
		}
	}
	
	var stringValue: String {
		let array = [a, b, c, d]
		if let nsStr = NSString(bytes: array, length: 4, encoding: NSMacOSRomanStringEncoding) {
			return nsStr as String
		}
		
		return String(format: "0x%02X%02X%02X%02X", a, b, c, d)
	}
	
	init() {
		a = 0
		b = 0
		c = 0
		d = 0
	}
	
	init(`OSType` aType: UInt32) {
		//TODO: make this endian-safe
		a = UInt8((aType >> 24) & 0xFF)
		b = UInt8((aType >> 16) & 0xFF)
		c = UInt8((aType >> 8) & 0xFF)
		d = UInt8((aType >> 0) & 0xFF)
	}
	
	init(a: UInt8, b: UInt8, c: UInt8, d: UInt8) {
		self.a = a
		self.b = b
		self.c = c
		self.d = d
	}
	
	var hashValue: Int {
		return rawOSType.hashValue
	}
}
