//
//  applefile.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/1/15.
//
//

import Foundation

/// spot in QuickDraw 2-D grid
///
/// In the QuickDraw coordinate plane, each coordinate is
/// `-32767..32767`. Each point is at the intersection of a
/// horizontal grid line and a vertical grid line.  Horizontal
/// coordinates increase from left to right. Vertical
/// coordinates increase from top to bottom. This is the way
/// both a TV screen and page of English text are scanned:
/// from top left to bottom right.
struct Point
{
	/// vertical coordinate
	var v: Int16
	
	/// horizontal coordinate
	var h: Int16
}

/* See older Inside Macintosh, Volume II page 84 or Volume IV
* page 104.
*/

/// Finder information
struct FInfo {
	/// File type, 4 ASCII chars
	var fdType: OSType
	/// File's creator, 4 ASCII chars
	var fdCreator: OSType
	/// Finder flag bits
	var fdFlags: FinderFlags
	/// file's location in folder
	var fdLocation: Point
	/// file 's folder (aka window)
	var fdFldr: Int16
}

/// Masks for finder flag bits (field `fdFlags` in struct
/// `FInfo`).
struct FinderFlags: OptionSetType {
	let rawValue: UInt16
	init(rawValue rv: UInt16) {
		rawValue = rv
	}
	
	/// file is on desktop (HFS only)
	static let OnDesktop = FinderFlags(rawValue: 0x0001)
	/// color coding (3 bits)
	static let MaskColor = FinderFlags(rawValue: 0x000E)
	/// reserved (System 7)
	static let SwitchLaunch = FinderFlags(rawValue: 0x0020)
	/// appl available to multiple users
	static let Shared = FinderFlags(rawValue: 0x0040)
	/// file contains no INIT resources
	static let NoINITs = FinderFlags(rawValue: 0x0080)
	/// Finder has loaded bundle res.
	static let BeenInited = FinderFlags(rawValue: 0x0100)
	/// file contains custom icon
	static let CustomIcom = FinderFlags(rawValue: 0x0400)
	/// file is a stationary pad
	static let Stationary = FinderFlags(rawValue: 0x0800)
	/// file can't be renamed by Finder
	static let NameLocked = FinderFlags(rawValue: 0x1000)
	/// file has a bundle
	static let HasBundle = FinderFlags(rawValue: 0x2000)
	/// file's icon is invisible
	static let Invisible = FinderFlags(rawValue: 0x4000)
	/// file is an alias file (System 7)
	static let Alias = FinderFlags(rawValue: 0x8000)
}

/* See older Inside Macintosh, Volume IV, page 105.
*/

/// Extended finder information
struct FXInfo {
	/// icon ID number
	var fdIconID: Int16
	/// spare
	var fdUnused: (Int16, Int16, Int16)
	/// scrip flag and code
	var fdScript: Int8
	/// reserved
	var fdXFlags: Int8
	/// comment ID number
	var fdComment: Int16
	/// home directory ID
	var fdPutAway: Int32
}; /* FXInfo */


/* Pieces used by AppleSingle & AppleDouble (defined later). */

/// header portion of AppleSingle
struct ASHeader {
	init() {
		magicNum = 0
		versionNum = 0
		filler = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
		numEntries = 0
	}
/* AppleSingle = 0x00051600; AppleDouble = 0x00051607 */
	/// internal file type tag
	var magicNum: UInt32
	/// format version: 2 = 0x00020000
	var versionNum: UInt32
	/// filler, currently all bits 0
	var filler: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8)
	/// number of entries which follow
	var numEntries: UInt16
} /* ASHeader */

/// one AppleSingle entry descriptor
struct ASEntry
{
	init() {
		entryIDValue = 0
		entryOffset = 0
		entryLength = 0
	}
	/// Apple reserves the range of entry IDs from `1` to `0x7FFFFFFF`.
	/// Entry ID 0 is invalid.  The rest of the range is available
	/// for applications to define their own entry types.  "Apple does
	/// not arbitrate the use of the rest of the range."
	enum EntryID: UInt32 {
		case Invalid = 0
		
		/// data fork of file - arbitrary length octet string
		case Data = 1
		
		/// resource fork - arbitrary length opaque octet string;
		/// as created and managed by Mac O.S. resoure manager
		case Resource = 2
		
		/// file's name as created on home file system - arbitrary
		/// length octet string; usually short, printable ASCII
		case RealName = 3
		
		/// standard Macintosh comment - arbitrary length octet
		/// string; printable ASCII, claimed 200 chars or less
		case Comment = 4
		
		/// standard Mac black and white icon
		case IconBW = 5
		
		/// "standard" Macintosh color icon - several competing
		///              color icons are defined.  Given the copyright dates
		/// of the Inside Macintosh volumes, the `'cicn'` resource predominated
		/// when the AppleSingle Developer's Note was written (most probable
		/// candidate).  See Inside Macintosh, Volume V, pages 64 & 80-81 for
		/// a description of `'cicn'` resources.
		///
		/// With System 7, Apple introduced icon families.  They consist of:
		///* large (32x32) B&W icon, 1-bit/pixel,    type `'ICN#'`,
		///* small (16x16) B&W icon, 1-bit/pixel,    type `'ics#'`,
		///* large (32x32) color icon, 4-bits/pixel, type `'icl4'`,
		///* small (16x16) color icon, 4-bits/pixel, type `'ics4'`,
		///* large (32x32) color icon, 8-bits/pixel, type `'icl8'`, and
		///* small (16x16) color icon, 8-bits/pixel, type `'ics8'`.
		///
		/// If entry ID 6 is one of these, take your pick.  See Inside
		/// Macintosh, Volume VI, pages 2-18 to 2-22 and 9-9 to 9-13, for
		/// descriptions.
		case IconColor = 6
		
		/// file dates; create, modify, etc
		case FileDates = 8
		
		/// Macintosh Finder info & extended info
		case FinderInfo = 9
		
		/// Mac file info, attributes, etc
		case MacInfo = 10
		
		/// ProDOS file information
		case ProDOSInfo = 11
		
		/// MS-DOS file info, attributes, etc
		case MSDOSInfo = 12
		
		/// short file name on AFP server - arbitrary length
		/// octet string; usualy printable ASCII starting with
		/// `'!'` (`0x21`)
		case AFPName = 13
		
		/// AFP file info, attrib., etc
		case AFPInfo = 14
		
		/// AFP directory ID
		case AFPDirID
	}
	
	/// entry ID 5, standard Mac black and white icon
	///
	/// This is probably a simple duplicate of the 128 octet bitmap
	/// stored as the 'ICON' resource or the icon element from an 'ICN#'
	/// resource.
	struct ASIconBW
	{
		/// 32 rows of 32 1-bit pixels
		var bitrow: (UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32)
	}

	/// entry ID 8, file dates; create, modify, etc
	///
	/// Times are stored as a "signed number of seconds before of after
	/// 12:00 a.m. (midnight), January 1, 2000 Greenwich Mean Time (GMT).
	/// Applications must convert to their native date and time
	/// conventions." Any unknown entries are set to 0x80000000
	/// (earliest reasonable time).
	struct ASFileDates
	{
		/// file creation date/time
		var create: Int32
		/// last modification date/time
		var modify: Int32
		/// last backup date/time
		var backup: Int32
		/// last access date/time
		var access: Int32
	}; /* ASFileDates */


	/// entry ID 9, Macintosh Finder info & extended info
	///
	/// See older Inside Macintosh, Volume II, page 115 for
	/// `PBGetFileInfo()`, and Volume IV, page 155, for `PBGetCatInfo()`.
	struct ASFinderInfo {
		
		/// `PBGetFileInfo()` or `PBGetCatInfo()`
		var ioFlFndrInfo: FInfo
		/// `PBGetCatInfo()` (HFS only)
		var ioFlXFndrInfo: FXInfo
	}
	
	/// entry ID 10, Macintosh file information
	struct ASMacInfo
	{
		struct Attributes: OptionSetType {
			let rawValue: UInt8
			
			init(rawValue rv: UInt8) {
				rawValue = rv
			}
			
			/// protected bit
			static let Protected = Attributes(rawValue: 0x02)
			/// locked bit
			static let Locked = Attributes(rawValue: 0x01)
		}
		/// filler, currently all bits 0
		var filler: (UInt8, UInt8, UInt8)
		/// `PBGetFileInfo()` or `PBGetCatInfo()`
		var ioFlAttrib: Attributes
	}
	
	
	/// entry ID 11, ProDOS file information
	///
	/// NOTE: ProDOS-16 and GS/OS use entire fields.  ProDOS-8 uses low
	/// order half of each item (low byte in access & filetype, low word
	/// in auxtype); remainder of each field should be zero filled.
	struct ASProdosInfo {
		/// access word
		var access: UInt16
		/// file type of original file
		var filetype: UInt16
		/// auxiliary type of the orig file
		var auxtype: UInt32
	}; /* ASProDosInfo */
	
	
	/// entry ID 12, MS-DOS file information
	///
	/// MS-DOS file attributes occupy 1 octet; since the Developer Note
	/// is unspecific, I've placed them in the low order portion of the
	/// field (based on example of other `ASMacInfo` & `ASProdosInfo`).
	struct ASMsdosInfo
	{
		struct DOSAttributes: OptionSetType {
			let rawValue: UInt8
			
			init(rawValue rv: UInt8) {
				rawValue = rv
			}
			
			/// normal file (all bits clear)
			static let Normal = DOSAttributes(rawValue: 0x00)
			/// file is read-only
			static let ReadOnly = DOSAttributes(rawValue: 0x01)
			/// hidden file (not shown by DIR)
			static let Hidden = DOSAttributes(rawValue: 0x02)
			/// system file (not shown by DIR)
			static let System = DOSAttributes(rawValue: 0x04)
			/// volume label (only in root dir)
			static let VolID = DOSAttributes(rawValue: 0x08)
			/// file is a subdirectory
			static let SubDir = DOSAttributes(rawValue: 0x10)
			/// new or modified (needs backup)
			static let Archive = DOSAttributes(rawValue: 0x20)
		}
		/// filler, currently all bits 0
		var filler: UInt8
		/// `_dos_getfileattr()`, MS-DOS
		/// interrupt 21h function 4300h
		var attr: DOSAttributes
	}
	
	/// entry ID 12, AFP server file information
	struct ASAfpInfo {
		
		struct Attributes: OptionSetType {
			let rawValue: UInt8
			
			init(rawValue rv: UInt8) {
				rawValue = rv
			}
			
			/// file is invisible
			static let Invisible = Attributes(rawValue: 0x01)
			/// simultaneous access allowed
			static let MultiUser = Attributes(rawValue: 0x02)
			/// system file
			static let System = Attributes(rawValue: 0x04)
			/// new or modified (needs backup)
			static let BackupNeeded = Attributes(rawValue: 0x40)
		}
		
		/// filler, currently all bits 0
		var filler: (UInt8, UInt8, UInt8)
		/// file attributes
		var attr: Attributes
	}
	
	/// entry ID 15, AFP server directory ID
	struct ASAfpDirId
	{
		/// file's directory ID on AFP server
		var dirid: UInt32
	}; /* ASAfpDirId */

	
	var entryID: EntryID {
		return EntryID(rawValue: entryIDValue) ?? .Invalid
	}
	
	/// entry type: see list, 0 invalid
	var entryIDValue: UInt32
	/// offset, in octets, from beginning
	/// of file to this entry's data
	var entryOffset: UInt32
	/// length of data in octets
	var entryLength: UInt32
}; /* ASEntry */
/*


/* matrix of entry types and their usage:
*
*                   Macintosh    Pro-DOS    MS-DOS    AFP server
*                   ---------    -------    ------    ----------
*  1   AS_DATA         xxx         xxx       xxx         xxx
*  2   AS_RESOURCE     xxx         xxx
*  3   AS_REALNAME     xxx         xxx       xxx         xxx
*
*  4   AS_COMMENT      xxx
*  5   AS_ICONBW       xxx
*  6   AS_ICONCOLOR    xxx
*
*  8   AS_FILEDATES    xxx         xxx       xxx         xxx
*  9   AS_FINDERINFO   xxx
* 10   AS_MACINFO      xxx
*
* 11   AS_PRODOSINFO               xxx
* 12   AS_MSDOSINFO                          xxx
*
* 13   AS_AFPNAME                                        xxx
* 14   AS_AFPINFO                                        xxx
* 15   AS_AFPDIRID                                       xxx
*/

/* entry ID 1, data fork of file - arbitrary length octet string */

/* entry ID 2, resource fork - arbitrary length opaque octet string;
*              as created and managed by Mac O.S. resoure manager
*/

/* entry ID 3, file's name as created on home file system - arbitrary
*              length octet string; usually short, printable ASCII
*/

/* entry ID 4, standard Macintosh comment - arbitrary length octet
*              string; printable ASCII, claimed 200 chars or less
*/

/* This is probably a simple duplicate of the 128 octet bitmap
* stored as the 'ICON' resource or the icon element from an 'ICN#'
* resource.
*/

struct ASIconBW /* entry ID 5, standard Mac black and white icon */
{
Uint32 bitrow[32]; /* 32 rows of 32 1-bit pixels */
}; /* ASIconBW */

typedef struct ASIconBW ASIconBW;

/* entry ID 6, "standard" Macintosh color icon - several competing
*              color icons are defined.  Given the copyright dates
* of the Inside Macintosh volumes, the 'cicn' resource predominated
* when the AppleSingle Developer's Note was written (most probable
* candidate).  See Inside Macintosh, Volume V, pages 64 & 80-81 for
* a description of 'cicn' resources.
*
* With System 7, Apple introduced icon families.  They consist of:
*      large (32x32) B&W icon, 1-bit/pixel,    type 'ICN#',
*      small (16x16) B&W icon, 1-bit/pixel,    type 'ics#',
*      large (32x32) color icon, 4-bits/pixel, type 'icl4',
*      small (16x16) color icon, 4-bits/pixel, type 'ics4',
*      large (32x32) color icon, 8-bits/pixel, type 'icl8', and
*      small (16x16) color icon, 8-bits/pixel, type 'ics8'.
* If entry ID 6 is one of these, take your pick.  See Inside
* Macintosh, Volume VI, pages 2-18 to 2-22 and 9-9 to 9-13, for
* descriptions.
*/

/* entry ID 7, not used */

/* Times are stored as a "signed number of seconds before of after
* 12:00 a.m. (midnight), January 1, 2000 Greenwich Mean Time (GMT).
* Applications must convert to their native date and time
* conventions." Any unknown entries are set to 0x80000000
* (earliest reasonable time).
*/

struct ASFileDates      /* entry ID 8, file dates info */
{
Sint32 create; /* file creation date/time */
Sint32 modify; /* last modification date/time */
Sint32 backup; /* last backup date/time */
Sint32 access; /* last access date/time */
}; /* ASFileDates */

typedef struct ASFileDates ASFileDates;

/* See older Inside Macintosh, Volume II, page 115 for
* PBGetFileInfo(), and Volume IV, page 155, for PBGetCatInfo().
*/

/* entry ID 9, Macintosh Finder info & extended info */
struct ASFinderInfo
{
FInfo ioFlFndrInfo; /* PBGetFileInfo() or PBGetCatInfo() */
FXInfo ioFlXFndrInfo; /* PBGetCatInfo() (HFS only) */
}; /* ASFinderInfo */

typedef struct ASFinderInfo ASFinderInfo;

struct ASMacInfo        /* entry ID 10, Macintosh file information */
{
Uint8  filler[3]; /* filler, currently all bits 0 */
Uint8  ioFlAttrib; /* PBGetFileInfo() or PBGetCatInfo() */
}; /* ASMacInfo */

typedef struct ASMacInfo ASMacInfo;

#define AS_PROTECTED    0x0002 /* protected bit */
#define AS_LOCKED       0x0001 /* locked bit */

/* NOTE: ProDOS-16 and GS/OS use entire fields.  ProDOS-8 uses low
* order half of each item (low byte in access & filetype, low word
* in auxtype); remainder of each field should be zero filled.
*/

struct ASProdosInfo     /* entry ID 11, ProDOS file information */
{
Uint16 access; /* access word */
Uint16 filetype; /* file type of original file */
Uint32 auxtype; /* auxiliary type of the orig file */
}; /* ASProDosInfo */

typedef struct ASProdosInfo ASProdosInfo;

/* MS-DOS file attributes occupy 1 octet; since the Developer Note
* is unspecific, I've placed them in the low order portion of the
* field (based on example of other ASMacInfo & ASProdosInfo).
*/

struct ASMsdosInfo      /* entry ID 12, MS-DOS file information */
{
Uint8  filler; /* filler, currently all bits 0 */
Uint8  attr; /* _dos_getfileattr(), MS-DOS */
/* interrupt 21h function 4300h */
}; /* ASMsdosInfo */

typedef struct ASMsdosInfo ASMsdosInfo;

#define AS_DOS_NORMAL   0x00 /* normal file (all bits clear) */
#define AS_DOS_READONLY 0x01 /* file is read-only */
#define AS_DOS_HIDDEN   0x02 /* hidden file (not shown by DIR) */
#define AS_DOS_SYSTEM   0x04 /* system file (not shown by DIR) */
#define AS_DOS_VOLID    0x08 /* volume label (only in root dir) */
#define AS_DOS_SUBDIR   0x10 /* file is a subdirectory */
#define AS_DOS_ARCHIVE  0x20 /* new or modified (needs backup) */

/* entry ID 13, short file name on AFP server - arbitrary length
*              octet string; usualy printable ASCII starting with
*              '!' (0x21)
*/

struct ASAfpInfo   /* entry ID 12, AFP server file information */
{
Uint8  filler[3]; /* filler, currently all bits 0 */
Uint8  attr; /* file attributes */
}; /* ASAfpInfo */

typedef struct ASAfpInfo ASAfpInfo;

#define AS_AFP_Invisible    0x01 /* file is invisible */
#define AS_AFP_MultiUser    0x02 /* simultaneous access allowed */
#define AS_AFP_System       0x04 /* system file */
#define AS_AFP_BackupNeeded 0x40 /* new or modified (needs backup) */

struct ASAfpDirId       /* entry ID 15, AFP server directory ID */
{
Uint32 dirid; /* file's directory ID on AFP server */
}; /* ASAfpDirId */

typedef struct ASAfpDirId ASAfpDirId;
*/

/// format of disk file
///
/// The format of an AppleSingle/AppleDouble header
struct AppleSingle {
	/// AppleSingle header part
	var header: ASHeader
	/// array of entry descriptors
	var entry: (ASEntry)
	/* Uint8   filedata[];          /* followed by rest of file */*/
}

/*
* FINAL REMINDER: the Motorola 680x0 is a big-endian architecture!
*/
