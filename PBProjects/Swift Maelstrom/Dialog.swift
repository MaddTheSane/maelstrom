//
//  Dialog.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/12/15.
//
//

import Foundation
import SDL2


/*  This is a class set for Macintosh-like dialogue boxes. :) */
/*  Sorta complex... */

/* Defaults for various dialog classes */

let BUTTON_WIDTH: Int32 = 75
let BUTTON_HEIGHT: Int32 = 19

let BOX_WIDTH: Int32 = 170
let BOX_HEIGHT: Int32 = 20

let EXPAND_STEPS = 50


/** Utility routine for dialogs */
private func isSensitive(_ area: SDL_Rect, x: Int32, y: Int32) -> Bool {
	if (y > area.y) && (y < (area.y+area.h)) &&
		(x > area.x) && (x < (area.x+area.w)) {
			return true
	}
	return false
}

/**  This is a class set for Macintosh-like dialogue boxes. :) */
class MacDialog {
	fileprivate static var textEnabled = 0
	fileprivate var screen: FrameBuf!
	fileprivate var position: (x: Int32, y: Int32)
	typealias ButtonCallbackFunc = (_ x: Int32, _ y: Int32, _ button: UInt8, _ done: inout Bool) -> Void
	typealias KeyCallbackFunc = (_ key: SDL_Keysym, _ doneflag: inout Bool) -> Void
	
	fileprivate var buttonCallback: ButtonCallbackFunc?
	fileprivate var keyCallback: KeyCallbackFunc?
	
	fileprivate(set) var error: String?
	
	init(x: Int32, y: Int32) {
		position = (x, y)
	}
	
	//MARK: - Input handling
	
	func setButtonPress(_ newButtonCallback: ButtonCallbackFunc?) {
		buttonCallback = newButtonCallback
	}
	
	func handleButtonPress(x: Int32, y: Int32, button: UInt8, done doneFlag: inout Bool) {
		buttonCallback?(x, y, button, &doneFlag)
	}
	
	func setKeyPress(_ newKeyCallback: KeyCallbackFunc?) {
		keyCallback = newKeyCallback
	}
	
	func handleKeyPress(_ key: SDL_Keysym, done doneflag: inout Bool) {
		keyCallback?(key, &doneflag)
	}
	
	//MARK: - Display handling
	
	func map(offset: (x: Int32, y: Int32), screen: FrameBuf, background: (red: UInt8, green: UInt8, blue: UInt8), foreground: (red: UInt8, green: UInt8, blue: UInt8)) {
		position.x += offset.x
		position.y += offset.y
		self.screen = screen
	}
	
	final func map(xOff: Int32, yOff: Int32, screen: FrameBuf, r_bg: UInt8, g_bg: UInt8, b_bg: UInt8, r_fg: UInt8, g_fg: UInt8, b_fg: UInt8) {
		self.map(offset: (xOff, yOff), screen: screen, background: (r_bg, g_bg, b_bg), foreground: (r_fg, g_fg, b_fg))
	}
	
	func show() {
		//empty, for subclassing
	}
	
	fileprivate class func enableText() {
		if textEnabled == 0 {
			SDL_StartTextInput()
		}
		textEnabled += 1
	}
	
	fileprivate class func disableText() {
		textEnabled -= 1
		if textEnabled == 0 {
			SDL_StopTextInput()
		}
	}
}

/** The button callbacks should return `1` if they finish the dialog,
or `0` if they do not.
*/
class MacButton : MacDialog {
	fileprivate var size: (width: Int32, height: Int32)
	//int Width, Height;
	fileprivate var button: UnsafeMutablePointer<SDL_Surface>?
	fileprivate var callback: buttonCallback?
	fileprivate var sensitive = SDL_Rect()
	typealias buttonCallback = () -> Bool
	
	enum Errors: Error {
		case sdlError(String)
	}
	
	init(x: Int32, y: Int32, width: Int32, height: Int32, text: String, font: FontServer.Font, fontserv: FontServer, callback: buttonCallback?) throws {
		size = (width, height)
		button = SDL_CreateRGBSurface([], width, height,
			8, 0, 0, 0, 0);

		super.init(x: x, y: y)

		guard button != nil else {
			throw Errors.sdlError(String(cString: SDL_GetError()))
		}
		
		//var textb = UnsafeMutablePointer<SDL_Surface>()
		var dstrect = SDL_Rect()
		
		button?.pointee.format.pointee.palette.pointee.colors[0].r = 0xFF;
		button?.pointee.format.pointee.palette.pointee.colors[0].g = 0xFF;
		button?.pointee.format.pointee.palette.pointee.colors[0].b = 0xFF;
		button?.pointee.format.pointee.palette.pointee.colors[1].r = 0x00;
		button?.pointee.format.pointee.palette.pointee.colors[1].g = 0x00;
		button?.pointee.format.pointee.palette.pointee.colors[1].b = 0x00;
		
		let textb = fontserv.newTextImage(text, font: font, style: [], foreground: (red: 0, green: 0, blue: 0))
		if textb != nil {
			if (textb!.pointee.w <= button!.pointee.w) &&
				(textb!.pointee.h <= button!.pointee.h) {
					dstrect.x = (button!.pointee.w-textb!.pointee.w)/2;
					dstrect.y = (button!.pointee.h-textb!.pointee.h)/2;
					dstrect.w = textb!.pointee.w;
					dstrect.h = textb!.pointee.h;
					SDL_UpperBlit(textb, nil, button, &dstrect);
			}

			fontserv.freeText(textb!)
		}
		bevelButton(button!);
		
		/* Set the callback */
		self.callback = callback
	}
	
	fileprivate func bevelButton(_ image: UnsafeMutablePointer<SDL_Surface>) {
		var image_bits = image.pointee.pixels.assumingMemoryBound(to: UInt8.self)
		
		/* Bevel upper corners */
		memset(image_bits+3, 0x01, Int(image.pointee.w - 6));
		image_bits += Int(image.pointee.pitch)
		memset(image_bits+1, 0x01, 2);
		memset(image_bits.advanced(by: Int(image.pointee.w-3)), 0x01, 2);
		image_bits += Int(image.pointee.pitch);
		memset(image_bits+1, 0x01, 1);
		memset(image_bits.advanced(by: Int(image.pointee.w - 2)), 0x01, 1);
		image_bits += Int(image.pointee.pitch);
		
		/* Draw sides */
		//for ( h=3; h < Int(image.memory.h-3); ++h ) {
		for _ in 3..<(image.pointee.h - 3) {
			image_bits[0] = 0x01;
			image_bits[Int(image.pointee.w-1)] = 0x01;
			image_bits += Int(image.pointee.pitch)
		}
		
		/* Bevel bottom corners */
		memset(image_bits+1, 0x01, 1);
		memset(image_bits.advanced(by: Int(image.pointee.w - 2)), 0x01, 1);
		image_bits += Int(image.pointee.pitch)
		memset(image_bits+1, 0x01, 2);
		memset(image_bits+Int(image.pointee.w-3), 0x01, 2);
		image_bits += Int(image.pointee.pitch);
		memset(image_bits+3, 0x01, Int(image.pointee.w - 6));
	}
	
	override func show() {
		screen.queueBlit(x: position.x, y: position.y, src: button!, do_clip: .noclip);
	}
	
	override func map(offset: (x: Int32, y: Int32), screen: FrameBuf, background: (red: UInt8, green: UInt8, blue: UInt8), foreground: (red: UInt8, green: UInt8, blue: UInt8)) {
		super.map(offset: offset, screen: screen, background: background, foreground: foreground)
		
		/* Set up the button sensitivity */
		sensitive.x = position.x;
		sensitive.y  = position.y;
		sensitive.w = size.width;
		sensitive.h = size.height;
		
		/* Map the bitmap image */
		button?.pointee.format.pointee.palette.pointee.colors[0].r = background.red;
		button?.pointee.format.pointee.palette.pointee.colors[0].g = background.green;
		button?.pointee.format.pointee.palette.pointee.colors[0].b = background.blue;
		button?.pointee.format.pointee.palette.pointee.colors[1].r = foreground.red;
		button?.pointee.format.pointee.palette.pointee.colors[1].g = foreground.green;
		button?.pointee.format.pointee.palette.pointee.colors[1].b = foreground.blue;
	}
	
	final fileprivate func invertImage() {
		let buttonPixels = UnsafeMutableBufferPointer(start: button?.pointee.pixels.assumingMemoryBound(to: UInt8.self), count: Int(button!.pointee.h * button!.pointee.pitch))
		
		for (i,buf) in buttonPixels.enumerated() {
			if buf == 0 {
				buttonPixels[i] = 1
			} else {
				buttonPixels[i] = 0
			}
		}
	}
	
	override final func handleButtonPress(x: Int32, y: Int32, button: UInt8, done doneFlag: inout Bool) {
		if isSensitive(sensitive, x: x, y: y) {
			activateButton(&doneFlag)
		}
	}
	
	fileprivate func activateButton(_ doneFlag: inout Bool) {
		/* Flash the button */
		invertImage();
		show();
		screen.update()
		SDL_Delay(50);
		invertImage();
		show();
		screen.update()
		/* Run the callback */
		if let callback = callback {
			doneFlag = callback()
		} else {
			doneFlag = true
		}
	}
	
	deinit {
		SDL_FreeSurface(button);
	}
}

/** The only difference between this button and the `MacButton` is that
if <Return> is pressed, this button is activated.
*/
final class MacDefaultButton : MacButton {
	fileprivate var fg: UInt32 = 0
	
	override func map(offset: (x: Int32, y: Int32), screen: FrameBuf, background: (red: UInt8, green: UInt8, blue: UInt8), foreground: (red: UInt8, green: UInt8, blue: UInt8)) {
		super.map(offset: offset, screen: screen, background: background, foreground: foreground)
		fg = screen.mapRGB(tuple: foreground)
	}
	
	override func handleKeyPress(_ key: SDL_Keysym, done doneflag: inout Bool) {
		if Int(key.sym) == SDLK_RETURN {
			activateButton(&doneflag)
		}
	}
	
	override func show() {
		/* Show the normal button */
		super.show()
		
		/* Show the thick edge */
		let x = position.x-4;
		let maxx = x+4+size.width+4-1;
		let y = position.y-4;
		let maxy = y+4+size.height+4-1;
		
		screen.drawLine(x1: x+5, y1: y, x2: maxx-5, y2: y, color: fg);
		screen.drawLine(x1: x+3, y1: y+1, x2: maxx-3, y2: y+1, color: fg);
		screen.drawLine(x1: x+2, y1: y+2, x2: maxx-2, y2: y+2, color: fg);
		screen.drawLine(x1: x+1, y1: y+3, x2: x+5, y2: y+3, color: fg);
		screen.drawLine(x1: maxx-5, y1: y+3, x2: maxx-1, y2: y+3, color: fg);
		screen.drawLine(x1: x+1, y1: y+4, x2: x+3, y2: y+4, color: fg);
		screen.drawLine(x1: maxx-3, y1: y+4, x2: maxx-1, y2: y+4, color: fg);
		screen.drawLine(x1: x, y1: y+5, x2: x+3, y2: y+5, color: fg);
		screen.drawLine(x1: maxx-3, y1: y+5, x2: maxx, y2: y+5, color: fg);
		
		screen.drawLine(x1: x, y1: y+6, x2: x, y2: maxy-6, color: fg);
		screen.drawLine(x1: maxx, y1: y+6, x2: maxx, y2: maxy-6, color: fg);
		screen.drawLine(x1: x+1, y1: y+6, x2: x+1, y2: maxy-6, color: fg);
		screen.drawLine(x1: maxx-1, y1: y+6, x2: maxx-1, y2: maxy-6, color: fg);
		screen.drawLine(x1: x+2, y1: y+6, x2: x+2, y2: maxy-6, color: fg);
		screen.drawLine(x1: maxx-2, y1: y+6, x2: maxx-2, y2: maxy-6, color: fg);
		
		screen.drawLine(x1: x, y1: maxy-5, x2: x+3, y2: maxy-5, color: fg);
		screen.drawLine(x1: maxx-3, y1: maxy-5, x2: maxx, y2: maxy-5, color: fg);
		screen.drawLine(x1: x+1, y1: maxy-4, x2: x+3, y2: maxy-4, color: fg);
		screen.drawLine(x1: maxx-3, y1: maxy-4, x2: maxx-1, y2: maxy-4, color: fg);
		screen.drawLine(x1: x+1, y1: maxy-3, x2: x+5, y2: maxy-3, color: fg);
		screen.drawLine(x1: maxx-5, y1: maxy-3, x2: maxx-1, y2: maxy-3, color: fg);
		screen.drawLine(x1: x+2, y1: maxy-2, x2: maxx-2, y2: maxy-2, color: fg);
		screen.drawLine(x1: x+3, y1: maxy-1, x2: maxx-3, y2: maxy-1, color: fg);
		screen.drawLine(x1: x+5, y1: maxy, x2: maxx-5, y2: maxy, color: fg);
	}
}

/* Class of checkboxes */

let CHECKBOX_SIZE: Int32 = 12

final class MacCheckBox : MacDialog {
	fileprivate var label: UnsafeMutablePointer<SDL_Surface>?
	fileprivate var fontServ: FontServer
	fileprivate var fg: UInt32 = 0
	fileprivate var bg: UInt32 = 0
	fileprivate var sensitive = SDL_Rect()
	fileprivate var checkval: UnsafeMutablePointer<Bool>
	
	init(toggle: UnsafeMutablePointer<Bool>, x: Int32, y: Int32, text: String, font: FontServer.Font, fontserv: FontServer) {
		fontServ = fontserv
		checkval = toggle
		label = fontserv.newTextImage(text, font: font, style: [], foreground: (red: 0, green: 0, blue: 0))
		super.init(x: x, y: y)
	}
	
	override func map(offset: (x: Int32, y: Int32), screen: FrameBuf, background: (red: UInt8, green: UInt8, blue: UInt8), foreground: (red: UInt8, green: UInt8, blue: UInt8)) {
		super.map(offset: offset, screen: screen, background: background, foreground: foreground)
		
		/* Set up the checkbox sensitivity */
		sensitive.x = position.x;
		sensitive.y = position.y;
		sensitive.w = CHECKBOX_SIZE
		sensitive.h = CHECKBOX_SIZE
		
		/* Get the screen colors */
		fg = screen.mapRGB(tuple: foreground)
		bg = screen.mapRGB(tuple: background)
		
		/* Map the checkbox text */
		label?.pointee.format.pointee.palette.pointee.colors[1].r = foreground.red;
		label?.pointee.format.pointee.palette.pointee.colors[1].g = foreground.green;
		label?.pointee.format.pointee.palette.pointee.colors[1].b = foreground.blue;
	}
	
	override func handleButtonPress(x: Int32, y: Int32, button: UInt8, done doneFlag: inout Bool) {
		if isSensitive(sensitive, x: x, y: y) {
			checkval.pointee = !checkval.pointee
			checkBox(checkval.pointee)
			screen.update()
		}
	}
	
	override func show() {
		screen.drawRect(x: position.x, y: position.y, width: CHECKBOX_SIZE, height: CHECKBOX_SIZE, color: fg)
		if label != nil {
			screen.queueBlit(x: position.x + CHECKBOX_SIZE + 4, y: position.y - 2, src: label!, do_clip: .noclip)
		}
		checkBox(checkval.pointee)
	}
	
	fileprivate func checkBox(_ checked: Bool) {
		let color: UInt32
		
		if checked {
			color = fg;
		} else {
			color = bg;
		}
		
		screen.drawLine(x1: position.x, y1: position.y, x2: position.x + CHECKBOX_SIZE - 1, y2: position.y + CHECKBOX_SIZE - 1, color: color)
		screen.drawLine(x1: position.x, y1: position.y + CHECKBOX_SIZE - 1, x2: position.x + CHECKBOX_SIZE - 1, y2: position.y, color: color)
	}
	
	deinit {
		if let label = label {
			fontServ.freeText(label)
		}
	}
}

/** Class of radio buttons */
final class MacRadioList : MacDialog {
	fileprivate var radioList = [Radio]()
	fileprivate let fontServ: FontServer
	fileprivate let font: FontServer.Font
	fileprivate var fg: UInt32 = 0
	fileprivate var bg: UInt32 = 0
	fileprivate var radiovar: UnsafeMutablePointer<Int>
	
	fileprivate struct Radio {
		var label: UnsafeMutablePointer<SDL_Surface>?
		var x: Int32
		var y: Int32
		var sensitive: SDL_Rect
	}
	
	init(variable: UnsafeMutablePointer<Int>, x: Int32, y: Int32, font: FontServer.Font, fontserv: FontServer) {
		radiovar = variable
		fontServ = fontserv
		self.font = font
		super.init(x: x, y: y)
	}
	
	override func handleButtonPress(x: Int32, y: Int32, button: UInt8, done doneFlag: inout Bool) {
		let oldRadio = radioList[radiovar.pointee]
		
		for (n, radio) in radioList.enumerated() {
			if isSensitive(radio.sensitive, x: x, y: y) {
				spot(x: oldRadio.x, y: oldRadio.y, color: bg)
				radiovar.pointee = n
				spot(x: radio.x, y: radio.y, color: fg)
				screen.update()
				return
			}
		}
	}
	
	override func show() {
		for (n,radio) in radioList.enumerated() {
			circle(x: radio.x, y: radio.y)
			if n == radiovar.pointee {
				spot(x: radio.x, y: radio.y, color: fg)
			}
			if radio.label != nil {
				screen.queueBlit(x: radio.x + 21, y: radio.y + 3, src: radio.label!, do_clip: .noclip)
			}
		}
	}
	
	override func map(offset: (x: Int32, y: Int32), screen: FrameBuf, background: (red: UInt8, green: UInt8, blue: UInt8), foreground: (red: UInt8, green: UInt8, blue: UInt8)) {
		/* Do the normal dialog mapping */
		super.map(offset: offset, screen: screen, background: background, foreground: foreground)
		
		/* Get the screen colors */
		fg = screen.mapRGB(red: foreground.red, green: foreground.green, blue: foreground.blue)
		bg = screen.mapRGB(red: background.red, green: background.green, blue: background.blue);
		
		/* Adjust sensitivity and map the radiobox text */
		for i in 0..<radioList.count {
			radioList[i].x += offset.x
			radioList[i].y += offset.y
			radioList[i].sensitive.x += offset.x
			radioList[i].sensitive.y += offset.y
			radioList[i].label?.pointee.format.pointee.palette.pointee.colors[1].r = foreground.red
			radioList[i].label?.pointee.format.pointee.palette.pointee.colors[1].g = foreground.green
			radioList[i].label?.pointee.format.pointee.palette.pointee.colors[1].b = foreground.blue
		}
	}
	
	func addRadio(x: Int32, y: Int32, text: String) {
		var radio = Radio(label: fontServ.newTextImage(text, font: font, style: [],
			foreground: (red: 0, green: 0, blue: 0)), x: x, y: y, sensitive: SDL_Rect())
		radio.sensitive.x = x
		radio.sensitive.y = y
		radio.sensitive.w = 20 + radio.label!.pointee.w
		radio.sensitive.h = BOX_HEIGHT
		radioList.append(radio)
	}
	
	fileprivate func spot(x x2: Int32, y y2: Int32, color: UInt32) {
		var x = x2
		var y = y2
		x += 8;
		y += 8;
		screen.drawLine(x1: x+1, y1: y, x2: x+4, y2: y, color: color)
		y += 1
		screen.drawLine(x1: x, y1: y, x2: x+5, y2: y, color: color)
		y += 1;
		screen.drawLine(x1: x, y1: y, x2: x+5, y2: y, color: color);
		y += 1;
		screen.drawLine(x1: x, y1: y, x2: x+5, y2: y, color: color);
		y += 1;
		screen.drawLine(x1: x, y1: y, x2: x+5, y2: y, color: color);
		y += 1;
		screen.drawLine(x1: x+1, y1: y, x2: x+4, y2: y, color: color);
	}
	
	fileprivate func circle(x x2: Int32, y y2: Int32) {
		var x = x2
		var y = y2
		x += 5;
		y += 5;
		screen.drawLine(x1: x+4, y1: y, x2: x+7, y2: y, color: fg);
		screen.drawLine(x1: x+2, y1: y+1, x2: x+3, y2: y+1, color: fg);
		screen.drawLine(x1: x+8, y1: y+1, x2: x+9, y2: y+1, color: fg);
		screen.drawLine(x1: x+1, y1: y+2, x2: x+1, y2: y+3, color: fg);
		screen.drawLine(x1: x+10, y1: y+2, x2: x+10, y2: y+3, color: fg);
		screen.drawLine(x1: x, y1: y+4, x2: x, y2: y+7, color: fg);
		screen.drawLine(x1: x+11, y1: y+4, x2: x+11, y2: y+7, color: fg);
		screen.drawLine(x1: x+1, y1: y+8, x2: x+1, y2: y+9, color: fg);
		screen.drawLine(x1: x+10, y1: y+8, x2: x+10, y2: y+9, color: fg);
		screen.drawLine(x1: x+2, y1: y+10, x2: x+3, y2: y+10, color: fg);
		screen.drawLine(x1: x+8, y1: y+10, x2: x+9, y2: y+10, color: fg);
		screen.drawLine(x1: x+4, y1: y+11, x2: x+7, y2: y+11, color: fg);
	}
	
	deinit {
		for radio in radioList {
			if let radioLbl = radio.label {
				fontServ.freeText(radioLbl)
			}
		}
	}
}

/** Class of text entry boxes */
final class MacTextEntry : MacDialog {
	fileprivate let fontServ: FontServer
	fileprivate let font: FontServer.Font
	fileprivate var fg: UInt32 = 0
	fileprivate var bg: UInt32 = 0
	fileprivate var cWidth: Int32
	fileprivate var cHeight: Int32
	fileprivate var foreground = SDL_Color(r: 0, g: 0, b: 0, a: 255)
	fileprivate var background = SDL_Color(r: 0, g: 0, b: 0, a: 255)
	fileprivate var entryList = [TextEntry]()
	fileprivate var currentEntry = 0
	
	fileprivate class TextEntry {
		var text: UnsafeMutablePointer<SDL_Surface>? = nil
		var variable: String = ""
		var sensitive = SDL_Rect()
		var location: (x: Int32, y: Int32) = (0,0)
		var size: (width: Int32, height: Int32) = (0,0)
		var end: Int32 = 0
		var hilite: Bool = false
	}
	
	init(x: Int32, y: Int32, font: FontServer.Font, fontserv: FontServer) {
		fontServ = fontserv
		self.font = font
		let tmpSize = fontserv.textSize("0", font: font, style: [])
		(cWidth, cHeight) = (Int32(tmpSize.width), Int32(tmpSize.height))
		super.init(x: x, y: y)
		MacDialog.enableText()
	}
	
	deinit {
		for entry in entryList {
			if let entryTxt = entry.text {
				fontServ.freeText(entryTxt)
			}
		}
		MacDialog.disableText()
	}
	
	override func handleButtonPress(x: Int32, y: Int32, button: UInt8, done doneFlag: inout Bool) {
		for (i,entry) in entryList.enumerated() {
			if isSensitive(entry.sensitive, x: x, y: y) {
				entryList[currentEntry].hilite = false
				
				updateEntry(entryList[currentEntry])
				currentEntry = i
				drawCursor(entry);
				screen.update()
				return
			}
		}
	}
	
	override func handleKeyPress(_ key: SDL_Keysym, done doneflag: inout Bool) {
		switch key.sym {
		case SDLK_TAB:
			entryList[currentEntry].hilite = false;
			updateEntry(entryList[currentEntry]);
			if currentEntry >= entryList.count {
				currentEntry += 1
			} else {
				currentEntry = 0
			}
			entryList[currentEntry].hilite = true;
			updateEntry(entryList[currentEntry]);
			
		case SDLK_DELETE, SDLK_BACKSPACE:
			if entryList[currentEntry].hilite {
				entryList[currentEntry].variable = ""
				entryList[currentEntry].hilite = false
			} else if entryList[currentEntry].variable.count > 0 {
				entryList[currentEntry].variable = String(entryList[currentEntry].variable.dropLast())
			}
			updateEntry(entryList[currentEntry]);
			drawCursor(entryList[currentEntry]);
			
		default:
			guard (entryList[currentEntry].end + cWidth) <= entryList[currentEntry].size.width else {
				return;
			}
			entryList[currentEntry].hilite = false
			entryList[currentEntry].variable += String(cString: [Int8(key.sym),0])
			updateEntry(entryList[currentEntry])
			drawCursor(entryList[currentEntry])
		}
		
		screen.update()
	}
	
	func addEntry(x: Int32, y: Int32, width: Int32, isDefault: Bool, variable: UnsafeMutablePointer<Int8>) {
		let entry = TextEntry()
		
		if isDefault {
			currentEntry = entryList.count
			entry.hilite = true;
		} else {
			entry.hilite = false;
		}

		entry.location = (x + 3, y + 3)
		entry.size = (width * cWidth, cHeight)
		entry.sensitive.x = x;
		entry.sensitive.y = y;
		entry.sensitive.w = 3+(width*cWidth)+3;
		entry.sensitive.h = 3+cHeight+3;
		entry.text = nil
		entryList.append(entry)
	}
	
	override func map(offset: (x: Int32, y: Int32), screen: FrameBuf, background backG: (red: UInt8, green: UInt8, blue: UInt8), foreground foreG: (red: UInt8, green: UInt8, blue: UInt8)) {
		/* Do the normal dialog mapping */
		super.map(offset: offset, screen: screen, background: backG, foreground: foreG)
		
		/* Get the screen colors */
		(foreground.r, foreground.g, foreground.b) = foreG
		(background.r, background.g, background.b) = backG
		fg = screen.mapRGB(tuple: foreG)
		bg = screen.mapRGB(tuple: backG)
		
		/* Adjust sensitivity and map the radiobox text */
		for entry in entryList {
			entry.location.x += offset.x
			entry.location.y += offset.y
			entry.sensitive.x += offset.x
			entry.sensitive.y += offset.y
		}
	}
	
	override func show() {
		for entry in entryList {
			screen.drawRect(x: entry.location.x - 3, y: entry.location.y - 3, width: 3 + entry.size.width, height: 3 + cHeight + 3, color: fg)
			updateEntry(entry)
		}
	}
	
	fileprivate func updateEntry(_ entry: TextEntry) {
		var clear: Uint32 = 0
		
		/* Create the new entry text */
		if let entryTxt = entry.text {
			fontServ.freeText(entryTxt)
			entry.text = nil
		}
		if entry.hilite {
			clear = fg;
			entry.text = fontServ.newTextImage(entry.variable, font: font,
				style: [], foreground: background, background: foreground)
		} else {
			clear = bg;
			entry.text = fontServ.newTextImage(entry.variable,
			font: font, style: [], foreground: foreground, background: background);
		}
		screen.fillRect(x: entry.location.x, y: entry.location.y,
		w: entry.size.width, h: entry.size.height, color: clear);
		if ( entry.text != nil ) {
			entry.end = (entry.text?.pointee.w)!;
			screen.queueBlit(x: entry.location.x, y: entry.location.y, src: entry.text!, do_clip: .noclip);
		} else {
			entry.end = 0;
		}
	}
	
	fileprivate func drawCursor(_ entry: TextEntry) {
		screen.drawLine(x1: entry.location.x + entry.end, y1: entry.location.y,
			x2: entry.location.x + entry.end, y2: entry.location.y + entry.size.height - 1,
			color: fg)
	}
}

/** Class of numeric entry boxes */
final class MacNumericEntry: MacDialog {
	fileprivate var entryList = [NumericEntry]()
	fileprivate let fontServ: FontServer
	fileprivate let font: FontServer.Font
	fileprivate var fg: UInt32 = 0
	fileprivate var bg: UInt32 = 0
	fileprivate var cWidth: Int32
	fileprivate var cHeight: Int32
	fileprivate var foreground = SDL_Color(r: 0, g: 0, b: 0, a: 255)
	fileprivate var background = SDL_Color(r: 0, g: 0, b: 0, a: 255)
	fileprivate var currentEntry = 0
	fileprivate var current: NumericEntry {
		return entryList[currentEntry]
	}

	fileprivate class NumericEntry {
		var text: UnsafeMutablePointer<SDL_Surface>? = nil
		var variable: UnsafeMutablePointer<Int>? = nil
		var sensitive = SDL_Rect()
		var location: (x: Int32, y: Int32) = (0,0)
		var size: (width: Int32, height: Int32) = (0,0)
		var end: Int32 = 0
		var hilite: Bool = false
	}

	init(x: Int32, y: Int32, font: FontServer.Font, fontserv: FontServer) {
		fontServ = fontserv
		self.font = font
		let tmpSize = fontserv.textSize("0", font: font, style: [])
		(cWidth, cHeight) = (Int32(tmpSize.width), Int32(tmpSize.height))
		super.init(x: x, y: y)
	}
	
	deinit {
		for entry in entryList {
			if let entryTxt = entry.text {
				fontServ.freeText(entryTxt)
			}
		}
	}
	
	override func handleButtonPress(x: Int32, y: Int32, button: UInt8, done doneFlag: inout Bool) {
		for (i,entry) in entryList.enumerated() {
			if isSensitive(entry.sensitive, x: x, y: y) {
				current.hilite = false
				updateEntry(current);
				currentEntry = i
				drawCursor(current);
				screen.update();
			}
		}
	}
	
	override func handleKeyPress(_ key: SDL_Keysym, done doneflag: inout Bool) {
		switch key.sym {
		case SDLK_TAB:
			current.hilite = false
			updateEntry(current);
			if currentEntry <= entryList.count {
				currentEntry += 1;
			} else {
				currentEntry=0;
			}
			current.hilite = true
			updateEntry(current);
			break;
			
		case SDLK_DELETE, SDLK_BACKSPACE:
			if ( current.hilite ) {
				current.variable?.pointee = 0
				current.hilite = false
			} else {
				current.variable?.pointee /= 10
			}
			updateEntry(current);
			drawCursor(current);
			break;
			
		case SDLK_0...SDLK_9:
			let n = key.sym - SDLK_0
			guard current.end + cWidth <= current.size.width else {
				return
			}
			if current.hilite {
				current.variable?.pointee = Int(n)
				current.hilite = false
			} else {
				current.variable?.pointee *= 10;
				current.variable?.pointee += Int(n);
			}
			updateEntry(current);
			drawCursor(current);
			break;
			
		default:
			break;
		}
		screen.update();
	}
	
	func addEntry(x: Int32, y: Int32, width: Int32, isDefault: Bool, variable: UnsafeMutablePointer<Int>) {
		let entry = NumericEntry()
		entryList.append(entry)
		entry.variable = variable
		if isDefault {
			currentEntry = entryList.count - 1
			entry.hilite = true
		} else {
			entry.hilite = false
		}
		entry.location = (x + 3, y + 3)
		entry.size = (width * cWidth, cHeight)
		entry.sensitive = SDL_Rect(x: x, y: y, w: 3 + width * cWidth + 3, h: 3 + cHeight + 3)
		entry.text = nil
	}
	
	override func map(offset: (x: Int32, y: Int32), screen: FrameBuf, background backG: (red: UInt8, green: UInt8, blue: UInt8), foreground foreG: (red: UInt8, green: UInt8, blue: UInt8)) {
		/* Do the normal dialog mapping */
		super.map(offset: offset, screen: screen, background: backG, foreground: foreG)
		
		/* Get the screen colors */
		(foreground.r, foreground.g, foreground.b) = foreG;
		(background.r, background.g, background.b) = backG;
		fg = screen.mapRGB(tuple: foreG)
		bg = screen.mapRGB(tuple: backG)
		
		/* Adjust sensitivity and map the radiobox text */
		for entry in entryList {
			entry.location.x += offset.x;
			entry.location.y += offset.y
			entry.sensitive.x += offset.x
			entry.sensitive.y += offset.y
		}
	}
	
	override func show() {
		for entry in entryList {
			screen.drawRect(x: entry.location.x - 3, y: entry.location.y - 3, width: 3 + entry.size.width + 3, height: 3 + cHeight + 3, color: fg)
			updateEntry(entry)
		}
	}
	
	fileprivate func updateEntry(_ entry: NumericEntry) {
		var buf = "";
		var clear: Uint32
		
		/* Create the new entry text */
		if let entryTxt = entry.text {
			fontServ.freeText(entryTxt);
		}
		buf = String(describing: entry.variable?.pointee)
		
		if entry.hilite {
			clear = fg;
			entry.text = fontServ.newTextImage(buf, font: font,
				style: [], foreground: background, background: foreground);
		} else {
			clear = bg;
			entry.text = fontServ.newTextImage(buf, font: font,
				style: [], foreground: foreground, background: background);
		}
		entry.end = (entry.text?.pointee.w)!;
		screen.fillRect(x: entry.location.x, y: entry.location.y,
		w: entry.size.width, h: entry.size.height, color: clear);
		screen.queueBlit(x: entry.location.x, y: entry.location.y, src: entry.text!, do_clip: .noclip);
	}
	
	fileprivate func drawCursor(_ entry: NumericEntry) {
		screen.drawLine(x1: entry.location.x + entry.end, y1: entry.location.y, x2: entry.location.x + entry.end, y2: entry.location.y + entry.size.height - 1, color: fg)
	}
}

/** Finally, the macintosh-like dialog class */
final class MaclikeDialog {
	fileprivate var screen: FrameBuf
	fileprivate var location: (x: Int32, y: Int32)
	fileprivate var size: (width: Int32, height: Int32)
	
	convenience init(x: Int, y: Int, width: Int, height: Int, screen: FrameBuf) {
		self.init(x: Int32(x), y: Int32(y), width: Int32(width), height: Int32(height), screen: screen)
	}
	
	init(x: Int32, y: Int32, width: Int32, height: Int32, screen: FrameBuf) {
		location = (x, y)
		size = (width, height)
		self.screen = screen
	}
	
	func addRectangle(x: Int, y: Int, w: Int, h: Int, color: UInt32) {
		let newElement = RectElement(x: Int16(x), y: Int16(y), w: UInt16(w), h: UInt16(h), color: color)
		rectList.append(newElement)
	}
	
	func addImage(_ image: UnsafeMutablePointer<SDL_Surface>, x: Int32, y: Int32) {
		let newElement = ImageElement(image: image, x: x, y: y)
		imageList.append(newElement)
	}
	
	func addImage(_ image: UnsafeMutablePointer<SDL_Surface>, x: Int, y: Int) {
		addImage(image, x: Int32(x), y: Int32(x))
	}
	
	func addDialog(_ dialog: MacDialog) {
		dialogList.append(dialog)
	}
	
	/// The big Kahones
	func run(_ expandSteps: Int = 1) {
		var savedfg: UnsafeMutablePointer<SDL_Surface>? = nil
		var savedbg: UnsafeMutablePointer<SDL_Surface>? = nil
		var event = SDL_Event()
		var maxX: Int32 = 0
		var maxY: Int32 = 0
		var XX = 0.0
		var YY = 0.0
		var H = 0.0
		var Hstep = 0.0
		var V = 0.0
		var Vstep = 0.0
		
		/* Save the area behind the dialog box */
		savedfg = screen.grabArea(x: UInt16(location.x), y: UInt16(location.y), w: UInt16(size.width), h: UInt16(size.height))
		screen.focusBG()
		savedbg = screen.grabArea(x: UInt16(location.x), y: UInt16(location.y), w: UInt16(size.width), h: UInt16(size.height))
		
		/* Show the dialog box with the nice Mac border */
		let black = screen.mapRGB(red: 0x00, green: 0x00, blue: 0x00);
		let dark = screen.mapRGB(red: 0x66, green: 0x66, blue: 0x99);
		let medium = screen.mapRGB(red: 0xBB, green: 0xBB, blue: 0xBB);
		let light = screen.mapRGB(red: 0xCC, green: 0xCC, blue: 0xFF);
		let white = screen.mapRGB(red: 0xFF, green: 0xFF, blue: 0xFF);
		maxX = location.x+size.width-1;
		maxY = location.y+size.height-1;
		screen.drawLine(x1: location.x, y1: location.y, x2: maxX, y2: location.y, color: light);
		screen.drawLine(x1: location.x, y1: location.y, x2: location.x, y2: maxY, color: light);
		screen.drawLine(x1: location.x, y1: maxY, x2: maxX, y2: maxY, color: dark);
		screen.drawLine(x1: maxX, y1: location.y, x2: maxX, y2: maxY, color: dark);
		screen.drawRect(x: location.x+1, y: location.y+1, width: size.width-2, height: size.height-2, color: medium);
		screen.drawLine(x1: location.x+2, y1: location.y+2, x2: maxX-2, y2: location.y+2, color: dark);
		screen.drawLine(x1: location.x+2, y1: location.y+2, x2: location.x+2, y2: maxY-2, color: dark);
		screen.drawLine(x1: location.x+3, y1: maxY-2, x2: maxX-2, y2: maxY-2, color: light);
		screen.drawLine(x1: maxX-2, y1: location.y+3, x2: maxX-2, y2: maxY-2, color: light);
		screen.drawRect(x: location.x+3, y: location.y+3, width: size.width-6, height: size.height-6, color: black);
		screen.fillRect(x: location.x+4, y: location.y+4, w: size.width-8, h: size.height-8, color: white);
		screen.focusFG()
		
		/* Allow the dialog to expand slowly */
		XX = Double(location.x+size.width/2);
		YY = Double(location.y+size.height/2);
		Hstep = Double(size.width) / Double(expandSteps)
		Vstep = Double(size.height) / Double(expandSteps)
		for _ in 0..<expandSteps {
			H += Hstep;
			XX -= Hstep/2;
			V += Vstep;
			YY -= Vstep/2;
			if XX < Double(location.x) {
				XX = Double(location.x)
			}
			if YY < Double(location.y) {
				YY = Double(location.y)
			}
			if ( H > Double(size.width) ) {
				H = Double(size.width)
			}
			if V > Double(size.height) {
				V = Double(size.height)
			}
			screen.clear(x: Int16(XX), y: Int16(YY), w: UInt16(size.width), h: UInt16(size.height))
			screen.update();
		}
		screen.clear(x: Int16(location.x), y: Int16(location.y), w: UInt16(size.width), h: UInt16(size.height))
		screen.update();
		
		/* Draw the dialog elements (after the slow expand) */
		for relem in rectList {
			screen.drawRect(x: location.x+4+Int32(relem.x), y: location.y+4+Int32(relem.y),
				width: Int32(relem.w), height: Int32(relem.h), color: relem.color);
		}
		for ielem in imageList {
			screen.queueBlit(x: location.x + 4 + ielem.x, y: location.y + 4 + ielem.y, src: ielem.image, do_clip: .noclip)
		}
		for delem in dialogList {
			delem.map(offset: (location.x + 4, location.y + 4), screen: screen,
				background: (0xFF,  0xFF, 0xFF), foreground: (0x00, 0x00, 0x00))
			delem.show()
		}
		screen.update();
		
		var done = false
		/* Wait until the dialog box is done */
		while !done {
			screen.waitEvent(&event);
			
			switch (event.type) {
				/* -- Handle mouse clicks */
			case .MOUSEBUTTONDOWN:
				
				for dialog in dialogList {
					dialog.handleButtonPress(x: event.button.x,
						y: event.button.y, button: event.button.button, done: &done)
				}
				/* -- Handle key presses */
			case .KEYDOWN:
				for dialog in dialogList {
					dialog.handleKeyPress(event.key.keysym, done: &done)
				}
				
			default:
				break;
			}
		}
		
		/* Replace the old section of screen */
		if let savedbg = savedbg {
			screen.focusBG();
			screen.queueBlit(x: location.x, y: location.y, src: savedbg, do_clip: .noclip);
			screen.update();
			screen.focusFG();
			screen.freeImage(savedbg);
		}
		if let savedfg = savedfg {
			screen.queueBlit(x: location.x, y: location.y, src: savedfg, do_clip: .noclip);
			screen.update();
			screen.freeImage(savedfg);
		}
	}
	
	fileprivate struct RectElement {
		var x: Int16
		var y: Int16
		var w: UInt16
		var h: UInt16
		var color: UInt32
	}
	
	fileprivate struct ImageElement {
		var image: UnsafeMutablePointer<SDL_Surface>
		var x: Int32
		var y: Int32
	}
	
	fileprivate var rectList = [RectElement]()
	fileprivate var imageList = [ImageElement]()
	fileprivate var dialogList = [MacDialog]()
}
