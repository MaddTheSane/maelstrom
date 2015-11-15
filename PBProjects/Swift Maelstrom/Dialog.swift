//
//  Dialog.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/12/15.
//
//

import Foundation


/*  This is a class set for Macintosh-like dialogue boxes. :) */
/*  Sorta complex... */

/* Defaults for various dialog classes */

let BUTTON_WIDTH = 75
let BUTTON_HEIGHT = 19

let BOX_WIDTH = 170
let BOX_HEIGHT = 20

let EXPAND_STEPS = 50


/** Utility routine for dialogs */
private func isSensitive(area: SDL_Rect, x: Int32, y: Int32) -> Bool {
	if (y > area.y) && (y < (area.y+area.h)) &&
		(x > area.x) && (x < (area.x+area.w)) {
			return true
	}
	return false
}


class MacDialog {
	private static var textEnabled = false
	private var screen: FrameBuf!
	private var position: (x: Int32, y: Int32)
	typealias ButtonCallbackFunc = (x: Int32, y: Int32, button: UInt8, inout done: Bool) -> Void
	typealias KeyCallbackFunc = (key: SDL_Keysym, inout doneflag: Bool) -> Void
	
	private var buttonCallback: ButtonCallbackFunc?
	private var keyCallback: KeyCallbackFunc?
	
	private(set) var error: String?
	
	init(x: Int32, y: Int32) {
		position = (x, y)
	}
	
	//MARK: - Input handling
	
	func setButtonPress(newButtonCallback: ButtonCallbackFunc?) {
		buttonCallback = newButtonCallback
	}
	
	func handleButtonPress(x x: Int32, y: Int32, button: UInt8, inout doneFlag: Bool) {
		buttonCallback?(x: x, y: y, button: button, done: &doneFlag)
	}
	
	func setKeyPress(newKeyCallback: KeyCallbackFunc?) {
		keyCallback = newKeyCallback
	}
	
	func handleKeyPress(key: SDL_Keysym, inout done doneflag: Bool) {
		keyCallback?(key: key, doneflag: &doneflag)
	}
	
	//MARK: - Display handling
	
	func map(offset offset: (x: Int32, y: Int32), screen: FrameBuf, background: (red: UInt8, green: UInt8, blue: UInt8), foreground: (red: UInt8, green: UInt8, blue: UInt8)) {
		position.x += offset.x
		position.y += offset.y
		self.screen = screen
	}
	
	final func map(xOff xOff: Int32, yOff: Int32, screen: FrameBuf, r_bg: UInt8, g_bg: UInt8, b_bg: UInt8, r_fg: UInt8, g_fg: UInt8, b_fg: UInt8) {
		self.map(offset: (xOff, yOff), screen: screen, background: (r_bg, g_bg, b_bg), foreground: (r_fg, g_fg, b_fg))
	}
	
	func show() {
		//empty, for subclassing
	}
}

/** The button callbacks should return `1` if they finish the dialog,
or `0` if they do not.
*/
class MacButton : MacDialog {
	private var size: (width: Int32, height: Int32)
	//int Width, Height;
	private var button: UnsafeMutablePointer<SDL_Surface>
	private var callback: buttonCallback?
	private var sensitive = SDL_Rect()
	typealias buttonCallback = () -> Bool
	
	enum Errors: ErrorType {
		case SDLError(String)
	}
	
	init(x: Int32, y: Int32, width: Int32, height: Int32, text: String, font: FontServ.MFont, fontserv: FontServ, callback: buttonCallback?) throws {
		size = (width, height)
		button = SDL_CreateRGBSurface(0, width, height,
			8, 0, 0, 0, 0);

		super.init(x: x, y: y)

		guard button != nil else {
			throw Errors.SDLError(String(SDL_GetError()))
		}
		
		//var textb = UnsafeMutablePointer<SDL_Surface>()
		var dstrect = SDL_Rect()
		
		button.memory.format.memory.palette.memory.colors[0].r = 0xFF;
		button.memory.format.memory.palette.memory.colors[0].g = 0xFF;
		button.memory.format.memory.palette.memory.colors[0].b = 0xFF;
		button.memory.format.memory.palette.memory.colors[1].r = 0x00;
		button.memory.format.memory.palette.memory.colors[1].g = 0x00;
		button.memory.format.memory.palette.memory.colors[1].b = 0x00;
		
		let textb = fontserv.newTextImage(text, font: font, style: [], foreground: (red: 0, green: 0, blue: 0))
		if textb != nil {
			if (textb.memory.w <= button.memory.w) &&
				(textb.memory.h <= button.memory.h) {
					dstrect.x = (button.memory.w-textb.memory.w)/2;
					dstrect.y = (button.memory.h-textb.memory.h)/2;
					dstrect.w = textb.memory.w;
					dstrect.h = textb.memory.h;
					SDL_UpperBlit(textb, nil, button, &dstrect);
			}

			fontserv.freeText(textb)
		}
		bevelButton(button);
		
		/* Set the callback */
		self.callback = callback
	}
	
	private func bevelButton(image: UnsafeMutablePointer<SDL_Surface>) {
		var image_bits = UnsafeMutablePointer<UInt8>(image.memory.pixels)
		
		/* Bevel upper corners */
		memset(image_bits+3, 0x01, image.memory.w-6);
		image_bits += Int(image.memory.pitch)
		memset(image_bits+1, 0x01, 2);
		memset(image_bits.advancedBy(image.memory.w-3), 0x01, 2);
		image_bits += Int(image.memory.pitch);
		memset(image_bits+1, 0x01, 1);
		memset(image_bits.advancedBy(image.memory.w-2), 0x01, 1);
		image_bits += Int(image.memory.pitch);
		
		/* Draw sides */
		//for ( h=3; h < Int(image.memory.h-3); ++h ) {
		for _ in 3..<(image.memory.h - 3) {
			image_bits[0] = 0x01;
			image_bits[Int(image.memory.w-1)] = 0x01;
			image_bits += Int(image.memory.pitch)
		}
		
		/* Bevel bottom corners */
		memset(image_bits+1, 0x01, 1);
		memset(image_bits.advancedBy(image.memory.w - 2), 0x01, 1);
		image_bits += Int(image.memory.pitch)
		memset(image_bits+1, 0x01, 2);
		memset(image_bits+Int(image.memory.w-3), 0x01, 2);
		image_bits += Int(image.memory.pitch);
		memset(image_bits+3, 0x01, image.memory.w-6);
	}
	
	override func show() {
		screen.queueBlit(x: position.x, y: position.y, src: button, do_clip: .NOCLIP);
	}
	
	override func map(offset offset: (x: Int32, y: Int32), screen: FrameBuf, background: (red: UInt8, green: UInt8, blue: UInt8), foreground: (red: UInt8, green: UInt8, blue: UInt8)) {
		super.map(offset: offset, screen: screen, background: background, foreground: foreground)
		
		/* Set up the button sensitivity */
		sensitive.x = position.x;
		sensitive.y  = position.y;
		sensitive.w = size.width;
		sensitive.h = size.height;
		
		/* Map the bitmap image */
		button.memory.format.memory.palette.memory.colors[0].r = background.red;
		button.memory.format.memory.palette.memory.colors[0].g = background.green;
		button.memory.format.memory.palette.memory.colors[0].b = background.blue;
		button.memory.format.memory.palette.memory.colors[1].r = foreground.red;
		button.memory.format.memory.palette.memory.colors[1].g = foreground.green;
		button.memory.format.memory.palette.memory.colors[1].b = foreground.blue;
	}
	
	final private func invertImage() {
		let buttonPixels = UnsafeMutableBufferPointer(start: UnsafeMutablePointer<UInt8>(button.memory.pixels), count: Int(button.memory.h * button.memory.pitch))
		
		for (i,buf) in buttonPixels.enumerate() {
			if buf == 0 {
				buttonPixels[i] = 1
			} else {
				buttonPixels[i] = 0
			}
		}
	}
	
	override final func handleButtonPress(x x: Int32, y: Int32, button: UInt8, inout doneFlag: Bool) {
		if isSensitive(sensitive, x: x, y: y) {
			activateButton(&doneFlag)
		}
	}
	
	private func activateButton(inout doneFlag: Bool) {
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
	private var fg: UInt32 = 0
	
	override func map(offset offset: (x: Int32, y: Int32), screen: FrameBuf, background: (red: UInt8, green: UInt8, blue: UInt8), foreground: (red: UInt8, green: UInt8, blue: UInt8)) {
		super.map(offset: offset, screen: screen, background: background, foreground: foreground)
		fg = screen.mapRGB(rgb: foreground)
	}
	
	override func handleKeyPress(key: SDL_Keysym, inout done doneflag: Bool) {
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
	private var label: UnsafeMutablePointer<SDL_Surface>
	private var fontServ: FontServ
	private var fg: UInt32 = 0
	private var bg: UInt32 = 0
	private var sensitive = SDL_Rect()
	private var checkval: UnsafeMutablePointer<Bool>
	
	init(toggle: UnsafeMutablePointer<Bool>, x: Int32, y: Int32, text: String, font: FontServ.MFont, fontserv: FontServ) {
		fontServ = fontserv
		checkval = toggle
		label = fontserv.newTextImage(text, font: font, style: [], foreground: (red: 0, green: 0, blue: 0))
		super.init(x: x, y: y)
	}
	override func map(offset offset: (x: Int32, y: Int32), screen: FrameBuf, background: (red: UInt8, green: UInt8, blue: UInt8), foreground: (red: UInt8, green: UInt8, blue: UInt8)) {
		super.map(offset: offset, screen: screen, background: background, foreground: foreground)
		
		/* Set up the checkbox sensitivity */
		sensitive.x = position.x;
		sensitive.y = position.y;
		sensitive.w = Int32(CHECKBOX_SIZE)
		sensitive.h = Int32(CHECKBOX_SIZE);
		
		/* Get the screen colors */
		fg = screen.mapRGB(rgb: foreground)
		bg = screen.mapRGB(rgb: background)
		
		/* Map the checkbox text */
		label.memory.format.memory.palette.memory.colors[1].r = foreground.red;
		label.memory.format.memory.palette.memory.colors[1].g = foreground.green;
		label.memory.format.memory.palette.memory.colors[1].b = foreground.blue;
	}
	
	override func handleButtonPress(x x: Int32, y: Int32, button: UInt8, inout doneFlag: Bool) {
		if isSensitive(sensitive, x: x, y: y) {
			checkval.memory = !checkval.memory
			checkBox(checkval.memory)
			screen.update()
		}
	}
	
	override func show() {
		screen.drawRect(x: position.x, y: position.y, width: CHECKBOX_SIZE, height: CHECKBOX_SIZE, color: fg)
		if label != nil {
			screen.queueBlit(x: position.x + CHECKBOX_SIZE + 4, y: position.y - 2, src: label, do_clip: .NOCLIP)
		}
		checkBox(checkval.memory)
	}
	
	private func checkBox(checked: Bool) {
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
		if label != nil {
			fontServ.freeText(label)
		}
	}
}

/** Class of radio buttons */
final class MacRadioList : MacDialog {
	private var radioList = [Radio]()
	private struct Radio {
		var label: UnsafeMutablePointer<SDL_Surface>
		var x: Int32
		var y: Int32
		var sensitive: SDL_Rect
	}
	
	init(variable: UnsafeMutablePointer<Int>, x: Int32, y: Int32, font: FontServ.MFont, fontserv: FontServ) {
		super.init(x: x, y: y)
	}

	/*
Mac_RadioList::Mac_RadioList(int *variable, int x, int y,
MFont *font, FontServ *fontserv) : Mac_Dialog(x, y)
{
Fontserv = fontserv;
Font = font;
radiovar = variable;
*radiovar = 0;
radio_list.next = NULL;
}

*/

}
/*
class Mac_RadioList : public Mac_Dialog {

public:
Mac_RadioList(int *variable, int x, int y,
MFont *font, FontServ *fontserv);
virtual ~Mac_RadioList() {
struct radio *radio, *old;

for ( radio=radio_list.next; radio; ) {
old = radio;
radio = radio->next;
if ( old->label )
Fontserv->FreeText(old->label);
delete old;
}
}

virtual void HandleButtonPress(int x, int y, int button,
int *doneflag) {
int n;
struct radio *radio, *oldradio;

oldradio = radio_list.next;
for (n=0, radio=radio_list.next; radio; radio=radio->next, ++n){
if ( n == *radiovar ) {
oldradio = radio;
break;
}
}
for (n=0, radio=radio_list.next; radio; radio=radio->next, ++n){
if ( IsSensitive(&radio->sensitive, x, y) ) {
Spot(oldradio->x, oldradio->y, Bg);
*radiovar = n;
Spot(radio->x, radio->y, Fg);
Screen->Update();
}
}
}

virtual void Add_Radio(int x, int y, const char *text) {
struct radio *radio;

for ( radio=&radio_list; radio->next; radio=radio->next )
/* Loop to end of radio box list */;
/* Which is ANSI C++? */
#ifdef linux
radio->next = new struct Mac_RadioList::radio;
#else
radio->next = new struct radio;
#endif
radio = radio->next;
radio->label = Fontserv->TextImage(text, Font,
STYLE_NORM, 0, 0, 0);
radio->x = x;
radio->y = y;
radio->sensitive.x = x;
radio->sensitive.y = y;
radio->sensitive.w = 20+radio->label->w;
radio->sensitive.h = BOX_HEIGHT;
radio->next = NULL;
}

virtual void Map(int Xoff, int Yoff, FrameBuf *screen,
Uint8 R_bg, Uint8 G_bg, Uint8 B_bg,
Uint8 R_fg, Uint8 G_fg, Uint8 B_fg) {
struct radio *radio;

/* Do the normal dialog mapping */
Mac_Dialog::Map(Xoff, Yoff, screen,
R_bg, G_bg, B_bg, R_fg, G_fg, B_fg);

/* Get the screen colors */
Fg = Screen->MapRGB(R_fg, G_fg, B_fg);
Bg = Screen->MapRGB(R_bg, G_bg, B_bg);

/* Adjust sensitivity and map the radiobox text */
for ( radio=radio_list.next; radio; radio=radio->next ) {
radio->x += Xoff;
radio->y += Yoff;
radio->sensitive.x += Xoff;
radio->sensitive.y += Yoff;
radio->label->format->palette->colors[1].r = R_fg;
radio->label->format->palette->colors[1].g = G_fg;
radio->label->format->palette->colors[1].b = B_fg;
}
}
virtual void Show(void) {
int n;
struct radio *radio;

for (n=0, radio=radio_list.next; radio; radio=radio->next, ++n){
Circle(radio->x, radio->y);
if ( n == *radiovar ) {
Spot(radio->x, radio->y, Fg);
}
if ( radio->label ) {
Screen->QueueBlit(radio->x+21, radio->y+3,
radio->label, NOCLIP);
}
}
}

private:
FontServ *Fontserv;
MFont *Font;
Uint32 Fg, Bg;
int *radiovar;

void Circle(int x, int y) {
x += 5;
y += 5;
Screen->DrawLine(x+4, y, x+7, y, Fg);
Screen->DrawLine(x+2, y+1, x+3, y+1, Fg);
Screen->DrawLine(x+8, y+1, x+9, y+1, Fg);
Screen->DrawLine(x+1, y+2, x+1, y+3, Fg);
Screen->DrawLine(x+10, y+2, x+10, y+3, Fg);
Screen->DrawLine(x, y+4, x, y+7, Fg);
Screen->DrawLine(x+11, y+4, x+11, y+7, Fg);
Screen->DrawLine(x+1, y+8, x+1, y+9, Fg);
Screen->DrawLine(x+10, y+8, x+10, y+9, Fg);
Screen->DrawLine(x+2, y+10, x+3, y+10, Fg);
Screen->DrawLine(x+8, y+10, x+9, y+10, Fg);
Screen->DrawLine(x+4, y+11, x+7, y+11, Fg);
}
void Spot(int x, int y, Uint32 color)
{
x += 8;
y += 8;
Screen->DrawLine(x+1, y, x+4, y, color);
++y;
Screen->DrawLine(x, y, x+5, y, color);
++y;
Screen->DrawLine(x, y, x+5, y, color);
++y;
Screen->DrawLine(x, y, x+5, y, color);
++y;
Screen->DrawLine(x, y, x+5, y, color);
++y;
Screen->DrawLine(x+1, y, x+4, y, color);
}
};
*/

/** Class of text entry boxes */
final class MacTextEntry : MacDialog {
	
	
	
	init(x: Int32, y: Int32, font: FontServ.MFont, fontserv: FontServ) {
		super.init(x: x, y: y)
	}
	/*
Mac_TextEntry::Mac_TextEntry(int x, int y,
MFont *font, FontServ *fontserv) : Mac_Dialog(x, y)
{
Fontserv = fontserv;
Font = font;
Cwidth = Fontserv->TextWidth("0", Font, STYLE_NORM);
Cheight = Fontserv->TextHeight(font);
entry_list.next = NULL;
current = &entry_list;
EnableText();
}

*/
}

/*
class Mac_TextEntry : public Mac_Dialog {

public:
Mac_TextEntry(int x, int y, MFont *font, FontServ *fontserv);
virtual ~Mac_TextEntry() {
struct text_entry *entry, *old;

for ( entry=entry_list.next; entry; ) {
old = entry;
entry = entry->next;
if ( old->text )
Fontserv->FreeText(old->text);
delete old;
}
DisableText();
}

virtual void HandleButtonPress(int x, int y, int button,
int *doneflag) {
struct text_entry *entry;

for ( entry=entry_list.next; entry; entry=entry->next ) {
if ( IsSensitive(&entry->sensitive, x, y) ) {
current->hilite = 0;
Update_Entry(current);
current = entry;
DrawCursor(current);
Screen->Update();
}
}
}
virtual void HandleKeyPress(SDL_Keysym key, int *doneflag) {
int n;

switch (key.sym) {
case SDLK_TAB:
current->hilite = 0;
Update_Entry(current);
if ( current->next )
current=current->next;
else
current=entry_list.next;
current->hilite = 1;
Update_Entry(current);
break;

case SDLK_DELETE:
case SDLK_BACKSPACE:
if ( current->hilite ) {
*current->variable = '\0';
current->hilite = 0;
} else if ( *current->variable ) {
n = strlen(current->variable);
current->variable[n-1] = '\0';
}
Update_Entry(current);
DrawCursor(current);
break;

default:
if ( (current->end+Cwidth) > current->width )
return;
//if ( key.unicode ) {
current->hilite = 0;
n = strlen(current->variable);
current->variable[n] = (char)key.sym;
current->variable[n+1] = '\0';
Update_Entry(current);
DrawCursor(current);
//}
break;
}
Screen->Update();
}

virtual void Add_Entry(int x, int y, int width, int is_default,
char *variable) {
struct text_entry *entry;

for ( entry=&entry_list; entry->next; entry=entry->next )
/* Loop to end of entry list */;
entry->next = new struct text_entry;
entry = entry->next;

entry->variable = variable;
if ( is_default ) {
current = entry;
entry->hilite = 1;
} else
entry->hilite = 0;
entry->x = x+3;
entry->y = y+3;
entry->width = width*Cwidth;
entry->height = Cheight;
entry->sensitive.x = x;
entry->sensitive.y = y;
entry->sensitive.w = 3+(width*Cwidth)+3;
entry->sensitive.h = 3+Cheight+3;
entry->text = NULL;
entry->next = NULL;
}

virtual void Map(int Xoff, int Yoff, FrameBuf *screen,
Uint8 R_bg, Uint8 G_bg, Uint8 B_bg,
Uint8 R_fg, Uint8 G_fg, Uint8 B_fg) {
struct text_entry *entry;

/* Do the normal dialog mapping */
Mac_Dialog::Map(Xoff, Yoff, screen,
R_bg, G_bg, B_bg, R_fg, G_fg, B_fg);

/* Get the screen colors */
foreground.r = R_fg;
foreground.g = G_fg;
foreground.b = B_fg;
background.r = R_bg;
background.g = G_bg;
background.b = B_bg;
Fg = Screen->MapRGB(R_fg, G_fg, B_fg);
Bg = Screen->MapRGB(R_bg, G_bg, B_bg);

/* Adjust sensitivity and map the radiobox text */
for ( entry=entry_list.next; entry; entry=entry->next ) {
entry->x += Xoff;
entry->y += Yoff;
entry->sensitive.x += Xoff;
entry->sensitive.y += Yoff;
}
}
virtual void Show(void) {
struct text_entry *entry;

for ( entry=entry_list.next; entry; entry=entry->next ) {
Screen->DrawRect(entry->x-3, entry->y-3,
3+entry->width+3, 3+Cheight+3, Fg);
Update_Entry(entry);
}
}

private:
FontServ *Fontserv;
MFont *Font;
Uint32 Fg, Bg;
int Cwidth, Cheight;
SDL_Color foreground;
SDL_Color background;

struct text_entry {
SDL_Surface *text;
char *variable;
SDL_Rect sensitive;
int  x, y;
int  width, height;
int  end;
int  hilite;
struct text_entry *next;
} entry_list, *current;


void Update_Entry(struct text_entry *entry) {
Uint32 clear;

/* Create the new entry text */
if ( entry->text ) {
Fontserv->FreeText(entry->text);
}
if ( entry->hilite ) {
clear = Fg;
entry->text = Fontserv->TextImage(entry->variable,
Font, STYLE_NORM, background, foreground);
} else {
clear = Bg;
entry->text = Fontserv->TextImage(entry->variable,
Font, STYLE_NORM, foreground, background);
}
Screen->FillRect(entry->x, entry->y,
entry->width, entry->height, clear);
if ( entry->text ) {
entry->end = entry->text->w;
Screen->QueueBlit(entry->x, entry->y, entry->text, NOCLIP);
} else {
entry->end = 0;
}
}
void DrawCursor(struct text_entry *entry) {
Screen->DrawLine(entry->x+entry->end, entry->y,
entry->x+entry->end, entry->y+entry->height-1, Fg);
}
};

*/
/** Class of numeric entry boxes */
final class MacNumericEntry: MacDialog {
	private var entry_list = [NumericEntry]()
	
	private struct NumericEntry {
		var text: UnsafeMutablePointer<SDL_Surface>
		var variable: UnsafeMutablePointer<Int>
		var sensitive: SDL_Rect
		var x: Int32
		var y: Int32
		var width: Int32
		var height: Int32
		var end: Int32
		var hilite: Bool
	}

	init(x: Int32, y: Int32, font: FontServ.MFont, fontserv: FontServ) {
		super.init(x: x, y: y)
	}
	/*

Mac_NumericEntry::Mac_NumericEntry(int x, int y,
MFont *font, FontServ *fontserv) : Mac_Dialog(x, y)
{
Fontserv = fontserv;
Font = font;
Cwidth = Fontserv->TextWidth("0", Font, STYLE_NORM);
Cheight = Fontserv->TextHeight(font);
entry_list.next = NULL;
current = &entry_list;
}
*/
}


/*
class Mac_NumericEntry : public Mac_Dialog {

public:
Mac_NumericEntry(int x, int y, MFont *font, FontServ *fontserv);
virtual ~Mac_NumericEntry() {
struct numeric_entry *entry, *old;

for ( entry=entry_list.next; entry; ) {
old = entry;
entry = entry->next;
if ( old->text )
Fontserv->FreeText(old->text);
delete old;
}
}

virtual void HandleButtonPress(int x, int y, int button,
int *doneflag) {
struct numeric_entry *entry;

for ( entry=entry_list.next; entry; entry=entry->next ) {
if ( IsSensitive(&entry->sensitive, x, y) ) {
current->hilite = 0;
Update_Entry(current);
current = entry;
DrawCursor(current);
Screen->Update();
}
}
}
virtual void HandleKeyPress(SDL_Keysym key, int *doneflag) {
int n;

switch (key.sym) {
case SDLK_TAB:
current->hilite = 0;
Update_Entry(current);
if ( current->next )
current=current->next;
else
current=entry_list.next;
current->hilite = 1;
Update_Entry(current);
break;

case SDLK_DELETE:
case SDLK_BACKSPACE:
if ( current->hilite ) {
*current->variable = 0;
current->hilite = 0;
} else
*current->variable /= 10;
Update_Entry(current);
DrawCursor(current);
break;

case SDLK_0:
case SDLK_1:
case SDLK_2:
case SDLK_3:
case SDLK_4:
case SDLK_5:
case SDLK_6:
case SDLK_7:
case SDLK_8:
case SDLK_9:
n = (key.sym-SDLK_0);
if ( (current->end+Cwidth) > current->width )
return;
if ( current->hilite ) {
*current->variable = n;
current->hilite = 0;
} else {
*current->variable *= 10;
*current->variable += n;
}
Update_Entry(current);
DrawCursor(current);
break;

default:
break;
}
Screen->Update();
}

virtual void Add_Entry(int x, int y, int width, int is_default,
int *variable) {
struct numeric_entry *entry;

for ( entry=&entry_list; entry->next; entry=entry->next )
/* Loop to end of numeric entry list */;
entry->next = new struct numeric_entry;
entry = entry->next;

entry->variable = variable;
if ( is_default ) {
current = entry;
entry->hilite = 1;
} else
entry->hilite = 0;
entry->x = x+3;
entry->y = y+3;
entry->width = width*Cwidth;
entry->height = Cheight;
entry->sensitive.x = x;
entry->sensitive.y = y;
entry->sensitive.w = 3+(width*Cwidth)+3;
entry->sensitive.h = 3+Cheight+3;
entry->text = NULL;
entry->next = NULL;
}

virtual void Map(int Xoff, int Yoff, FrameBuf *screen,
Uint8 R_bg, Uint8 G_bg, Uint8 B_bg,
Uint8 R_fg, Uint8 G_fg, Uint8 B_fg) {
struct numeric_entry *entry;

/* Do the normal dialog mapping */
Mac_Dialog::Map(Xoff, Yoff, screen,
R_bg, G_bg, B_bg, R_fg, G_fg, B_fg);

/* Get the screen colors */
foreground.r = R_fg;
foreground.g = G_fg;
foreground.b = B_fg;
background.r = R_bg;
background.g = G_bg;
background.b = B_bg;
Fg = Screen->MapRGB(R_fg, G_fg, B_fg);
Bg = Screen->MapRGB(R_bg, G_bg, B_bg);

/* Adjust sensitivity and map the radiobox text */
for ( entry=entry_list.next; entry; entry=entry->next ) {
entry->x += Xoff;
entry->y += Yoff;
entry->sensitive.x += Xoff;
entry->sensitive.y += Yoff;
}
}
virtual void Show(void) {
struct numeric_entry *entry;

for ( entry=entry_list.next; entry; entry=entry->next ) {
Screen->DrawRect(entry->x-3, entry->y-3,
3+entry->width+3, 3+Cheight+3, Fg);
Update_Entry(entry);
}
}

private:
FontServ *Fontserv;
MFont *Font;
Uint32 Fg, Bg;
int Cwidth, Cheight;
SDL_Color foreground;
SDL_Color background;

struct numeric_entry {
SDL_Surface *text;
int *variable;
SDL_Rect sensitive;
int  x, y;
int  width, height;
int  end;
int  hilite;
struct numeric_entry *next;
} entry_list, *current;


void Update_Entry(struct numeric_entry *entry) {
char buf[128];
Uint32 clear;

/* Create the new entry text */
if ( entry->text ) {
Fontserv->FreeText(entry->text);
}
snprintf(buf, sizeof(buf), "%d", *entry->variable);

if ( entry->hilite ) {
clear = Fg;
entry->text = Fontserv->TextImage(buf,
Font, STYLE_NORM, background, foreground);
} else {
clear = Bg;
entry->text = Fontserv->TextImage(buf,
Font, STYLE_NORM, foreground, background);
}
entry->end = entry->text->w;
Screen->FillRect(entry->x, entry->y,
entry->width, entry->height, clear);
Screen->QueueBlit(entry->x, entry->y, entry->text, NOCLIP);
}
void DrawCursor(struct numeric_entry *entry) {
Screen->DrawLine(entry->x+entry->end, entry->y,
entry->x+entry->end, entry->y+entry->height-1, Fg);
}
};
*/

/** Finally, the macintosh-like dialog class */
final class MaclikeDialog {
	private var screen: FrameBuf
	private var location: (x: Int32, y: Int32)
	private var size: (width: Int32, height: Int32)
	
	convenience init(x: Int, y: Int, width: Int, height: Int, screen: FrameBuf) {
		self.init(x: Int32(x), y: Int32(y), width: Int32(width), height: Int32(height), screen: screen)
	}
	
	init(x: Int32, y: Int32, width: Int32, height: Int32, screen: FrameBuf) {
		location = (x, y)
		size = (width, height)
		self.screen = screen
	}
	
	func addRectangle(x x: Int, y: Int, w: Int, h: Int, color: UInt32) {
		let newElement = RectElement(x: Int16(x), y: Int16(y), w: UInt16(w), h: UInt16(h), color: color)
		rectList.append(newElement)
	}
	
	func addImage(image: UnsafeMutablePointer<SDL_Surface>, x: Int32, y: Int32) {
		let newElement = ImageElement(image: image, x: x, y: y)
		imageList.append(newElement)
	}
	
	func addImage(image: UnsafeMutablePointer<SDL_Surface>, x: Int, y: Int) {
		addImage(image, x: Int32(x), y: Int32(x))
	}
	
	func addDialog(dialog: MacDialog) {
		dialogList.append(dialog)
	}
	
	/// The big Kahones
	func run(expandSteps: Int = 1) {
		var savedfg = UnsafeMutablePointer<SDL_Surface>()
		var savedbg = UnsafeMutablePointer<SDL_Surface>()
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
		for _ in 0..<expandSteps /*( H=0, V=0, i=0; i<expand_steps; ++i )*/ {
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
			screen.queueBlit(x: location.x + 4 + ielem.x, y: location.y + 4 + ielem.y, src: ielem.image, do_clip: .NOCLIP)
		}
		for delem in dialogList {
			//delem.map(xOff: location.x + 4, yOff: location.y + 4, screen: screen, r_bg: 0xFF, g_bg: 0xFF, b_bg: 0xFF, r_fg: 0x00, g_fg: 0x00, b_fg: 0x00)
			delem.map(offset: (location.x + 4, location.y + 4), screen: screen,
				background: (0xFF,  0xFF, 0xFF), foreground: (0x00, 0x00, 0x00))
			delem.show()
		}
		screen.update();
		
		var done = false
		/* Wait until the dialog box is done */
		for ( done = false; !done; ) {
			screen.waitEvent(&event);
			
			switch (event.type) {
				/* -- Handle mouse clicks */
			case SDL_MOUSEBUTTONDOWN.rawValue:
				
				for dialog in dialogList {
					dialog.handleButtonPress(x: event.button.x,
						y: event.button.y, button: event.button.button, doneFlag: &done)
				}
				/* -- Handle key presses */
			case SDL_KEYDOWN.rawValue:
				for dialog in dialogList {
					dialog.handleKeyPress(event.key.keysym, done: &done)
				}
				
			default:
				break;
			}
		}
		
		/* Replace the old section of screen */
		if savedbg != nil {
			screen.focusBG();
			screen.queueBlit(x: location.x, y: location.y, src: savedbg, do_clip: .NOCLIP);
			screen.update();
			screen.focusFG();
			screen.freeImage(savedbg);
		}
		if savedfg != nil {
			screen.queueBlit(x: location.x, y: location.y, src: savedfg, do_clip: .NOCLIP);
			screen.update();
			screen.freeImage(savedfg);
		}
	}
	
	private struct RectElement {
		var x: Int16
		var y: Int16
		var w: UInt16
		var h: UInt16
		var color: UInt32
	}
	
	private struct ImageElement {
		var image: UnsafeMutablePointer<SDL_Surface>
		var x: Int32
		var y: Int32
	}
	
	private var rectList = [RectElement]()
	private var imageList = [ImageElement]()
	private var dialogList = [MacDialog]()
}
