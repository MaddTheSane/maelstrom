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


func ==(lhs: Mac_Resource.Resource, rhs: Mac_Resource.Resource) -> Bool {
	return lhs.id == rhs.id
}

func <(lhs: Mac_Resource.Resource, rhs: Mac_Resource.Resource) -> Bool {
	return lhs.id < rhs.id
}

private func bytesex32(inout x: UInt32) -> UInt32 {
	x = x.bigEndian
	return x
}

private func bytesex32(inout x: Int32) -> Int32 {
	x = x.bigEndian
	return x
}


private func bytesex16(inout x: UInt16) -> UInt16 {
	x = x.bigEndian
	return x
}

private func bytesex16(inout x: Int16) -> Int16 {
	x = x.bigEndian
	return x
}

/** Here's an iterator to find heuristically (I've always wanted to use that
word :-) a macintosh resource fork from a general mac name.

This function may be overkill, but I want to be able to find any Macintosh
resource fork, darn it! :)
*/
private func checkAppleFile(resfile: UnsafeMutablePointer<FILE>, inout resbase: UInt32) {
	var header = ASHeader()
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
		
		var entry = ASEntry()
		
		#if APPLEDOUBLE_DEBUG
			print(String(format: "Number of entries: %d, sizeof(entry) = %d",
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
				resbase = entry.entryOffset;
				break;
			}
		}
	}
	
	fseek(resfile, 0, SEEK_SET)
}

private func checkMacBinary(resfile: UnsafeMutablePointer<FILE>, inout resbase: UInt32) {
	var header = MBHeader()
	if fread(&header, sizeof(MBHeader), 1, resfile) != 0 && (header.version & MACBINARY_MASK) == MACBINARY_MAGIC {
		resbase = UInt32(sizeof(MBHeader)) + header.dataLength
	}
	fseek(resfile, 0, SEEK_SET)
}


private func openMacRes(inout original: NSURL, inout resbase: UInt32) -> UnsafeMutablePointer<FILE> {
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
		if snr[iterations].replace != "\0" {
			filename.replaceAllInstancesOfCharacter(snr[iterations].search, withCharacter: snr[iterations].replace)
		}
		//filename
		
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

		/* Look for raw resource fork.. */
		newName = filename
		newURL = urlByAddingPath(newName)
		resfile = fopen(newURL!.fileSystemRepresentation, "rb")
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
	var Res_type: OSType
	///# this type resources in map - 1
	var Num_rez: UInt16
	/** Offset from type list, of reference
	list for this type */
	var Ref_offset: UInt16
	
	init() {
		Res_type = 0
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
}


/// The actual resources in the resource fork
struct Mac_ResData {
	var length: UInt32
	var data: UnsafeMutablePointer<UInt8>

	var dataArray: Array<UInt8> {
		return Array(UnsafeMutableBufferPointer(start: data, count: Int(length)))
	}
	
	var dataObject: NSData {
		if length == 0 {
			return NSData()
		}
		return NSData(bytes: data, length: Int(length))
	}
}

class Mac_Resource {
	/// The Resource Fork File
	private var filep: UnsafeMutablePointer<FILE> = nil
	/// The offset of the rsrc
	private var base = 0

	/// Offset of Resource data in resource fork
	private var res_offset: UInt32 = 0
	/// Number of types of resources
	private var num_types: UInt16 = 0

	private var resources = [ResourceList]()
	
	struct Resource: Comparable {
		var name: String
		var id: UInt16
		var offset: UInt32
		var data: Mac_ResData
	};

	struct ResourceList {
		var type: OSType
		var count: UInt16
		var list: [Resource]
	};

	
	convenience init(filename: String) {
		self.init(fileURL: NSURL(fileURLWithPath: filename))
	}
	
	init(fileURL: NSURL) {
		
	}
	/** Create a set of resource types in this file */
	var types: Set<OSType> {
		return []
	}

	/** Return the number of resources of the given type */
	func numberOfResources(type type: OSType) -> UInt16 {
		return 0
	}
	
	/** Create an array of resource ids for a type */
	func resourceIDs(type type: OSType) -> [UInt16] {
		return []
	}

	
	deinit {
		if filep != nil {
			fclose(filep);
		}
	}
}

/*

class Mac_Resource {
public:
	Mac_Resource(const char *filename);
	~Mac_Resource();

	/* Create a NULL terminated list of resource types in this file */
	char  **Types(void);

	/* Return the number of resources of the given type */
	Uint16  NumResources(const char *res_type);

	/* Create a 0xFFFF terminated list of resource ids for a type */
	Uint16 *ResourceIDs(const char *res_type);

	/* Return a resource of a certain type and id.  These resources
	   are deleted automatically when Mac_Resource object is deleted.
	 */
	char   *ResourceName(const char *res_type, Uint16 id);
	Mac_ResData *Resource(const char *res_type, Uint16 id);
	Mac_ResData *Resource(const char *res_type, const char *name);

	/* This returns a more detailed error message, or NULL */
	char *Error(void) {
		return(errstr);
	}

protected:
	friend int Res_cmp(const void *A, const void *B);

	/* Offset of Resource data in resource fork */
	Uint32 res_offset;
	Uint16 num_types;		/* Number of types of resources */

	struct resource {
		char  *name;
		Uint16 id;
		Uint32 offset;
		Mac_ResData *data;
	};

	struct resource_list {
		char   type[5];			/* Four character type + nul */
		Uint16 count;
		struct resource *list;
	} *Resources;

	FILE   *filep;				/* The Resource Fork File */
	Uint32  base;				/* The offset of the rsrc */

	/* Useful for getting error feedback */
	void error(const char *fmt, ...) {
		va_list ap;

		va_start(ap, fmt);
		vsnprintf(errbuf, sizeof(errbuf), fmt, ap);
		va_end(ap);
		errstr = errbuf;
	}
	char *errstr;
	char  errbuf[BUFSIZ];
};
*/

/*
/* These are the data structures that make up the Macintosh Resource Fork */
struct Resource_Header {
	Uint32	res_offset;	/* Offset of resources in file */
	Uint32	map_offset;	/* Offset of resource map in file */
	Uint32	res_length;	/* Length of the resource data */
	Uint32	map_length;	/* Length of the resource map */
};

struct Resource_Data {
	Uint32	Data_length;	/* Length of the resources data */
#ifdef SHOW_VARLENGTH_FIELDS
	Uint8	Data[0];	/* The Resource Data */
#endif
};

struct Type_entry {
	char	Res_type[4];	/* Resource type */
	Uint16	Num_rez;	/* # this type resources in map - 1 */
	Uint16	Ref_offset;	/* Offset from type list, of reference
				   list for this type */
};

struct Ref_entry {
	Uint16	Res_id;		/* The ID for this resource */
	Uint16	Name_offset;	/* Offset in name list of resource
				   name, or -1 if no name */
	Uint8	Res_attrs;	/* Resource attributes */
	Uint8	Res_offset[3];	/* 3-byte offset from Resource data */
	Uint32	Reserved;	/* Reserved for use in-core */
};

struct Name_entry {
	Uint8	Name_len;	/* Length of the following name */
#ifdef SHOW_VARLENGTH_FIELDS
	Uint8	name[0];	/* Variable length resource name */
#endif
	};

struct Resource_Map {
	Uint8	Reserved[22];	/* Reserved for use in-core */
	Uint16	Map_attrs;	/* Map attributes */
	Uint16	types_offset;	/* Offset of resource type list */
	Uint16  names_offset;	/* Offset of resource name list */
	Uint16	num_types;	/* # of types in map - 1 */
#ifdef SHOW_VARLENGTH_FIELDS
	struct Type_entry  types[0];	 /* Variable length types list */
	struct Ref_entry   refs[0];	 /* Variable length reference list */
	struct Name_entry  names[0];	 /* Variable length name list */
#endif
	};

int Res_cmp(const void *A, const void *B)
{
	struct Mac_Resource::resource *a, *b;

	a=(struct Mac_Resource::resource *)A;
	b=(struct Mac_Resource::resource *)B;

	if ( a->id > b->id )
		return(1);
	else if ( a->id < b->id )
		return(-1);
	else /* They are equal?? */
		return(0);
}

/* Here's an iterator to find heuristically (I've always wanted to use that
   word :-) a macintosh resource fork from a general mac name.

   This function may be overkill, but I want to be able to find any Macintosh
   resource fork, darn it! :)
*/
static void CheckAppleFile(FILE *resfile, Uint32 *resbase)
{
	ASHeader header;
	if (fread(&header.magicNum,sizeof(header.magicNum),1,resfile)&&
		(bytesex32(header.magicNum) == APPLEDOUBLE_MAGIC) ) {
		fread(&header.versionNum,
				sizeof(header.versionNum), 1, resfile);
		bytesex32(header.versionNum);
		fread(&header.filler,
				sizeof(header.filler), 1, resfile);
		fread(&header.numEntries,
				sizeof(header.numEntries), 1, resfile);
		bytesex16(header.numEntries);
#ifdef APPLEDOUBLE_DEBUG
mesg("Header magic: 0x%.8x, version 0x%.8x\n",
			header.magicNum, header.versionNum);
#endif

		ASEntry entry;
#ifdef APPLEDOUBLE_DEBUG
mesg("Number of entries: %d, sizeof(entry) = %d\n",
			header.numEntries, sizeof(entry));
#endif
		for ( int i = 0; i<header.numEntries; ++ i ) {
			if (! fread(&entry, sizeof(entry), 1, resfile))
				break;
			bytesex32(entry.entryID);
			bytesex32(entry.entryOffset);
			bytesex32(entry.entryLength);
#ifdef APPLEDOUBLE_DEBUG
mesg("Entry (%d): ID = 0x%.8x, Offset = %d, Length = %d\n",
	i+1, entry.entryID, entry.entryOffset, entry.entryLength);
#endif
			if ( entry.entryID == AS_RESOURCE ) {
				*resbase = entry.entryOffset;
				break;
			}
		}
	}
	fseek(resfile, 0, SEEK_SET);
}
static void CheckMacBinary(FILE *resfile, Uint32 *resbase)
{
	MBHeader header;
	if (fread(header.data,sizeof(header.data),1,resfile)&&
		((header.Version()&MACBINARY_MASK) == MACBINARY_MAGIC) ) {
		*resbase = sizeof(header.data) + header.DataLength();
	}
	fseek(resfile, 0, SEEK_SET);
}
static FILE *Open_MacRes(char **original, Uint32 *resbase)
{
	char *filename, *basename, *ptr, *newname;
	const char *dirname;
	FILE *resfile=NULL;

	/* Search and replace characters */
	const int N_SNRS = 2;
	struct searchnreplace {
		char search;
		char replace;
	} snr[N_SNRS] = {
		{ '\0',	'\0' },
		{ ' ',	'_' },
	};
	int iterations=0;

	/* Separate the Mac name from a UNIX path */
	filename = new char[strlen(*original)+1];
	strcpy(filename, *original);
	if ( (basename=strrchr(filename, '/')) != NULL ) {
		dirname = filename;
		*(basename++) = '\0';
	} else {
		dirname = "";
		basename = filename;
	}

	for ( iterations=0; iterations < N_SNRS; ++iterations ) {
		/* Translate ' ' into '_', etc */
		/* Note that this translation is irreversible */
		for ( ptr = basename; *ptr; ++ptr ) {
			if ( *ptr == snr[iterations].search )
				*ptr = snr[iterations].replace;
		}

		/* First look for Executor (tm) resource forks */
		newname = new char[strlen(dirname)+2+1+strlen(basename)+1];
		sprintf(newname, "%s%s%%%s", dirname, (*dirname ? "/" : ""),
								basename);
		if ( (resfile=fopen(newname, "rb")) != NULL ) {
			break;
		}
		delete[] newname;

		/* Look for MacBinary files */
		newname = new char[strlen(dirname)+2+strlen(basename)+4+1];
		sprintf(newname, "%s%s%s.bin", dirname, (*dirname ? "/" : ""),
								basename);
		if ( (resfile=fopen(newname, "rb")) != NULL ) {
			break;
		}
		delete[] newname;

		/* Look for raw resource fork.. */
		newname = new char[strlen(dirname)+2+strlen(basename)+1];
		sprintf(newname, "%s%s%s", dirname, (*dirname ? "/" : ""),
								basename);
		if ( (resfile=fopen(newname, "rb")) != NULL ) {
			break;
		}
	}
	/* Did we find anything? */
	if ( iterations != N_SNRS ) {
		*original = newname;
		*resbase = 0;

		/* Look for AppleDouble format header */
		CheckAppleFile(resfile, resbase);

		/* Look for MacBinary format header */
		CheckMacBinary(resfile, resbase);
	}
#ifdef APPLEDOUBLE_DEBUG
mesg("Resfile base = %d\n", *resbase);
#endif
	delete[] filename;
	return(resfile);
}

Mac_Resource:: Mac_Resource(const char *file)
{
	char *filename = (char *)file;
	struct Resource_Header Header;
	struct Resource_Map    Map;
	struct Type_entry      type_ent;
	struct Ref_entry       ref_ent;
	Uint16                *ref_offsets;
	Uint8                  name_len;
	unsigned long          cur_offset;
	int i, n;

	/* Clear out any variables */
	Resources = NULL;

	/* Try to open the Macintosh resource fork */
	errstr = NULL;
	if ( (filep=Open_MacRes(&filename, &base)) == NULL ) {
		error("Couldn't open resource file '%s'", filename);
		return;
	} else {
		/* Open_MacRes() passes back the real name of resource file */
		delete[] filename;
	}
	fseek(filep, base, SEEK_SET);

	if ( ! fread(&Header, sizeof(Header), 1, filep) ) {
		error("Couldn't read resource info from '%s'", filename);
		return;
	}
	bytesex32(Header.res_length);
	bytesex32(Header.res_offset);
	res_offset = Header.res_offset;
	bytesex32(Header.map_length);
	bytesex32(Header.map_offset);

	fseek(filep, base+Header.map_offset, SEEK_SET);
	if ( ! fread(&Map, sizeof(Map), 1, filep) ) {
		error("Couldn't read resource info from '%s'", filename);
		return;
	}
	bytesex16(Map.types_offset);
	bytesex16(Map.names_offset);
	bytesex16(Map.num_types);
	Map.num_types += 1;	/* Value in fork is one short */

	/* Fill in our class members */
	num_types = Map.num_types;
	Resources = new struct resource_list[num_types];
	for ( i=0; i<num_types; ++i )
		Resources[i].list = NULL;

	ref_offsets = new Uint16[num_types];
	fseek(filep, base+Header.map_offset+Map.types_offset+2, SEEK_SET);
	for ( i=0; i<num_types; ++i ) {
		if ( ! fread(&type_ent, sizeof(type_ent), 1, filep) ) {
			error("Couldn't read resource info from '%s'",
								filename);
			delete[] ref_offsets;
			return;
		}
		bytesex16(type_ent.Num_rez);
		bytesex16(type_ent.Ref_offset);
		type_ent.Num_rez += 1;	/* Value in fork is one short */

		strncpy(Resources[i].type, type_ent.Res_type, 4);
		Resources[i].type[4] = '\0';
		Resources[i].count   = type_ent.Num_rez;
		Resources[i].list = new struct resource[Resources[i].count];
		for ( n=0; n<Resources[i].count; ++n ) {
			Resources[i].list[n].name = NULL;
			Resources[i].list[n].data = NULL;
		}
		ref_offsets[i] = type_ent.Ref_offset;
	}

	for ( i=0; i<num_types; ++i ) {
		fseek(filep, 
		base+Header.map_offset+Map.types_offset+ref_offsets[i],
								SEEK_SET);
		for ( n=0; n<Resources[i].count; ++n ) {
			if ( ! fread(&ref_ent, sizeof(ref_ent), 1, filep) ) {
				error("Couldn't read resource info from '%s'",
								filename);
				delete[] ref_offsets;
				return;
			}
			bytesex16(ref_ent.Res_id);
			bytesex16(ref_ent.Name_offset);
			Resources[i].list[n].offset = 
					((ref_ent.Res_offset[0]<<16) |
                                         (ref_ent.Res_offset[1]<<8) |
                                         (ref_ent.Res_offset[2]));
			Resources[i].list[n].id = ref_ent.Res_id;

			/* Grab the name, while we're here... */
			if ( ref_ent.Name_offset == 0xFFFF ) {
				Resources[i].list[n].name = new char[1];
				Resources[i].list[n].name[0] = '\0';
			} else {
				cur_offset = ftell(filep);
				fseek(filep, 
		base+Header.map_offset+Map.names_offset+ref_ent.Name_offset,
								SEEK_SET);
				fread(&name_len, 1, 1, filep);
				Resources[i].list[n].name=new char[name_len+1];
				fread(Resources[i].list[n].name,
							1, name_len, filep);
				Resources[i].list[n].name[name_len] = '\0';
				fseek(filep, cur_offset, SEEK_SET);
			}
		}
#ifndef macintosh
		/* Sort the resources in ascending order. :) */
		qsort(Resources[i].list,Resources[i].count,
					sizeof(struct resource), Res_cmp);
#endif
	}
	delete[] ref_offsets;
}

Mac_Resource:: ~Mac_Resource()
{
	if ( filep )
		fclose(filep);

	if ( ! Resources )
		return;
	for ( int i=0; i<num_types; ++i ) {
		if ( ! Resources[i].list )
			continue;
		for ( int n=0; n<Resources[i].count; ++n ) {
			if ( Resources[i].list[n].name )
				delete[] Resources[i].list[n].name;
			if ( Resources[i].list[n].data ) {
				delete[] Resources[i].list[n].data->data;
				delete Resources[i].list[n].data;
			}
		}
		delete[] Resources[i].list;
	}
	delete[] Resources;
}

char **
Mac_Resource:: Types(void)
{
	int i;
	char **types;

	types = new char *[num_types+1];
	for ( i=0; i<num_types; ++i )
		types[i] = Resources[i].type;
	types[i] = NULL;
	return(types);
}

Uint16
Mac_Resource:: NumResources(const char *res_type)
{
	int i;

	for ( i=0; i<num_types; ++i ) {
		if ( strncmp(res_type, Resources[i].type, 4) == 0 )
			return(Resources[i].count);
	}
	return(0);
}

Uint16 *
Mac_Resource:: ResourceIDs(const char *res_type)
{
	int i, n;
	Uint16 *ids;

	for ( i=0; i<num_types; ++i ) {
		if ( strncmp(res_type, Resources[i].type, 4) == 0 ) {
			ids = new Uint16[Resources[i].count+1];
			for ( n=0; n<Resources[i].count; ++n )
				ids[n] = Resources[i].list[n].id;
			ids[n] = 0xFFFF;
			return(ids);
		}
	}
	error("Couldn't find resources of type '%s'", res_type);
	return(NULL);
}

char *
Mac_Resource:: ResourceName(const char *res_type, Uint16 id)
{
	int i, n;

	for ( i=0; i<num_types; ++i ) {
		if ( strncmp(res_type, Resources[i].type, 4) == 0 ) {
			for ( n=0; n<Resources[i].count; ++n ) {
				if ( id == Resources[i].list[n].id )
					return(Resources[i].list[n].name);
			}
		}
	}
	error("Couldn't find resource of type '%s', id %hu", res_type, id);
	return(NULL);
}

Mac_ResData *
Mac_Resource:: Resource(const char *res_type, Uint16 id)
{
	int i, n;
	Mac_ResData *d;

	for ( i=0; i<num_types; ++i ) {
		if ( strncmp(res_type, Resources[i].type, 4) == 0 ) {
			for ( n=0; n<Resources[i].count; ++n ) {
				if ( id == Resources[i].list[n].id ) {
					/* Is it already loaded? */
					d = Resources[i].list[n].data;
					if ( d )
						return(d);

					/* Load it */
					d = new Mac_ResData;
					fseek(filep, base+res_offset+Resources[i].list[n].offset, SEEK_SET);
					fread(&d->length, 4, 1, filep);
					bytesex32(d->length);
					d->data = new Uint8[d->length];
					if (!fread(d->data,d->length,1,filep)) {
						delete[] d->data;
						error("Couldn't read %d bytes", d->length);
						delete d;
						return(NULL);
					}
					Resources[i].list[n].data = d;
					return(d);
				}
			}
		}
	}
	error("Couldn't find resource of type '%s', id %hu", res_type, id);
	return(NULL);
}

Mac_ResData *
Mac_Resource:: Resource(const char *res_type, const char *name)
{
	int i, n;
	Mac_ResData *d;

	for ( i=0; i<num_types; ++i ) {
		if ( strncmp(res_type, Resources[i].type, 4) == 0 ) {
			for ( n=0; n<Resources[i].count; ++n ) {
				if (strcmp(name, Resources[i].list[n].name)==0){
					/* Is it already loaded? */
					d = Resources[i].list[n].data;
					if ( d )
						return(d);

					/* Load it */
					d = new Mac_ResData;
					fseek(filep, base+res_offset+Resources[i].list[n].offset, SEEK_SET);
					fread(&d->length, 4, 1, filep);
					bytesex32(d->length);
					d->data = new Uint8[d->length];
					if (!fread(d->data,d->length,1,filep)) {
						delete[] d->data;
						error("Couldn't read %d bytes", d->length);
						delete d;
						return(NULL);
					}
					Resources[i].list[n].data = d;
					return(d);
				}
			}
		}
	}
	error("Couldn't find resource of type '%s', name %s", res_type, name);
	return(NULL);
}
*/
