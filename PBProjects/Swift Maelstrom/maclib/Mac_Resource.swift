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


private func ==(lhs: Mac_Resource.Resource, rhs: Mac_Resource.Resource) -> Bool {
	return lhs.id == rhs.id
}

private func <(lhs: Mac_Resource.Resource, rhs: Mac_Resource.Resource) -> Bool {
	return lhs.id < rhs.id
}

@inline(__always) internal func bytesex32(inout x: UInt32) -> UInt32 {
	x = x.bigEndian
	return x
}

@inline(__always) internal func bytesex32(inout x: Int32) -> Int32 {
	x = x.bigEndian
	return x
}


@inline(__always) internal func bytesex16(inout x: UInt16) -> UInt16 {
	x = x.bigEndian
	return x
}

@inline(__always) internal func bytesex16(inout x: Int16) -> Int16 {
	x = x.bigEndian
	return x
}

/** Swap bytes from big-endian to this machine's type.
The input data is assumed to be always in big-endian format.
*/
@inline(__always) internal func byteswap(var array: UnsafeMutablePointer<UInt16>, var count nshorts: Int) {
	for ; nshorts-- > 0; array++ {
		bytesex16(&array.memory)
	}
}

/** Here's an iterator to find heuristically (I've always wanted to use that
word :-) a macintosh resource fork from a general mac name.

This function may be overkill, but I want to be able to find any Macintosh
resource fork, darn it! :)
*/
private func checkAppleFile(resfile: UnsafeMutablePointer<FILE>, inout resbase: Int) {
	var header = AppleSingleHeader()
	if fread(&header.magicNum, sizeof(UInt32), 1, resfile) != 0 && bytesex32(&header.magicNum) == APPLEDOUBLE_MAGIC {
		fread(&header.versionNum,
			sizeofValue(header.versionNum), 1, resfile);
		bytesex32(&header.versionNum);
		fread(&header.filler,
			sizeofValue(header.filler), 1, resfile);
		fread(&header.numEntries,
			sizeofValue(header.numEntries), 1, resfile);
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
			if fread(&entry, sizeofValue(entry), 1, resfile) == 0 {
				break;
			}
			bytesex32(&entry.entryIDValue);
			bytesex32(&entry.entryOffset);
			bytesex32(&entry.entryLength);
			#if APPLEDOUBLE_DEBUG
				print(String(format: "Entry (%d): ID = 0x%.8x, Offset = %d, Length = %d",
					i+1, entry.entryID, entry.entryOffset, entry.entryLength))
			#endif
			if entry.entryID == .Resource {
				resbase = Int(entry.entryOffset)
				break;
			}
		}
	}
	
	fseek(resfile, 0, SEEK_SET)
}

private func checkMacBinary(resfile: UnsafeMutablePointer<FILE>, inout resbase: Int) {
	var header = MBHeader()
	if fread(&header, sizeof(MBHeader), 1, resfile) != 0 && (header.version & MACBINARY_MASK) == MACBINARY_MAGIC {
		resbase = sizeof(MBHeader) + Int(header.dataLength)
	}
	fseek(resfile, 0, SEEK_SET)
}


private func openMacRes(inout original: NSURL, inout resbase: Int) -> UnsafeMutablePointer<FILE> {
	var resfile: UnsafeMutablePointer<FILE> = nil
	let directory = original.URLByDeletingLastPathComponent
	var filename = original.lastPathComponent!
	var newURL: NSURL?
	
	func urlByAddingPath(aPath: String) -> NSURL {
		if let directory = directory {
			return directory.URLByAppendingPathComponent(aPath)
		}
		return NSURL(fileURLWithPath: aPath)
	}
	
	struct searchnreplace {
		var search: Character
		var replace: Character
	}
	let snr = [searchnreplace(search: "\0", replace: "\0"),
	searchnreplace(search: " ", replace: "_")]
	
	var iterations = 0
	
	for iterations = 0; iterations < snr.count; iterations++ {
		/* Translate ' ' into '_', etc */
		/* Note that this translation is irreversible */
		filename.replaceAllInstancesOfCharacter(snr[iterations].search, withCharacter: snr[iterations].replace)
		
		/* First look for Executor (tm) resource forks */
		var newName = "%\(filename)"
		newURL = urlByAddingPath(newName)
		resfile = fopen(newURL!.fileSystemRepresentation, "rb")
		guard resfile == nil else {
			break
		}
		
		newURL = nil
		
		/* Look for MacBinary files */
		newName = (filename as NSString).stringByAppendingPathExtension("bin")!
		newURL = urlByAddingPath(newName)
		resfile = fopen(newURL!.fileSystemRepresentation, "rb")
		guard resfile == nil else {
			break
		}
		
		newURL = nil

		/* Look for OS X-style metadata: it might have a resource fork */
		newName = "._\(filename)"
		newURL = urlByAddingPath(newName)
		resfile = fopen(newURL!.fileSystemRepresentation, "rb")
		if resfile != nil {
			//Be a bit more strict when looking for resources in OS X metadata.
			//Simply put, it might not have a resource fork.
			var resbase2 = 0
			checkAppleFile(resfile, resbase: &resbase2)
			guard resbase2 != 0 else {
				break
			}
		}
		
		newURL = nil
		
		/* Look for raw resource fork.. */
		newName = filename
		newURL = urlByAddingPath(newName)
		resfile = fopen(newURL!.fileSystemRepresentation, "rb")
		guard resfile == nil else {
			break
		}
		
		/* Look for actual resource fork on OS X */
		resfile = fileFromResourceFork(newURL!)
		guard resfile == nil else {
			break
		}
		
		newURL = nil
	}
	
	/* Did we find anything? */
	if iterations != snr.count {
		original = newURL!
		resbase = 0
		
		/* Look for AppleDouble format header */
		checkAppleFile(resfile, resbase: &resbase)
		
		/* Look for MacBinary format header */
		checkMacBinary(resfile, resbase: &resbase)
	}
	#if APPLEDOUBLE_DEBUG
		print(String(format: "Resfile base = %d", *resbase))
	#endif

	return resfile
}

// MARK: - These are the data structures that make up the Macintosh Resource Fork
private struct Resource_Header {
	///Offset of resources in file
	var res_offset: UInt32
	///Offset of resource map in file
	var map_offset: UInt32
	///Length of the resource data
	var res_length: UInt32
	///Length of the resource map
	var map_length: UInt32
	
	init() {
		res_offset = 0
		map_offset = 0
		res_length = 0
		map_length = 0
	}
}

private struct Resource_Data {
	///Length of the resources data
	var Data_length: UInt32
	#if SHOW_VARLENGTH_FIELDS
	///The Resource Data
	var Data: [UInt8]
	#endif
	
	init() {
		Data_length = 0
	}
};

private struct Type_entry {
	///Resource type
	var Res_type: MaelOSType
	///number of this type resources in map - 1
	var Num_rez: UInt16
	/** Offset from type list, of reference
	list for this type */
	var Ref_offset: UInt16
	
	init() {
		Res_type = MaelOSType()
		Num_rez = 0
		Ref_offset = 0
	}
};

private struct Ref_entry {
	///The ID for this resource
	var Res_id: UInt16
	/** Offset in name list of resource
	name, or -1 if no name */
	var Name_offset: UInt16
	///Resource attributes
	var Res_attrs: UInt8
	///3-byte offset from Resource data
	var Res_offset: (UInt8, UInt8, UInt8)
	///Reserved for use in-core
	var Reserved: UInt32
	
	init() {
		Res_id = 0
		Name_offset = 0
		Res_attrs = 0
		Res_offset = (0,0,0)
		Reserved = 0
	}
};

private struct Name_entry {
	///Length of the following name
	var Name_len: UInt8
	#if SHOW_VARLENGTH_FIELDS
	/// Variable length resource name
	var name: (UInt8)
	#endif
};

private struct Resource_Map {
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

class Mac_Resource {
	enum Errors: ErrorType {
		case FileNotFound
		case CouldNotOpenResource
		case CouldNotFindResourceType(type: MaelOSType)
		case CouldNotFindResourceTypeID(type: MaelOSType, id: UInt16)
		case CouldNotFindResourceTypeName(type: MaelOSType, name: String)
		case CouldNotReadData
	}
	
	/// The Resource Fork File
	private var filep: UnsafeMutablePointer<FILE> = nil
	/// The offset of the rsrc
	private var base = 0

	/// Offset of Resource data in resource fork
	private var res_offset: UInt32 = 0
	/// Number of types of resources
	private var num_types: UInt16 = 0

	private var resources = [ResourceList]()
	
	private(set) var errstr: String?
	
	private final class Resource: Comparable {
		let name: String
		let id: UInt16
		let offset: UInt32
		private(set) var data: NSData? = nil
		
		private init(entry ref_ent: Ref_entry, name: String) {
			offset =
				((UInt32(ref_ent.Res_offset.0)<<16) |
					(UInt32(ref_ent.Res_offset.1)<<8) |
					UInt32(ref_ent.Res_offset.2));
			id = ref_ent.Res_id;
			self.name = name
		}
	}

	private final class ResourceList {
		var type: MaelOSType
		private var intCount: UInt16
		private(set) var list = [Resource]()
		
		private init(entry: Type_entry) {
			type = entry.Res_type
			intCount = entry.Num_rez
		}
	}
	
	convenience init(filename: String) throws {
		try self.init(fileURL: NSURL(fileURLWithPath: filename))
	}
	
	init(fileURL: NSURL) throws {
		var filename = fileURL
		var header = Resource_Header()
		var resMap = Resource_Map()
		var typeEnt = Type_entry()
		//Uint16                *ref_offsets;
		var name_len: UInt8 = 0
		//int i, n;
		
		/* Clear out any variables */
		resources = []
		
		/* Try to open the Macintosh resource fork */
		errstr = nil;
		filep = openMacRes(&filename, resbase: &base)
		guard filep != nil else {
			throw Errors.FileNotFound
			//error("Couldn't open resource file '%@'", filename);
		}
		fseek(filep, base, SEEK_SET);
		
		guard fread(&header, sizeofValue(header), 1, filep) != 0 else {
			throw Errors.CouldNotOpenResource
			//error("Couldn't read resource info from '%s'", filename);
		}
		bytesex32(&header.res_length);
		bytesex32(&header.res_offset);
		res_offset = header.res_offset;
		bytesex32(&header.map_length);
		bytesex32(&header.map_offset);
		
		fseek(filep, base+Int(header.map_offset), SEEK_SET);
		guard fread(&resMap, sizeofValue(resMap), 1, filep) != 0 else {
			throw Errors.CouldNotOpenResource
			//error("Couldn't read resource info from '%s'", filename);
		}
		bytesex16(&resMap.types_offset);
		bytesex16(&resMap.names_offset);
		bytesex16(&resMap.num_types);
		resMap.num_types += 1;	/* Value in fork is one short */
		
		/* Fill in our class members */
		num_types = resMap.num_types;
		
		var ref_offsets = [UInt16](count: Int(num_types), repeatedValue: 0)
		fseek(filep, base+Int(header.map_offset)+Int(resMap.types_offset)+2, SEEK_SET)
		for _ in 0..<num_types {
			guard fread(&typeEnt, sizeofValue(typeEnt), 1, filep) != 0 else {
				throw Errors.CouldNotOpenResource
			}
			
			bytesex16(&typeEnt.Num_rez);
			bytesex16(&typeEnt.Ref_offset);
			typeEnt.Num_rez += 1;	/* Value in fork is one short */
			typeEnt.Res_type.rawOSType = typeEnt.Res_type.rawOSType.bigEndian
			resources.append(ResourceList(entry: typeEnt))
			ref_offsets.append(typeEnt.Ref_offset)
		}
		
		for (i, aRes) in resources.enumerate() {
			fseek(filep,
				base + Int(header.map_offset) + Int(resMap.types_offset) + Int(ref_offsets[i]),
				SEEK_SET);
			for _ in 0..<Int(aRes.intCount) {
				var ref_ent = Ref_entry()
				
				guard fread(&ref_ent, sizeofValue(ref_ent), 1, filep) != 0 else {
					throw Errors.CouldNotOpenResource
				}
				
				bytesex16(&ref_ent.Res_id)
				bytesex16(&ref_ent.Name_offset)
				
				var entName: String
				/* Grab the name, while we're here... */
				if ( ref_ent.Name_offset == 0xFFFF ) {
					entName = ""
				} else {
					let cur_offset = ftell(filep);
					fseek(filep,
						base+Int(header.map_offset)+Int(resMap.names_offset)+Int(ref_ent.Name_offset),
						SEEK_SET);
					fread(&name_len, 1, 1, filep);
					var aCharName = [UInt8](count: Int(name_len), repeatedValue: 0)
					fread(&aCharName,
						1, Int(name_len), filep);
					if let nsName = NSString(bytes: aCharName, length: aCharName.count, encoding: NSMacOSRomanStringEncoding) as String? {
						entName = nsName
					} else {
						entName = "Encoding failure!"
					}
					fseek(filep, cur_offset, SEEK_SET);
				}
				
				let aPart = Resource(entry: ref_ent, name: entName)
				aRes.list.append(aPart)
			}
			aRes.list.sortInPlace(>)
		}
	}
	
	/** Create a set of resource types in this file */
	var types: Set<MaelOSType> {
		var toRet = Set<MaelOSType>()
		for res in resources {
			toRet.insert(res.type)
		}
		return toRet
	}

	/** Return the number of resources of the given type */
	func countOfResources(type type: MaelOSType) -> Int {
		for res in resources {
			if res.type == type {
				return res.list.count
			}
		}
		
		return 0
	}
	
	/** Create an array of resource ids for a type */
	func resourceIDs(type type: MaelOSType) throws -> [UInt16] {
		var toRet = [UInt16]()
		for aRes in resources {
			if aRes.type == type {
				for aTyp in aRes.list {
					toRet.append(aTyp.id)
				}
				return toRet.sort(>)
			}
		}
		throw Errors.CouldNotFindResourceType(type: type)
	}

	func nameOfResource(type type: MaelOSType, id: UInt16) throws -> String {
		for res in resources {
			if res.type == type {
				for aTyp in res.list {
					if aTyp.id == id {
						return aTyp.name
					}
				}
			}
		}
		throw Errors.CouldNotFindResourceTypeID(type: type, id: id)
	}

	private func loadData(resource: Resource) throws {
		fseek(filep, base+Int(res_offset + resource.offset), SEEK_SET);
		
		var len: UInt32 = 0
		fread(&len, 4, 1, filep);
		len = len.bigEndian
		guard let d = NSMutableData(length: Int(len)) else {
			fatalError("Out of memory?")
		}
		guard fread(d.mutableBytes, Int(len), 1, filep) != 0 else {
			throw Errors.CouldNotReadData
		}
		resource.data = NSData(data: d)
	}
	
	/// Return a resource of a certain type and id.
	func resource(type res_type: MaelOSType, id: UInt16) throws -> NSData {
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
		
		throw Errors.CouldNotFindResourceTypeID(type: res_type, id: id)
	}
	
	/// Return a resource of a certain type and name.
	func resource(type res_type: MaelOSType, name: String, comparisonOptions options: NSStringCompareOptions = []) throws -> NSData {
		for rezes in resources {
			if rezes.type == res_type {
				for resource in rezes.list {
					if resource.name.compare(name, options: options) == .OrderedSame {
						if let data = resource.data {
							return data
						}
						
						try loadData(resource)
						
						return resource.data!
					}
				}
			}
		}
		
		throw Errors.CouldNotFindResourceTypeName(type: res_type, name: name)
	}
	
	deinit {
		if filep != nil {
			fclose(filep);
		}
	}
}

