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
struct Point {
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
	
	/// File type, 4 ASCII chars
	var fdType: MaelOSType = MaelOSType()
	/// File's creator, 4 ASCII chars
	var fdCreator: MaelOSType = MaelOSType()
	/// Finder flag bits
	var fdFlags: FinderFlags = []
	/// file's location in folder
	var fdLocation: Point = Point(v: 0, h: 0)
	/// file's folder (aka window)
	var fdFldr: Int16 = 0
}

/* See older Inside Macintosh, Volume IV, page 105.
*/

/// Extended finder information
struct FXInfo {
	/// icon ID number
	var fdIconID: Int16 = 0
	/// spare
	var fdUnused: (Int16, Int16, Int16) = (0,0,0)
	/// scrip flag and code
	var fdScript: Int8 = 0
	/// reserved
	var fdXFlags: Int8 = 0
	/// comment ID number
	var fdComment: Int16 = 0
	/// home directory ID
	var fdPutAway: Int32 = 0
}; /* FXInfo */


/* Pieces used by AppleSingle & AppleDouble (defined later). */

/// header portion of AppleSingle
struct AppleSingleHeader {
	
	/// AppleSingle = 0x00051600;
	static let AppleSingle: UInt32 = 0x00051600
	
	/// AppleDouble = 0x00051607
	static let AppleDouble: UInt32 = 0x00051607
	
	/// internal file type tag
	var magicNum: UInt32 = 0
	/// format version: 2 = 0x00020000
	var versionNum: UInt32 = 0
	/// filler, currently all bits 0
	var filler: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
	/// number of entries which follow
	var numEntries: UInt16 = 0
} /* ASHeader */

/// one AppleSingle entry descriptor
struct AppleSingleEntry {
	/// Apple reserves the range of entry IDs from `1` to `0x7FFFFFFF`.
	/// Entry ID 0 is invalid.  The rest of the range is available
	/// for applications to define their own entry types.  "Apple does
	/// not arbitrate the use of the rest of the range."
	///
	/// matrix of entry types and their usage:
	///
	///                       Macintosh    Pro-DOS    MS-DOS    AFP server
	///                       ---------    -------    ------    ----------
	///      1   AS_DATA         xxx         xxx       xxx         xxx
	///      2   AS_RESOURCE     xxx         xxx
	///      3   AS_REALNAME     xxx         xxx       xxx         xxx
	///
	///      4   AS_COMMENT      xxx
	///      5   AS_ICONBW       xxx
	///      6   AS_ICONCOLOR    xxx
	///
	///      8   AS_FILEDATES    xxx         xxx       xxx         xxx
	///      9   AS_FINDERINFO   xxx
	///     10   AS_MACINFO      xxx
	///
	///     11   AS_PRODOSINFO               xxx
	///     12   AS_MSDOSINFO                          xxx
	///
	///     13   AS_AFPNAME                                        xxx
	///     14   AS_AFPINFO                                        xxx
	///     15   AS_AFPDIRID                                       xxx
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
		
		/// AFP server file information
		case AFPInfo = 14
		
		/// AFP server directory ID
		case AFPDirID = 15
	}
	
	/// entry ID 5, standard Mac black and white icon
	///
	/// This is probably a simple duplicate of the 128 octet bitmap
	/// stored as the `'ICON'` resource or the icon element from an `'ICN#'`
	/// resource.
	struct IconBW {
		/// 32 rows of 32 1-bit pixels
		var bitrow: (UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32,UInt32)
	}

	/// entry ID 8, file dates; create, modify, etc
	///
	/// Times are stored as a "signed number of seconds before of after
	/// 12:00 a.m. (midnight), January 1, 2000 Greenwich Mean Time (GMT).
	/// Applications must convert to their native date and time
	/// conventions." Any unknown entries are set to `0x80000000`
	/// (earliest reasonable time).
	struct FileDates {
		/// file creation date/time
		var create: Int32 = Int32(bitPattern: 0x80000000)
		/// last modification date/time
		var modify: Int32 = Int32(bitPattern: 0x80000000)
		/// last backup date/time
		var backup: Int32 = Int32(bitPattern: 0x80000000)
		/// last access date/time
		var access: Int32 = Int32(bitPattern: 0x80000000)
	}; /* ASFileDates */


	/// entry ID 9, Macintosh Finder info & extended info
	///
	/// See older Inside Macintosh, Volume II, page 115 for
	/// `PBGetFileInfo()`, and Volume IV, page 155, for `PBGetCatInfo()`.
	struct ASFinderInfo {
		/// `PBGetFileInfo()` or `PBGetCatInfo()`
		var ioFlFndrInfo: FInfo = FInfo()
		/// `PBGetCatInfo()` (HFS only)
		var ioFlXFndrInfo: FXInfo = FXInfo()
	}
	
	/// entry ID 10, Macintosh file information
	struct MacInfo {
		struct Attributes: OptionSetType {
			let rawValue: UInt8
			
			init(rawValue rv: UInt8) {
				rawValue = rv
			}
			
			/// protected bit
			static let Protected = Attributes(rawValue: 1 << 1)
			/// locked bit
			static let Locked = Attributes(rawValue: 1 << 0)
		}
		/// filler, currently all bits 0
		var filler: (UInt8, UInt8, UInt8) = (0,0,0)
		/// `PBGetFileInfo()` or `PBGetCatInfo()`
		var ioFlAttrib: Attributes = []
	}
	
	
	/// entry ID 11, ProDOS file information
	///
	/// NOTE: ProDOS-16 and GS/OS use entire fields.  ProDOS-8 uses low
	/// order half of each item (low byte in access & filetype, low word
	/// in auxtype); remainder of each field should be zero filled.
	struct ProDOSInfo {
		/// access word
		var access: UInt16 = 0
		/// file type of original file
		var filetype: UInt16 = 0
		/// auxiliary type of the orig file
		var auxtype: UInt32 = 0
	}; /* ASProDosInfo */
	
	
	/// entry ID 12, MS-DOS file information
	///
	/// MS-DOS file attributes occupy 1 octet; since the Developer Note
	/// is unspecific, I've placed them in the low order portion of the
	/// field (based on example of other `ASMacInfo` & `ASProdosInfo`).
	struct MSDOSInfo {
		struct DOSAttributes: OptionSetType {
			let rawValue: UInt8
			
			init(rawValue rv: UInt8) {
				rawValue = rv
			}
			
			/// normal file (all bits clear)
			static let Normal = DOSAttributes(rawValue: 0x00)
			/// file is read-only
			static let ReadOnly = DOSAttributes(rawValue: 1 << 0)
			/// hidden file (not shown by DIR)
			static let Hidden = DOSAttributes(rawValue: 1 << 1)
			/// system file (not shown by DIR)
			static let System = DOSAttributes(rawValue: 1 << 2)
			/// volume label (only in root dir)
			static let VolID = DOSAttributes(rawValue: 1 << 3)
			/// file is a subdirectory
			static let SubDir = DOSAttributes(rawValue: 1 << 4)
			/// new or modified (needs backup)
			static let Archive = DOSAttributes(rawValue: 1 << 5)
		}
		/// filler, currently all bits 0
		var filler: UInt8 = 0
		/// `_dos_getfileattr()`, MS-DOS
		/// interrupt 21h function 4300h
		var attr: DOSAttributes = .Normal
	}
	
	/// entry ID 14, AFP server file information
	struct AFPInfo {
		struct Attributes: OptionSetType {
			let rawValue: UInt8
			
			init(rawValue rv: UInt8) {
				rawValue = rv
			}
			
			/// file is invisible
			static let Invisible = Attributes(rawValue: 1 << 0)
			/// simultaneous access allowed
			static let MultiUser = Attributes(rawValue: 1 << 1)
			/// system file
			static let System = Attributes(rawValue: 1 << 2)
			/// new or modified (needs backup)
			static let BackupNeeded = Attributes(rawValue: 0x40)
		}
		
		/// filler, currently all bits 0
		var filler: (UInt8, UInt8, UInt8) = (0,0,0)
		/// file attributes
		var attr: Attributes = []
	}
	
	/// entry ID 15, AFP server directory ID
	struct AFPDirId {
		/// file's directory ID on AFP server
		var dirid: UInt32 = 0
	}; /* ASAfpDirId */

	
	var entryID: EntryID {
		return EntryID(rawValue: entryIDValue) ?? .Invalid
	}
	
	/// entry type: see list, 0 invalid
	var entryIDValue: UInt32 = 0
	/// offset, in octets, from beginning
	/// of file to this entry's data
	var entryOffset: UInt32 = 0
	/// length of data in octets
	var entryLength: UInt32 = 0
}; /* ASEntry */

/// format of disk file
///
/// The format of an AppleSingle/AppleDouble header
struct AppleSingle {
	/// AppleSingle header part
	var header: AppleSingleHeader
	/// array of entry descriptors
	var entry: (AppleSingleEntry)
	/* Uint8   filedata[];          /* followed by rest of file */*/
}

/*
* FINAL REMINDER: the Motorola 680x0 is a big-endian architecture!
*/

