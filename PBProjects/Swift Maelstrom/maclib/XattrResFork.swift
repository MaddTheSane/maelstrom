//
//  XattrResFork.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/16/15.
//
//

import Foundation
import Darwin.POSIX.sys.xattr

private struct Fmem {
	var pos: Int = 0
	var buffer: Unmanaged<NSData>
	
	var size: Int {
		return buffer.takeUnretainedValue().length
	}
}

private func readfn(handler: UnsafeMutablePointer<Void>, buf: UnsafeMutablePointer<Int8>, var size: Int32) -> Int32 {
	let mem = UnsafeMutablePointer<Fmem>(handler)
	let available = mem.memory.size - mem.memory.pos;
	
	if Int(size) > available {
		size = Int32(available)
	}
	memcpy(buf, mem.memory.buffer.takeUnretainedValue().bytes.advancedBy(mem.memory.pos), sizeof(Int8) * Int(size));
	mem.memory.pos += Int(size);
	
	return size;
}

private func seekfn(handler: UnsafeMutablePointer<Void>, offset: fpos_t, whence: Int32) -> fpos_t {
	let mem = UnsafeMutablePointer<Fmem>(handler)
	var pos = 0
	
	switch (whence) {
	case SEEK_SET:
		if offset >= 0 {
			pos = Int(offset)
		} else {
			pos = 0;
		}
		
	case SEEK_CUR:
		if (offset >= 0 || Int(-offset) <= mem.memory.pos) {
			pos = mem.memory.pos + Int(offset);
		} else {
			pos = 0;
		}
		
	case SEEK_END:
		pos = mem.memory.size + Int(offset)
	default:
		return -1;
	}
	
	if (pos > mem.memory.size) {
		return -1;
	}
	
	mem.memory.pos = pos;
	return fpos_t(pos)
}

private func closefn(handler: UnsafeMutablePointer<Void>) -> Int32 {
	let mem = UnsafeMutablePointer<Fmem>(handler)
	
	mem.memory.buffer.release()
	mem.dealloc(1)
	
	return 0
}

func fileFromResourceFork(url: NSURL) -> UnsafeMutablePointer<FILE> {
	#if os(OSX)
		let fsr = url.absoluteURL.fileSystemRepresentation
		let rsrcSize = getxattr(fsr, XATTR_RESOURCEFORK_NAME, nil, 0, 0, 0)
		guard rsrcSize > 0 else {
			return nil
		}
		let mutData = NSMutableData(length: rsrcSize)!
		let gotBytes = getxattr(fsr, XATTR_RESOURCEFORK_NAME, mutData.mutableBytes, mutData.length, 0, 0)
		guard gotBytes != -1 else {
			return nil
		}
		
		assert(rsrcSize == gotBytes)
		
		let fmemPtr = UnsafeMutablePointer<Fmem>.alloc(1)
		fmemPtr.memory.pos = 0
		let storedBytes = NSData(data: mutData)
		fmemPtr.memory.buffer = Unmanaged.passRetained(storedBytes)
		
		return funopen(fmemPtr, readfn, nil, seekfn, closefn)
	#else
		return nil
	#endif
}
