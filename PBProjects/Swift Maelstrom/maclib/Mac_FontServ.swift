//
//  Mac_FontServ.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/2/15.
//
//

import Foundation
import SDL2

private func HiByte(_ word: UInt16) -> UInt8 {
	return UInt8((word >> 8) & 0xFF)
}

private func LoByte(_ word: UInt16) -> UInt8 {
	return UInt8(word & 0xFF)
}

///Lay-out of a Font Record header
struct FontHdr {
	///Macintosh font magic numbers
	static let FixedFont: UInt16 = 0xB000
	static let PropFont: UInt16 = 0x9000
	
	///`PROPFONT` or `FIXEDFONT`
	var fontType: UInt16 = 0
	var firstChar: Int16 = 0
	var lastChar: Int16 = 0
	var widMax: Int16 = 0
	///Negative of max kern
	var kernMax: Int16 = 0
	///negative of descent
	var nDescent: Int16 = 0
	var fRectWidth: UInt16 = 0
	var fRectHeight: UInt16 = 0
	/** Offset in words from itself to
	the start of the owTable */
	var owTLoc: UInt16 = 0
	var ascent: UInt16 = 0
	var descent: UInt16 = 0
	var leading: UInt16 = 0
	///Row width of bit image in words
	var rowWords: UInt16 = 0
}

private func copy_short(_ S: UnsafeMutablePointer<Int16>, _ D: inout UnsafePointer<UInt8>) {
	memcpy(S, D, 2)
	D += 2
}

private func copy_short(_ S: UnsafeMutablePointer<UInt16>, _ D: inout UnsafePointer<UInt8>) {
	memcpy(S, D, 2)
	D += 2
}

private func copy_int(_ S: UnsafeMutablePointer<Int32>, _ D: inout UnsafePointer<UInt8>) {
	memcpy(S, D, 4)
	D += 4
}

private func copy_int(_ S: UnsafeMutablePointer<UInt32>, _ D: inout UnsafePointer<UInt8>) {
	memcpy(S, D, 4)
	D += 4
}

class FontServer {
	///Different styles supported by the font server
	struct Style: OptionSet {
		let rawValue: UInt8
		
		init(rawValue rv: UInt8) {
			rawValue = rv
		}
		
		static var bold: Style {
			return Style(rawValue: 0x01)
		}
		static var underline: Style {
			return Style(rawValue: 0x02)
		}
		///Unimplemented
		static var italic: Style {
			return Style(rawValue: 0x04)
		}
	}

	fileprivate struct FontEntry {
		var size: UInt16 = 0
		var style: UInt16 = 0
		var ID: UInt16 = 0
	}
	
	fileprivate struct FOND {
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

	final class Font {
		///The NFNT header!
		fileprivate var header: FontHdr = FontHdr()
		
		//MARK: - Variable-length tables
		/// bitImage[rowWords][fRectHeight];
		var bitImage: [UInt16] = []
		
		///locTable[lastChar+3-firstChar];
		var locTable: [UInt16] = []
		
		/// owTable[lastchar+3-firstChar];
		var owTable: [Int16] = []
		
		//MARK: -
		
		/// The Raw Data
		//private weak var nfnt: NSData! = NSData()
		
		var textHeight: UInt16 {
			return header.fRectHeight
		}
		
		/// The width of the specified text in pixels when displayed with the
		/// specified font and style.
		func textWidth(_ text: String, style: Style) -> UInt16 {
			//First, convert to MacRoman.
			guard let macRomanStr = text.cString(using: String.Encoding.macOSRoman) else {
				return 0
			}
			var extra_width: UInt16 = 0
			if style.contains(.bold) {
				extra_width = 1
			}
			
			if style.contains(.italic) {
				return 0
			}
			
			var width: UInt16 = 0
			
			for aChar in macRomanStr {
				let uChar = UInt8(bitPattern: aChar)
				/* check to see if this character is defined */
				if owTable[Int(uChar)] <= 0 {
					continue
				}
				let space_width = LoByte(UInt16(owTable[Int(uChar)]))
				#if WIDE_BOLD
				width += UInt16(space_width) + extra_width
				#else
				width += UInt16(space_width);
				#endif
			}
			
			return width
		}
	}

	enum Errors: Error {
		case noFONDResource
		case fontFamilyNotFound
		case fontFamilyLacksPointSize
		case badFontMagicNumber(UInt16)
	}

	fileprivate var text_allocated = 0
	fileprivate var fontres: MacResource!

	init(fontAt fontfile: URL) throws {
		fontres = try MacResource(fileURL: fontfile);

		if fontres.countOfResources(type: MaelOSType(stringValue: "FOND")!) == 0 {
			throw Errors.noFONDResource
		}
	}
	
	func newFont(_ fontName: String, pointSize ptsize: Int32) throws -> Font {
		var fond: Data!
		var fondStruct = FOND()
		var fent = FontEntry()
		do {
			/* Get the font family */
			fond = try fontres.resource(type: MaelOSType(stringValue: "FOND")!, name: fontName)
		} catch _ {
			throw Errors.fontFamilyNotFound
		}
		
		/* Find out what font ID we need */
		
		try fond.withUnsafeBytes { (data1: UnsafePointer<UInt8>) -> Void in
			var data = data1
			copy_short(&fondStruct.flags, &data);
			copy_short(&fondStruct.ID, &data);
			copy_short(&fondStruct.firstCH, &data);
			copy_short(&fondStruct.lastCH, &data);
			copy_short(&fondStruct.MaxAscent, &data);
			copy_short(&fondStruct.MaxDescent, &data);
			copy_short(&fondStruct.MaxLead, &data);
			copy_short(&fondStruct.MaxWidth, &data);
			copy_int(&fondStruct.WidthOff, &data);
			copy_int(&fondStruct.KernOff, &data);
			copy_int(&fondStruct.StyleOff, &data);
			memcpy(&fondStruct.StyleProp, data, 18); data = data.advanced(by: 18);
			copy_int(&fondStruct.Intl_info, &data);
			copy_short(&fondStruct.Version, &data);
			copy_short(&fondStruct.num_fonts, &data);
			bytesex16(&fondStruct.num_fonts);

		var ii = 0
		
		for i in 0 ..< Int(fondStruct.num_fonts)  {
			memcpy(&fent, data, MemoryLayout<FontEntry>.size);
			func aSwap(_ fe: UnsafeMutablePointer<FontEntry>) {
				fe.withMemoryRebound(to: UInt16.self, capacity: 3, { byteswap($0, 3) })
			}
			//byteswap((Uint16 *)&Fent, 3);
			aSwap(&fent)
			if Int(fent.size) == Int(ptsize) && fent.style == 0 {
				break;
			}
			//data += MemoryLayout<FontEntry>.size
			ii = i
		}
		
		if ii == Int(fondStruct.num_fonts) {
			throw Errors.fontFamilyLacksPointSize
		}
		}

		/* Now, fent.ID is the ID of the correct NFNT resource */
		var font = Font()
		var fontData = try fontres.resource(type: MaelOSType(stringValue: "NFNT")!, id: fent.ID)
		
		/* Now that we have the resource, fiddle with the font structure
		so we can use it.  (Code taken from 'mac2bdf' -- Thanks! :)
		*/
		var swapFont = false
		font.header = (fontData as NSData).bytes.bindMemory(to: FontHdr.self, capacity: fontData.count).pointee
		if ((font.header.fontType & ~3) != FontHdr.PropFont) &&
			((font.header.fontType & ~3) != FontHdr.FixedFont) {
				swapFont = true
		}
		if swapFont {
			func aSwap(_ fe: UnsafeMutablePointer<FontHdr>) {
				fe.withMemoryRebound(to: UInt16.self, capacity: 13, { byteswap($0, MemoryLayout<FontHdr>.size / MemoryLayout<UInt16>.size) })
			}
			aSwap(&font.header)
		}
		
		/* Check magic number.
		The low two bits are masked off; newer versions of the Font Manager
		use these to indicate the presence of optional 'width' and 'height'
		tables, which are for fractional character spacing (unused).
		*/
		if  ((font.header.fontType & ~3) != FontHdr.PropFont) &&
			((font.header.fontType & ~3) != FontHdr.FixedFont)  {
				throw Errors.badFontMagicNumber(font.header.fontType)
		}

		let nchars = font.header.lastChar - (font.header.firstChar + 1) + 1
		/* One extra for "missing character image" */
		let nwords = font.header.rowWords * font.header.fRectHeight
		
		do {
			let tmpBitImage = (fontData as NSData).bytes.advanced(by: MemoryLayout<FontHdr>.size).assumingMemoryBound(to: UInt16.self) //UnsafePointer<UInt16>((fontData as NSData).bytes.advanced(by: sizeof(FontHdr)))
			let tmpLocTable = tmpBitImage.advanced(by: Int(nwords))
			font.owTable = tmpLocTable.advanced(by: Int(nchars) + 1).withMemoryRebound(to: Int16.self, capacity: Int(nchars), { (tmpOwTable) -> [Int16] in
				let tmpBufOwTable = UnsafeBufferPointer(start: tmpOwTable, count: Int(nchars))
				return Array(tmpBufOwTable)
			})//UnsafePointer<Int16>(tmpLocTable.advanced(by: Int(nchars) + 1))
			let tmpBufBitImage = UnsafeBufferPointer(start: tmpBitImage, count: Int(nwords))
			let tmpBufLocTable = UnsafeBufferPointer(start: tmpLocTable, count: Int(nchars) + 1)
			//let tmpBufOwTable = UnsafeBufferPointer(start: tmpOwTable, count: Int(nchars))
			font.bitImage = Array(tmpBufBitImage)
			font.locTable = Array(tmpBufLocTable)
			//font.owTable = Array(tmpBufOwTable)
		}

		/* Note -- there may be excess data at the end of the resource
		(the optional width or height tables) */
		
		/* Byteswap the tables */
		if swapFont {
			byteswap(&font.bitImage, Int(nwords))
			byteswap(&font.locTable, Int(nchars) + 1)
			for (i, val) in font.owTable.enumerated() {
				font.owTable[i] = val.bigEndian
			}
		}
		
		return font
	}
	
	/// Determine the final width of a text block (in pixels)
	func textWidth(_ text: String, font: Font, style: Style) -> UInt16 {
		return font.textWidth(text, style: style)
	}
	/// Determine the final height of a text block (in pixels)
	func textHeight(font: Font) -> UInt16 {
		return font.textHeight
	}

	///Determine the final width and height of a text block (in pixels)
	func textSize(_ text: String, font: Font, style: Style) -> (width: UInt16, height: UInt16) {
		let width = textWidth(text, font: font, style: style)
		let height = textHeight(font: font)
		return (width, height)
	}
	
	/// Returns a bitmap image filled with the requested text.
	/// The text should be freed with `freeText()` after it is used.
	func newTextImage(_ text: String, font: Font, style: Style, foreground: SDL_Color, background: SDL_Color) -> UnsafeMutablePointer<SDL_Surface>? {
		guard let aChars = text.cString(using: String.Encoding.macOSRoman) else {
			error = "FontServ: Encoding error"
			return nil
		}
		let bChars: [UInt8] = {
			var cChars = aChars.map { (aChar) -> UInt8 in
				return UInt8(bitPattern: aChar)
			}
			cChars.removeLast()
			
			return cChars
		}()
		
		///Set bit `i` of a scan line
		func SETBIT(_ scanline: UnsafeMutablePointer<UInt8>, _ i: Int, _ bit: UInt8) {
			let bleh = (7 - UInt8((i)%8))
			let bleh2 = bit << bleh
			scanline[(i)/8] |= bleh2
		}
		
		///Get bit `i` of a scan line
		func GETBIT(_ scanline: UnsafePointer<UInt16>, _ i: Int) -> UInt8 {
			return UInt8((scanline[(i)/16] >> (15 - UInt16(i%16))) & 1)
		}
		
		//var image: UnsafeMutablePointer<SDL_Surface>? = nil
		//var bitmap: UnsafeMutablePointer<UInt8>? = nil
		
		var bold_offset = 0
		
		if style.contains(.bold) {
			bold_offset = 1
		}
		
		if style.contains(.italic) {
			error = "FontServ: Italics not implemented!"
			return nil
		}
		
		/*
		switch (style) {
		case STYLE_NORM:	bold_offset = 0;
		break;
		case STYLE_BOLD:	bold_offset = 1;
		break;
		case STYLE_ULINE:	bold_offset = 0;
		break;
		case STYLE_ITALIC:	SetError(
			"FontServ: Italics not implemented!");
		return(NULL);
		default:		SetError(
			"FontServ: Unknown text style!");
		return(NULL);
		}*/
		
		/* Notes on the tables.
		
		Table 'bits' contains a bitmap image of the entire font.
		There are fRectHeight rows, each rowWords long.
		The high bit of a word is leftmost in the image.
		The characters are placed in this image in order of their
		ASCII value.  The last image is that of the "missing
		character"; every Mac font must have such an image
		(traditionally a maximum-sized block).
		
		The location table (loctab) and offset/width table (owtab)
		have one entry per character in the range firstChar..lastChar,
		plus two extra entries: one for the "missing character" image
		and a terminator.  They describe, respectively, where to
		find the character in the bitmap and how to interpret it with
		respect to the "character origin" (pen position on the base
		line).
		
		The location table entry for a character contains the bit (!)
		offset of the start of its image data in the font's bitmap.
		The image data's width is computed by subtracting the start
		from the start of the next character (hence the terminator).
		
		The offset/width table contains -1 for undefined characters;
		for defined characters, the high byte contains the character
		offset (distance between left of character image and
		character origin), and the low byte contains the character
		width (distance between the character origin and the origin
		of the next character on the line).
	 */
		
		/* Figure out how big the text image will be */
		let width = textWidth(text, font: font, style: style);
		if width == 0 {
			error = "No text to convert"
			return nil
		}
		let height = font.header.fRectHeight
		
		/* Allocate the text bitmap image */
		guard let image = SDL_CreateRGBSurface([], Int32(width), Int32(height), 1, 0,0,0,0) else {
			error = String(format: "Unable to allocate bitmap: %s", SDL_GetError());
			return nil
		}
		let bitmap = image.pointee.pixels.assumingMemoryBound(to: UInt8.self)
		
		/* Print the individual characters */
		/* Note: this could probably be optimized.. eh, who cares. :) */
		var bit_offset = 0
		for boldness in 0 ... bold_offset {
			bit_offset=0;
			for aChar in bChars {
				/* check to see if this character is defined */
				/* According to the above comment, we should */
				/* check if the table contains -1, but this  */
				/* change seems to fix a SIGSEGV that would  */
				/* otherwise occur in some cases.            */
				if font.owTable[Int(aChar)] <= 0 {
					continue;
				}
				
				let space_width = LoByte(UInt16(font.owTable[Int(aChar)]));
				let space_offset = HiByte(UInt16(font.owTable[Int(aChar)]));
				let ascii = Int16(aChar) - font.header.firstChar
				let glyph_line_offset = font.locTable[Int(ascii)]
				let glyph_width = (font.locTable[Int(ascii)+1] - font.locTable[Int(ascii)]);
				for y in 0..<height {
					let dst_offset = (Int(y)*Int((image.pointee.pitch))*8 +
						bit_offset+Int(space_offset))
					
					font.bitImage.withUnsafeBufferPointer({ (bufPtr) -> Void in
						let src_scanline = bufPtr.baseAddress!.advanced(by: Int(y) * Int(font.header.rowWords))
						for bit in 0..<glyph_width {
							SETBIT(bitmap, dst_offset+Int(bit)+boldness,
								   GETBIT(src_scanline, Int(glyph_line_offset+bit)))
						}
					})
				}
				#if WIDE_BOLD
				bit_offset += (Int(space_width)+Int(bold_offset));
				#else
				bit_offset += Int(space_width)
				#endif
			}
		}
		if style.contains(.underline) {
			let y = height-(font.header).descent+1
			bit_offset =  Int(y)*Int((image.pointee.pitch))*8
			for bit in 0..<width {
				SETBIT(bitmap, bit_offset+Int(bit), 0x01);
			}
		}
		
		/* Map the image and return */
		SDL_SetColorKey(image, 1/*SDL_SRCCOLORKEY*/, 0);
		image.pointee.format.pointee.palette.pointee.colors[0] = background
		image.pointee.format.pointee.palette.pointee.colors[1] = foreground
		text_allocated += 1;
		return image
	}
	
	/// Returns a bitmap image filled with the requested text.
	/// The text should be freed with `freeText()` after it is used.
	func newTextImage(_ text: String, font: Font, style: Style, foreground: (red: UInt8, green: UInt8, blue: UInt8)) -> UnsafeMutablePointer<SDL_Surface>? {
		let background = SDL_Color(r: 0xFF, g: 0xFF, b: 0xFF, a: 0xFF)
		let fgColor = SDL_Color(r: foreground.red, g: foreground.green, b: foreground.blue, a: 0xFF)
		
		return newTextImage(text, font: font, style: style, foreground: fgColor, background: background)
	}
	
	func freeText(_ text: UnsafeMutablePointer<SDL_Surface>) {
		text_allocated -= 1
		SDL_FreeSurface(text)
	}
	
	/// Inverts the color of the text image
	func invertText(_ text: UnsafeMutablePointer<SDL_Surface>) -> Bool {
		var colors = [SDL_Color]()
		colors.reserveCapacity(2)
		
		/* Only works on bitmap images */
		if text.pointee.format.pointee.BitsPerPixel != 1 {
			error = "Not a text bitmap"
			return false
		}
		
		/* Swap background and foreground colors */
		colors.append(text.pointee.format.pointee.palette.pointee.colors[1])
		colors.append(text.pointee.format.pointee.palette.pointee.colors[0])
		SDL_SetPaletteColors(text.pointee.format.pointee.palette, colors, 0, 2);
		return true
	}

	private(set) var error: String? = nil
}
