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


/// The actual resources in the resource fork
struct Mac_ResData {
	var length: UInt32
	var data: UnsafeMutablePointer<UInt8>
	
	var dataArray: Array<UInt8> {
		return Array(UnsafeMutableBufferPointer(start: data, count: Int(length)))
	}
}

class Mac_Resource {
	
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

	
	init() {
		
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
vsprintf(errbuf, fmt, ap);
va_end(ap);
errstr = errbuf;
}
char *errstr;
char  errbuf[BUFSIZ];
};
*/
