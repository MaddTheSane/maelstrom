//
//  Mac_Resources.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/1/15.
//
//

import Foundation

/* The format for AppleDouble files -- in a header file */
private let APPLEDOUBLE_MAGIC: UInt32 = 0x00051607

/* The format for MacBinary files -- in a header file */
private let MACBINARY_MASK: UInt16 = 0xFCFF
private let MACBINARY_MAGIC: UInt16 = 0x8081


private func ==(lhs: MacResource.Resource, rhs: MacResource.Resource) -> Bool {
	return lhs.id == rhs.id
}

private func <(lhs: MacResource.Resource, rhs: MacResource.Resource) -> Bool {
	return lhs.id < rhs.id
}

@discardableResult
@inline(__always) internal func bytesex32(_ x: inout UInt32) -> UInt32 {
	x = x.bigEndian
	return x
}

@discardableResult
@inline(__always) internal func bytesex32(_ x: inout Int32) -> Int32 {
	x = x.bigEndian
	return x
}

@discardableResult
@inline(__always) internal func bytesex16(_ x: inout UInt16) -> UInt16 {
	x = x.bigEndian
	return x
}

@discardableResult
@inline(__always) internal func bytesex16(_ x: inout Int16) -> Int16 {
	x = x.bigEndian
	return x
}

/** Swap bytes from big-endian to this machine's type.
The input data is assumed to be always in big-endian format.
*/
@inline(__always) internal func byteswap(_ array: UnsafeMutablePointer<UInt16>, count nshorts: Int) {
	var array = array, nshorts = nshorts
	for _ in 0 ..< nshorts {
		bytesex16(&array.pointee)
		array = array.successor()
	}
}

/** Here's an iterator to find heuristically (I've always wanted to use that
word :-) a macintosh resource fork from a general mac name.

This function may be overkill, but I want to be able to find any Macintosh
resource fork, darn it! :)
*/
private func checkAppleFile(_ resfile: UnsafeMutablePointer<FILE>, resbase: inout Int) {
	var header = AppleSingleHeader()
	if fread(&header.magicNum, MemoryLayout<UInt32>.size, 1, resfile) != 0 && bytesex32(&header.magicNum) == APPLEDOUBLE_MAGIC {
		fread(&header.versionNum,
			MemoryLayout.size(ofValue: header.versionNum), 1, resfile);
		bytesex32(&header.versionNum);
		fread(&header.filler,
			MemoryLayout.size(ofValue: header.filler), 1, resfile);
		fread(&header.numEntries,
			MemoryLayout.size(ofValue: header.numEntries), 1, resfile);
		bytesex16(&header.numEntries);
		#if APPLEDOUBLE_DEBUG
			print(String(format: "Header magic: 0x%.8x, version 0x%.8x",
				header.magicNum, header.versionNum))
		#endif
		
		var entry = AppleSingleEntry()
		
		#if APPLEDOUBLE_DEBUG
			print(String(format: "Number of entries: %d, sizeof(entry) = %ld",
				header.numEntries, sizeofValue(entry)))
		#endif
		for i in 0..<header.numEntries {
			if fread(&entry, MemoryLayout.size(ofValue: entry), 1, resfile) == 0 {
				break;
			}
			bytesex32(&entry.entryIDValue);
			bytesex32(&entry.entryOffset);
			bytesex32(&entry.entryLength);
			#if APPLEDOUBLE_DEBUG
				print(String(format: "Entry (%d): ID = 0x%.8x, Offset = %d, Length = %d",
					i+1, entry.entryID, entry.entryOffset, entry.entryLength))
			#endif
			if entry.entryID == .resource {
				resbase = Int(entry.entryOffset)
				break;
			}
		}
	}
	
	fseek(resfile, 0, SEEK_SET)
}

private func checkMacBinary(_ resfile: UnsafeMutablePointer<FILE>, resbase: inout Int) {
	var header = MBHeader()
	if fread(&header, MemoryLayout<MBHeader>.size, 1, resfile) != 0 && (header.version & MACBINARY_MASK) == MACBINARY_MAGIC {
		resbase = MemoryLayout<MBHeader>.size + Int(header.dataLength)
	}
	fseek(resfile, 0, SEEK_SET)
}

private func openMacRes(_ original: inout URL, resbase: inout Int) -> UnsafeMutablePointer<FILE> {
	var resfile: UnsafeMutablePointer<FILE>? = nil
	let directory = original.deletingLastPathComponent()
	var filename = original.lastPathComponent
	var newURL: URL?
	
	func urlByAddingPath(_ aPath: String) -> URL {
		if (try? directory.checkResourceIsReachable()) ?? false {
			return directory.appendingPathComponent(aPath)
		}
		return URL(fileURLWithPath: aPath)
	}
	
	struct searchnreplace {
		var search: Character
		var replace: Character
	}
	let snr = [searchnreplace(search: "\0", replace: "\0"),
	searchnreplace(search: " ", replace: "_")]
	
	var iterations2 = 0
	
	for iterations in 0 ..< snr.count {
		/* Translate ' ' into '_', etc */
		/* Note that this translation is irreversible */
		filename.replaceAllInstances(of: snr[iterations].search, with: snr[iterations].replace)
		
		/* First look for Executor (tm) resource forks */
		var newName = "%\(filename)"
		newURL = urlByAddingPath(newName)
		resfile = newURL!.withUnsafeFileSystemRepresentation({ (fName) -> UnsafeMutablePointer<FILE>? in
			return fopen(fName, "rb")
		})
		guard resfile == nil else {
			break
		}
		
		newURL = nil
		
		/* Look for MacBinary files */
		newName = (filename as NSString).appendingPathExtension("bin")!
		newURL = urlByAddingPath(newName)
		resfile = newURL!.withUnsafeFileSystemRepresentation({ (fName) -> UnsafeMutablePointer<FILE>? in
			return fopen(fName, "rb")
		})
		guard resfile == nil else {
			break
		}
		
		newURL = nil

		/* Look for OS X-style metadata: it might have a resource fork */
		newName = "._\(filename)"
		newURL = urlByAddingPath(newName)
		resfile = newURL!.withUnsafeFileSystemRepresentation({ (fName) -> UnsafeMutablePointer<FILE>? in
			return fopen(fName, "rb")
		})
		if resfile != nil {
			//Be a bit more strict when looking for resources in OS X metadata.
			//Simply put, it might not have a resource fork.
			//...but it will always be an AppleSingle/AppleDouble file
			var resbase2 = 0
			checkAppleFile(resfile!, resbase: &resbase2)
			guard resbase2 != 0 else {
				break
			}
		}
		
		newURL = nil
		
		/* Look for actual resource fork on OS X */
		//Has to be placed here, otherwise the empty file will be loaded instead
		newName = filename
		newURL = urlByAddingPath(newName)
		resfile = fileFromResourceFork(newURL!)
		guard resfile == nil else {
			break
		}

		/* Look for raw resource fork.. */
		resfile = newURL!.withUnsafeFileSystemRepresentation({ (fName) -> UnsafeMutablePointer<FILE>? in
			return fopen(fName, "rb")
		})
		guard resfile == nil else {
			break
		}
		
		newURL = nil
		iterations2 = iterations
	}
	
	/* Did we find anything? */
	if iterations2 != snr.count {
		original = newURL!
		resbase = 0
		
		/* Look for AppleDouble format header */
		checkAppleFile(resfile!, resbase: &resbase)
		
		/* Look for MacBinary format header */
		checkMacBinary(resfile!, resbase: &resbase)
	}
	#if APPLEDOUBLE_DEBUG
		print(String(format: "Resfile base = %d", resbase))
	#endif

	return resfile!
}

// MARK: - These are the data structures that make up the Macintosh Resource Fork
private struct ResourceHeader {
	///Offset of resources in file
	var res_offset: UInt32 = 0
	///Offset of resource map in file
	var map_offset: UInt32 = 0
	///Length of the resource data
	var res_length: UInt32 = 0
	///Length of the resource map
	var map_length: UInt32 = 0
}

private struct TypeEntry {
	///Resource type
	var Res_type: MaelOSType = MaelOSType()
	///number of this type resources in map - 1
	var Num_rez: UInt16 = 0
	/** Offset from type list, of reference
	list for this type */
	var Ref_offset: UInt16 = 0
}

private struct ReferenceEntry {
	///The ID for this resource
	var Res_id: UInt16 = 0
	/** Offset in name list of resource
	name, or -1 if no name */
	var nameOffset: UInt16 = 0
	///Resource attributes
	var resourceAttrs: UInt8 = 0
	///3-byte offset from Resource data
	var Res_offset: (UInt8, UInt8, UInt8) = (0,0,0)
	///Reserved for use in-core
	var reserved: UInt32 = 0
	
	var resourceOffset: UInt32 {
		return ((UInt32(Res_offset.0)<<16) |
			(UInt32(Res_offset.1)<<8) |
			UInt32(Res_offset.2))
	}
};

private struct NameEntry {
	///Length of the following name
	var Name_len: UInt8
	//#if SHOW_VARLENGTH_FIELDS
	/// Variable length resource name
	//var name: (UInt8)
	//#endif
};

private struct ResourceMap {
	///Reserved for use in-core
	var Reserved: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
	///Map attributes
	var Map_attrs: UInt16
	///Offset of resource type list
	var types_offset: UInt16
	///Offset of resource name list
	var names_offset: UInt16
	///# of types in map - 1
	var num_types: UInt16
	/*
	#if SHOW_VARLENGTH_FIELDS
	struct Type_entry  types[0];	 /* Variable length types list */
	struct Ref_entry   refs[0];	 /* Variable length reference list */
	struct Name_entry  names[0];	 /* Variable length name list */
	#endif
*/
	init() {
		Reserved = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
		Map_attrs = 0
		types_offset = 0
		names_offset = 0
		num_types = 0
	}
}

final class MacResource {
	enum Errors: Error {
		case fileNotFound
		case couldNotOpenResource
		case couldNotFindResourceType(type: MaelOSType)
		case couldNotFindResourceTypeID(type: MaelOSType, id: UInt16)
		case couldNotFindResourceTypeName(type: MaelOSType, name: String)
		case couldNotReadData
	}
	
	/// The Resource Fork File
	fileprivate var filep: UnsafeMutablePointer<FILE>? = nil
	/// The offset of the rsrc
	fileprivate var base = 0

	/// Offset of Resource data in resource fork
	fileprivate var res_offset: UInt32 = 0
	/// Number of types of resources
	fileprivate var num_types: UInt16 = 0

	fileprivate var resources = [ResourceList]()
	
	fileprivate(set) var errstr: String?
	
	fileprivate final class Resource: Comparable {
		let name: String
		let id: UInt16
		let offset: UInt32
		fileprivate(set) var data: Data? = nil
		
		fileprivate init(entry ref_ent: ReferenceEntry, name: String) {
			offset =
				((UInt32(ref_ent.Res_offset.0)<<16) |
					(UInt32(ref_ent.Res_offset.1)<<8) |
					UInt32(ref_ent.Res_offset.2));
			id = ref_ent.Res_id;
			self.name = name
		}
	}

	fileprivate final class ResourceList {
		var type: MaelOSType
		fileprivate var intCount: UInt16
		fileprivate(set) var list = [Resource]()
		
		fileprivate init(entry: TypeEntry) {
			type = entry.Res_type
			intCount = entry.Num_rez
		}
	}
	
	convenience init(filename: String) throws {
		try self.init(fileURL: URL(fileURLWithPath: filename))
	}
	
	init(fileURL: URL) throws {
		var filename = fileURL
		var header = ResourceHeader()
		var resMap = ResourceMap()
		var typeEnt = TypeEntry()
		//Uint16                *ref_offsets;
		var name_len: UInt8 = 0
		//int i, n;
		
		/* Clear out any variables */
		resources = []
		
		/* Try to open the Macintosh resource fork */
		errstr = nil;
		filep = openMacRes(&filename, resbase: &base)
		guard filep != nil else {
			throw Errors.fileNotFound
			//error("Couldn't open resource file '%@'", filename);
		}
		fseek(filep, base, SEEK_SET);
		
		guard fread(&header, MemoryLayout<ResourceHeader>.size, 1, filep) != 0 else {
			throw Errors.couldNotOpenResource
			//error("Couldn't read resource info from '%s'", filename);
		}
		bytesex32(&header.res_length);
		bytesex32(&header.res_offset);
		res_offset = header.res_offset;
		bytesex32(&header.map_length);
		bytesex32(&header.map_offset);
		
		fseek(filep, base+Int(header.map_offset), SEEK_SET);
		guard fread(&resMap, MemoryLayout<ResourceMap>.size, 1, filep) != 0 else {
			throw Errors.couldNotOpenResource
			//error("Couldn't read resource info from '%s'", filename);
		}
		bytesex16(&resMap.types_offset);
		bytesex16(&resMap.names_offset);
		bytesex16(&resMap.num_types);
		resMap.num_types += 1;	/* Value in fork is one short */
		
		/* Fill in our class members */
		num_types = resMap.num_types;
		
		var ref_offsets = [UInt16]()
		ref_offsets.reserveCapacity(Int(num_types))
		fseek(filep, base+Int(header.map_offset)+Int(resMap.types_offset)+2, SEEK_SET)
		for _ in 0..<num_types {
			guard fread(&typeEnt, MemoryLayout<TypeEntry>.size, 1, filep) != 0 else {
				throw Errors.couldNotOpenResource
			}
			
			bytesex16(&typeEnt.Num_rez);
			bytesex16(&typeEnt.Ref_offset);
			typeEnt.Num_rez += 1;	/* Value in fork is one short */
			//typeEnt.Res_type.rawOSType = typeEnt.Res_type.rawOSType.bigEndian
			resources.append(ResourceList(entry: typeEnt))
			ref_offsets.append(typeEnt.Ref_offset)
		}
		
		for (i, aRes) in resources.enumerated() {
			fseek(filep,
				base + Int(header.map_offset) + Int(resMap.types_offset) + Int(ref_offsets[i]),
				SEEK_SET);
			for _ in 0..<Int(aRes.intCount) {
				var ref_ent = ReferenceEntry()
				
				guard fread(&ref_ent, MemoryLayout.size(ofValue: ref_ent), 1, filep) != 0 else {
					throw Errors.couldNotOpenResource
				}
				
				bytesex16(&ref_ent.Res_id)
				bytesex16(&ref_ent.nameOffset)
				
				var entName: String
				/* Grab the name, while we're here... */
				if ref_ent.nameOffset == 0xFFFF {
					entName = ""
				} else {
					let cur_offset = ftell(filep);
					fseek(filep,
						base+Int(header.map_offset)+Int(resMap.names_offset)+Int(ref_ent.nameOffset),
						SEEK_SET);
					fread(&name_len, 1, 1, filep);
					var aCharName = [UInt8](repeating: 0, count: Int(name_len))
					fread(&aCharName,
						1, Int(name_len), filep);
					let bCharName = Data(aCharName)
					if let nsName = String(data: bCharName, encoding: .macOSRoman) {
						entName = nsName
					} else {
						entName = "Encoding failure!"
					}
					fseek(filep, cur_offset, SEEK_SET);
				}
				
				let aPart = Resource(entry: ref_ent, name: entName)
				aRes.list.append(aPart)
			}
			aRes.list.sort(by: >)
		}
	}
	
	/** Create a set of resource types in this file */
	lazy var types: Set<MaelOSType> = {
		var toRet = Set<MaelOSType>()
		for res in self.resources {
			toRet.insert(res.type)
		}
		return toRet
	}()

	/** Return the number of resources of the given type */
	func countOfResources(type: MaelOSType) -> Int {
		for res in resources {
			if res.type == type {
				return res.list.count
			}
		}
		
		return 0
	}
	
	/** Create an array of resource ids for a type */
	func resourceIDs(type: MaelOSType) throws -> [UInt16] {
		var toRet = [UInt16]()
		for aRes in resources {
			if aRes.type == type {
				for aTyp in aRes.list {
					toRet.append(aTyp.id)
				}
				return toRet.sorted(by: <)
			}
		}
		throw Errors.couldNotFindResourceType(type: type)
	}

	func nameOfResource(type: MaelOSType, id: UInt16) throws -> String {
		for res in resources {
			if res.type == type {
				for aTyp in res.list {
					if aTyp.id == id {
						return aTyp.name
					}
				}
			}
		}
		throw Errors.couldNotFindResourceTypeID(type: type, id: id)
	}

	fileprivate func loadData(_ resource: Resource) throws {
		fseek(filep, base + Int(res_offset + resource.offset), SEEK_SET);
		
		var len: UInt32 = 0
		fread(&len, 4, 1, filep);
		len = len.bigEndian
		var d = Data(count: Int(len))
		try d.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
			guard fread(bytes, Int(len), 1, filep) != 0 else {
				throw Errors.couldNotReadData
			}
		}
		resource.data = d
	}
	
	/// Return a resource of a certain type and id.
	func resource(type res_type: MaelOSType, id: UInt16) throws -> Data {
		for rezes in resources {
			if rezes.type == res_type {
				for resource in rezes.list {
					if resource.id == id {
						if let data = resource.data {
							return data
						}
						
						try loadData(resource)
						
						return resource.data!
					}
				}
			}
		}
		
		throw Errors.couldNotFindResourceTypeID(type: res_type, id: id)
	}
	
	/// Return a resource of a certain type and name.
	func resource(type res_type: MaelOSType, name: String, comparisonOptions options: NSString.CompareOptions = []) throws -> Data {
		for rezes in resources {
			if rezes.type == res_type {
				for resource in rezes.list {
					if resource.name.compare(name, options: options) == .orderedSame {
						if let data = resource.data {
							return data
						}
						
						try loadData(resource)
						
						guard let resDat = resource.data else {
							throw Errors.couldNotOpenResource
						}
						return resDat
					}
				}
			}
		}
		
		throw Errors.couldNotFindResourceTypeName(type: res_type, name: name)
	}
	
	deinit {
		if filep != nil {
			fclose(filep);
		}
	}
}
