//
//  SDLHelpers.swift
//  SDLTest
//
//  Created by C.W. Betts on 2/1/16.
//
//

import Foundation
import SDL2

/*
public var SDL_AUDIO_MASK_BITSIZE: Int32 { get }
public var SDL_AUDIO_MASK_DATATYPE: Int32 { get }
public var SDL_AUDIO_MASK_ENDIAN: Int32 { get }
public var SDL_AUDIO_MASK_SIGNED: Int32 { get }
*/

//extension SDL_AudioFormat {
//	var bitSize: UInt8 {
//		return UInt8(self.rawValue & SDL_AUDIO_MASK_BITSIZE.rawValue)
//	}
//}

//MARK: - log

/// Log a message with `SDL_LOG_PRIORITY_ERROR`
func SDL_LogError(category: Int32, _ fmt: String, _ args: CVarArgType...) {
	let blankVA = getVaList([])
	let aStr = NSString(format: fmt, arguments: getVaList(args)) as String
	SDL_LogMessageV(category, SDL_LOG_PRIORITY_ERROR, aStr, blankVA)
}

func SDL_Log(fmt: String, _ args: CVarArgType...) {
	let blankVA = getVaList([])
	let aStr = NSString(format: fmt, arguments: getVaList(args)) as String
	SDL_LogMessageV(Int32(SDL_LOG_CATEGORY_APPLICATION), SDL_LOG_PRIORITY_INFO, aStr, blankVA)
}

/// Log a message with `SDL_LOG_PRIORITY_VERBOSE`
func SDL_LogVerbose(category: Int32, _ fmt: String, _ args: CVarArgType...) {
	let blankVA = getVaList([])
	let aStr = NSString(format: fmt, arguments: getVaList(args)) as String
	SDL_LogMessageV(Int32(SDL_LOG_CATEGORY_APPLICATION), SDL_LOG_PRIORITY_VERBOSE, aStr, blankVA)
}

/// Log a message with `SDL_LOG_PRIORITY_DEBUG`
func SDL_LogDebug(category: Int32, _ fmt: String, _ args: CVarArgType...) {
	let blankVA = getVaList([])
	let aStr = NSString(format: fmt, arguments: getVaList(args)) as String
	SDL_LogMessageV(Int32(SDL_LOG_CATEGORY_APPLICATION), SDL_LOG_PRIORITY_DEBUG, aStr, blankVA)
}

/// Log a message with `SDL_LOG_PRIORITY_INFO`
func SDL_LogInfo(category: Int32, _ fmt: String, _ args: CVarArgType...) {
	let blankVA = getVaList([])
	let aStr = NSString(format: fmt, arguments: getVaList(args)) as String
	SDL_LogMessageV(Int32(SDL_LOG_CATEGORY_APPLICATION), SDL_LOG_PRIORITY_INFO, aStr, blankVA)
}

/// Log a message with `SDL_LOG_PRIORITY_WARN`
func SDL_LogWarn(category: Int32, _ fmt: String, _ args: CVarArgType...) {
	let blankVA = getVaList([])
	let aStr = NSString(format: fmt, arguments: getVaList(args)) as String
	SDL_LogMessageV(Int32(SDL_LOG_CATEGORY_APPLICATION), SDL_LOG_PRIORITY_WARN, aStr, blankVA)
}

/// Log a message with SDL_LOG_PRIORITY_CRITICAL
func SDL_LogCritical(category: Int32, _ fmt: String, _ args: CVarArgType...) {
	let blankVA = getVaList([])
	let aStr = NSString(format: fmt, arguments: getVaList(args)) as String
	SDL_LogMessageV(Int32(SDL_LOG_CATEGORY_APPLICATION), SDL_LOG_PRIORITY_CRITICAL, aStr, blankVA)
}

// MARK: -

public func SDL_LoadWAV(file: UnsafePointer<CChar>, _ spec: UnsafeMutablePointer<SDL_AudioSpec>, _ audio_buf: UnsafeMutablePointer<UnsafeMutablePointer<Uint8>>, _ audio_len: UnsafeMutablePointer<Uint32>) -> UnsafeMutablePointer<SDL_AudioSpec> {
	return SDL_LoadWAV_RW(SDL_RWFromFile(file, "rb"), 1, spec, audio_buf, audio_len)
}

public func SDL_GameControllerAddMappingsFromFile(file: UnsafePointer<CChar>) -> Int32 {
	return SDL_GameControllerAddMappingsFromRW(SDL_RWFromFile(file, "rb"), 1)
}

typealias SDL_TexturePtr = COpaquePointer
typealias SDL_RendererPtr = COpaquePointer

//MARK: - rect

public func ==(a: SDL_Rect, b: SDL_Rect) -> Bool {
	return ((a.x == b.x) && (a.y == b.y) &&
		(a.w == b.w) && (a.h == b.h)) ? true : false
}

extension SDL_Rect: Equatable {
	/// Returns `true` if point resides inside a rectangle.
	public func pointIsInRect(p: SDL_Point) -> Bool {
		return ( (p.x >= x) && (p.x < (x + w)) &&
			(p.y >= y) && (p.y < (y + h)) ) ? true : false
	}
	
	/// Returns `true` if the rectangle has no area.
	public var empty: Bool {
		return ((self.w <= 0) || (self.h <= 0)) ? true : false;
	}
	
	
	/// Determine whether two rectangles intersect.
	///
	/// - returns: `true` if there is an intersection, `false` otherwise.
	public func intersectsRect(B: SDL_Rect) -> Bool {
		var ap = self
		var bp = B
		return SDL_HasIntersection(&ap, &bp).boolValue
	}
	
	/// Calculate the union of two rectangles.
	public func union(B: SDL_Rect) -> SDL_Rect {
		var ap = self
		var bp = B
		var result = SDL_Rect()
		SDL_UnionRect(&ap, &bp, &result)
		return result
	}
	
	public mutating func unionInPlace(B: SDL_Rect) {
		var ap = self
		var bp = B
		SDL_UnionRect(&ap, &bp, &self)
	}
}

//MARK: - mutexes

public func SDL_mutexP(m: COpaquePointer) -> Int32 {
	return SDL_LockMutex(m)
}

public func SDL_mutexV(m: COpaquePointer) -> Int32 {
	return SDL_UnlockMutex(m)
}

//MARK: - pixels

public typealias SDL_Colour = SDL_Color

//MARK: - quit

public func SDL_QuitRequested() -> Bool {
	SDL_PumpEvents()
	return SDL_PeepEvents(nil, 0, SDL_PEEKEVENT, SDL_QUIT.rawValue, SDL_QUIT.rawValue) > 0
}

//MARK: rwops

public func SDL_RWsize(ctx: UnsafeMutablePointer<SDL_RWops>) -> Sint64 {
	return ctx.memory.size(ctx)
}

public func SDL_RWseek(ctx: UnsafeMutablePointer<SDL_RWops>, _ offset: Int64, _ whence: Int32) -> Int64 {
	return ctx.memory.seek(ctx, offset, whence)
}

public func SDL_RWtell(ctx: UnsafeMutablePointer<SDL_RWops>) -> Int64 {
	return ctx.memory.seek(ctx, 0, RW_SEEK_CUR)
}

public func SDL_RWread(ctx: UnsafeMutablePointer<SDL_RWops>, _ ptr: UnsafeMutablePointer<Void>, _ size: Int, _ n: Int) -> Int {
	return ctx.memory.read(ctx, ptr, size, n)
}

public func SDL_RWwrite(ctx: UnsafeMutablePointer<SDL_RWops>, _ ptr: UnsafePointer<Void>, _ size: Int, _ n: Int) -> Int {
	return ctx.memory.write(ctx, ptr, size, n)
}

public func SDL_RWclose(ctx: UnsafeMutablePointer<SDL_RWops>) -> Int32 {
	return ctx.memory.close(ctx)
}


//MARK: - shape

extension WindowShapeMode {
	public var alpha: Bool {
		return (self == ShapeModeDefault || self == ShapeModeBinarizeAlpha || self == ShapeModeReverseBinarizeAlpha)
	}
}

public func SDL_SHAPEMODEALPHA(mode: WindowShapeMode) -> Bool {
	return mode.alpha
}

//MARK: - stdinc

extension SDL_bool: BooleanLiteralConvertible, BooleanType {
	public init(booleanLiteral value: Bool) {
		if value == true {
			self = SDL_TRUE
		} else {
			self = SDL_FALSE
		}
	}
	
	public var boolValue: Bool {
		if self == SDL_FALSE {
			return false
		} else {
			return true
		}
	}
}

//MARK: - surface

extension SDL_Surface {
	public var mustLock: Bool {
		return (flags & SDL_RLEACCEL) != 0
	}
}

public func SDL_MUSTLOCK(S: UnsafePointer<SDL_Surface>) -> Bool {
	return S.memory.mustLock
}

public func SDL_LoadBMP(file: UnsafePointer<Int8>) -> UnsafeMutablePointer<SDL_Surface> {
	return SDL_LoadBMP_RW(SDL_RWFromFile(file, "rb"), 1)
}

public func SDL_SaveBMP(surface: UnsafeMutablePointer<SDL_Surface>, _ file: UnsafePointer<CChar>) -> Int32 {
	return SDL_SaveBMP_RW(surface, SDL_RWFromFile(file, "wb"), 1)
}

//MARK: - timer

public func SDL_TICKS_PASSED(A: Uint32, _ B: Uint32) -> Bool {
	return (Int32(B) - Int32(A)) <= 0
}

#if false
///  Macro-like function to determine SDL version program was compiled against.
///
///  This macro fills in a SDL_version structure with the version of the
///  library you compiled against. This is determined by what header the
///  compiler uses. Note that if you dynamically linked the library, you might
///  have a slightly newer or older version at runtime. That version can be
///  determined with SDL_GetVersion(), which, unlike SDL_VERSION(),
///  is not a macro.
///
///  - parameter x: A pointer to a SDL_version struct to initialize.
public func SDL_VERSION(inout x: SDL_version) {
	x.major = Uint8(SDL_MAJOR_VERSION)
	x.minor = Uint8(SDL_MINOR_VERSION)
	x.patch = Uint8(SDL_PATCHLEVEL)

}
#endif

///  This function turns the version numbers into a numeric value:
///
///		(1,2,3) -> (1203)
///
///  This assumes that there will never be more than 100 patchlevels.
public func SDL_VERSIONNUM(X: UInt8, _ Y: UInt8, _ Z: UInt8) -> Int32 {
	return (Int32(X)*1000 + Int32(Y)*100 + Int32(Z))
}

// MARK: video:

public func SDL_WINDOWPOS_UNDEFINED_DISPLAY(x: Int32) -> Int32 {
	return SDL_WINDOWPOS_UNDEFINED_MASK | x
}

public let SDL_WINDOWPOS_UNDEFINED = SDL_WINDOWPOS_UNDEFINED_DISPLAY(0)

public func SDL_WINDOWPOS_ISUNDEFINED(X: Int32) -> Bool {
	return (X & Int32(bitPattern: 0xFFFF0000)) == SDL_WINDOWPOS_UNDEFINED_MASK
}


public func SDL_WINDOWPOS_CENTERED_DISPLAY(X: Int32) -> Int32 {
	return SDL_WINDOWPOS_CENTERED_MASK | X
}

public let SDL_WINDOWPOS_CENTERED = SDL_WINDOWPOS_CENTERED_DISPLAY(0)

public func SDL_WINDOWPOS_ISCENTERED(X: Int32) -> Bool {
	return (X & Int32(bitPattern: 0xFFFF0000)) == SDL_WINDOWPOS_CENTERED_MASK
}
