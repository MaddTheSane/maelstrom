//
//  Mac_FontServ.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/2/15.
//
//

import Foundation

///Different styles supported by the font server
struct FontStyle: OptionSetType {
	let rawValue: UInt8
	
	init(rawValue rv: UInt8) {
		rawValue = rv
	}
	
	static let Normal = FontStyle(rawValue: 0)
	static let Bold = FontStyle(rawValue: 0x01)
	static let Underline = FontStyle(rawValue: 0x02)
	///Unimplemented
	static let Italic = FontStyle(rawValue: 0x04)
}

///Lay-out of a Font Record header
struct FontHdr {
	///Macintosh font magic numbers
	static let FixedFont: UInt16 = 0xB000
	static let PropFont: UInt16 = 0x9000
	
	///`PROPFONT` or `FIXEDFONT`
	var fontType: UInt16
	var firstChar: Int16
	var lastChar: Int16
	var widMax: Int16
	///Negative of max kern
	var kernMax: Int16
	///negative of descent
	var nDescent: Int16
	var fRectWidth: UInt16
	var fRectHeight: UInt16
	/** Offset in words from itself to
	the start of the owTable */
	var owTLoc: UInt16
	var ascent: UInt16
	var descent: UInt16
	var leading: UInt16
	///Row width of bit image in words
	var rowWords: UInt16
}

class FontServ {
	private struct FontEntry {
		var size: UInt16 = 0
		var style: UInt16 = 0
		var ID: UInt16 = 0
	}
	
	private struct FOND {
		var flags: UInt16 = 0
		var ID: UInt16 = 0
		var firstCH: UInt16 = 0
		var lastCH: UInt16 = 0
		///Maximum Font Ascent
		var MaxAscent: UInt16 = 0
		///Maximum Font Descent
		var MaxDescent: UInt16 = 0
		///Maximum Font Leading
		var MaxLead: UInt16 = 0
		///Maximum Font Glyph Width
		var MaxWidth: UInt16 = 0
		///Width table offset
		var WidthOff: UInt32 = 0
		///Kerning table offset
		var KernOff: UInt32 = 0
		///Style mapping table offset
		var StyleOff: UInt32 = 0
		///9 Style Properties
		var StyleProp: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16) = (0, 0, 0, 0, 0, 0, 0, 0, 0)
		///International script info
		var Intl_info: UInt32 = 0
		///The version of the FOND resource
		var Version: UInt16 = 0
		
		//MARK: - The Font Association Table
		///Number of fonts in table - 1
		var num_fonts: UInt16 = 0
		//#ifdef SHOW_VARLENGTH_FIELDS
		//struct Font_entry nfnts[0];
		//#endif
		
		/* The Offset Table */
		/* The Bounding Box Table */
		/* The Glyph Width Table */
		/* The Style Mapping Table */
		/* The Kerning Table */
	};

	struct MFont {
		///The NFNT header!
		var header: FontHdr
		
		//MARK: - Variable-length tables
		/// bitImage[rowWords][fRectHeight];
		var bitImage: [UInt16]
		
		///locTable[lastChar+3-firstChar];
		var locTable: [UInt16]
		
		/// owTable[lastchar+3-firstChar];
		var owTable: [Int16]
		
		//MARK: -
		
		/// The Raw Data
		var nfnt: NSData
	}
	
	enum Errors: ErrorType {
		case NoFONDResource
	}

	private var text_allocated = 0
	private var fontres: Mac_Resource!

	init(fontAtURL fontfile: NSURL) throws {
		fontres = try Mac_Resource(fileURL: fontfile);

		if fontres.countOfResources(type: MaelOSType(stringValue: "FOND")!) == 0 {
			throw Errors.NoFONDResource
		}
	}
}
