//
//  SDL_FrameBuf.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/2/15.
//
//

import Foundation
import SDL2

//static void PrintSurface(const char *title, SDL_Surface *surface)
private func printSurface(title: String, surface: UnsafeMutablePointer<SDL_Surface>) {
	//do nothing
}

///Lower the precision of a value
private func LOWER_PREC(X: Int32) -> Int16 {
	return Int16(X / 16)
}

/*
#define LOWER_PREC(X)	((X)/16)	/*  */
#define RAISE_PREC(X)	((X)/16)	/* Raise the precision of a value */

*/

private func memswap(var dst: UnsafeMutablePointer<UInt8>, var src: UnsafeMutablePointer<UInt8>, len: Int) {
	#if SWAP_XOR
		for _ in 0..<len {
			dst.memory ^= src.memory
			src.memory ^= dst.memory
			dst.memory ^= src.memory
			dst++;src++;
		}
	#else
		for _ in 0..<len {
			swap(&dst.memory, &src.memory)
			dst++;src++;
		}
	#endif
}

class FrameBuf {
	enum clipval {
		case DOCLIP
		case NOCLIP
	}

	//	SDL_Window *window;
	private var window: SDL_WindowPtr = nil
	private var putPixel: (@convention(c) (screen_loc: UnsafeMutablePointer<Uint8>, screen: UnsafeMutablePointer<SDL_Surface>, pixel: Uint32) -> ())! = nil
	var screen: UnsafeMutablePointer<SDL_Surface> = nil

	var screenfg: UnsafeMutablePointer<SDL_Surface> = nil
	var screenbg: UnsafeMutablePointer<SDL_Surface> = nil
	
	private var locked = false
	private var screen_mem: UnsafeMutablePointer<UInt8> = nil

	/* Blit clipping rectangle */
	private var clip = SDL_Rect()

	func clipBlit(cliprect: SDL_Rect) {
		clip = cliprect
	}
	
	/* List of loaded images */
	struct ImageList {
		var image: UnsafeMutablePointer<SDL_Surface>
		var next: UnsafeMutablePointer<ImageList>
	};
	var images = ImageList(image: nil, next: nil)
	//image_list images, *itail;

	func lock() {
		/* Keep trying to lock the screen until we succeed */
		if !locked {
			locked = true
			while ( SDL_LockSurface(screen) < 0 ) {
				SDL_Delay(10);
			}
			screen_mem = UnsafeMutablePointer<UInt8>(screen.memory.pixels)
		}
	}
	
	func unlock() {
		if locked {
			SDL_UnlockSurface(screen)
			locked = false
		}
	}

	private func LOCK_IF_NEEDED() {
		if !locked {
			lock()
		}
	}
	
	private func UNLOCK_IF_NEEDED() {
		if locked {
			unlock()
		}
	}
	
	func focusFG() {
		UNLOCK_IF_NEEDED();
		screen = screenfg;
	}

	func focusBG() {
		UNLOCK_IF_NEEDED();
		screen = screenbg;
	}
	
	enum Errors: ErrorType {
		case CouldNotCreateWindow(SDLError: String)
		case SettingVideoMode(width: Int32, height: Int32, SDLError: String)
		case CouldNotCreateBackground(SDLError: String)
		case InvalidPixelFormat(UInt8)
	}
	
	var caption: String {
		get {
			return String.fromCString(SDL_GetWindowTitle(window))!
		}
		set {
			SDL_SetWindowTitle(window, newValue);
		}
	}
	
	init(width: Int32, height: Int32, videoFlags: UInt32, colors: UnsafePointer<SDL_Color> = nil, icon: UnsafeMutablePointer<SDL_Surface> = nil) throws {
		window = SDL_CreateWindow("title", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, videoFlags);
		if window == nil {
			error = String(format: "Couldn't create window: %s", SDL_GetError())
			throw Errors.CouldNotCreateWindow(SDLError: String.fromCString(SDL_GetError())!)
		}
		/* Set the icon, if any */
		if icon != nil {
			SDL_SetWindowIcon(window, icon);
		}
		
		/* old comment: */
		/* Try for the 8-bit video mode that was requested, accept any depth */
		screenfg = SDL_GetWindowSurface(window);
		if screenfg == nil {
			throw Errors.SettingVideoMode(width: width, height: height, SDLError: String.fromCString(SDL_GetError())!)
		}
		printSurface("Created foreground", surface: screenfg);
		screen = screenfg
		
		/* Create the background */
		screenbg = SDL_CreateRGBSurface(screen.memory.flags, screen.memory.w, screen.memory.h,
			Int32(screen.memory.format.memory.BitsPerPixel),
			screen.memory.format.memory.Rmask,
			screen.memory.format.memory.Gmask,
			screen.memory.format.memory.Bmask, 0);
		if screenbg == nil {
			throw Errors.CouldNotCreateBackground(SDLError: String.fromCString(SDL_GetError())!)
		}
		printSurface("Created background", surface: screenbg);
		
		/* Create a dirty rectangle map of the screen */
		dirtypitch = UInt16(LOWER_PREC(width))
		dirtymaplen = UInt16(LOWER_PREC(height)) * dirtypitch;
		dirtymap   = [UnsafeMutablePointer<SDL_Rect>](count: Int(dirtymaplen), repeatedValue: nil)
		
		/* Create the update list */
		updatelist = [SDL_Rect](count: FrameBuf.UPDATE_CHUNK, repeatedValue:SDL_Rect())
		clearDirtyList();
		updatemax = FrameBuf.UPDATE_CHUNK;
		
		/* Create the blit list */
		blitQ = [BlitQ](count: FrameBuf.QUEUE_CHUNK, repeatedValue: BlitQ())
		blitQlen = 0;
		blitQmax = FrameBuf.QUEUE_CHUNK;
		
		/* Set the blit clipping rectangle */
		clip.x = 0;
		clip.y = 0;
		clip.w = screen.memory.w;
		clip.h = screen.memory.h;
		
		/* Copy the image colormap and set a black background */
		setBackground(R: 0, G: 0, B: 0);
		if colors != nil {
			setPalette(colors);
		}
		
		/* Figure out what putpixel routine to use */
		switch (screen.memory.format.memory.BytesPerPixel) {
		case 1:
			putPixel = PutPixel1;
			break;
		case 2:
			putPixel = PutPixel2;
			break;
		case 3:
			putPixel = PutPixel3;
			break;
		case 4:
			putPixel = PutPixel4;
			break;
			
		default:
			throw Errors.InvalidPixelFormat(screen.memory.format.memory.BytesPerPixel)
		}
	}
	
	func fade() {
		#if FADE_SCREEN
		/*
const int max = 32;
Uint16 ramp[256];

for ( int j = 1; j <= max; j++ ) {
int v = faded ? j : max - j + 1;
for ( int i = 0; i < 256; i++ ) {
ramp[i] = (i * v / max) << 8;
}
SDL_SetWindowGammaRamp(window, ramp, ramp, ramp);
SDL_Delay(10);
}
faded = !faded;

if ( faded ) {
for ( int i = 0; i < 256; i++ ) {
ramp[i] = 0;
}
SDL_SetWindowGammaRamp(window, ramp, ramp, ramp);
}
*/
		#else
			SDL_Delay(320)
			print("fade skipped")
		#endif
	}
	
	func toggleFullScreen() {
		
	}
	
	func update() {
		
	}
	
	func freeImage(title: UnsafeMutablePointer<SDL_Surface>) {
		
	}
	
	func mapRGB(red R: UInt8, green G: UInt8, blue B: UInt8) -> UInt32 {
		return SDL_MapRGB(screenfg.memory.format, R, G, B)
	}

	/// Load and convert an 8-bit image with the given mask
	func loadImage(w w: UInt16, h: UInt16, pixels: UnsafeMutablePointer<UInt8>, mask: UnsafeMutablePointer<UInt8> = nil) -> UnsafeMutablePointer<SDL_Surface> {
		return nil
	}
	
	func screenDump(fileName: String, x: UInt16, y: UInt16, w: UInt16, h: UInt16) -> Bool {
		return false
	}
	
	func waitEvent(event: UnsafeMutablePointer<SDL_Event>) -> Int32 {
		return SDL_WaitEvent(event)
	}
	
	func performBlits() {
		if blitQlen > 0 {
			/* Perform lazy unlocking */
			UNLOCK_IF_NEEDED();
			
			/* Blast and free the queued blits */
			for ( var i=0; i<blitQlen; ++i ) {
				SDL_LowerBlit(blitQ[i].src, &blitQ[i].srcrect,
					screen, &blitQ[i].dstrect);
				SDL_FreeSurface(blitQ[i].src);
			}
			blitQlen = 0;
		}
	}

	
	func drawPoint(x x: Int16, y: Int16, color: UInt32) {
		var dirty = SDL_Rect()
		
		/* Adjust the bounds */
		if x < 0 {return;}
		if Int32(x) > screen.memory.w {return;}
		if y < 0 {return;}
		if Int32(y) > screen.memory.h {return;}
		
		performBlits();
		LOCK_IF_NEEDED();
		putPixel!(screen_loc: screen_mem.advancedBy(Int(y)*Int(screen.memory.pitch)+Int(x)*Int(screen.memory.format.memory.BytesPerPixel)), screen: screen, pixel: color)
		dirty.x = Int32(x)
		dirty.y = Int32(y)
		dirty.w = 1;
		dirty.h = 1;
		addDirtyRect(&dirty);
	}
	
	///Simple, slow, line drawing algorithm.  Improvement, anyone? :-)
	
	func drawLine(x1 x1: Int32, y1: Int32, x2: Int32, y2: Int32, color: UInt32) {
		drawLine(x1: Int16(x1), y1: Int16(y1), x2: Int16(x2), y2: Int16(y2), color: color)
	}
	
	func drawLine(x1 x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16, color: UInt32) {
		drawLine(x1: Int16(x1), y1: Int16(y1), x2: Int16(x2), y2: Int16(y2), color: color)
	}
	
	func drawLine(x1 x1: Int16, y1: Int16, x2: Int16, y2: Int16, color: UInt32) {
		
	}
	/*

/* Simple, slow, line drawing algorithm.  Improvement, anyone? :-) */
void
FrameBuf:: DrawLine(Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color)
{
SDL_Rect dirty;
Sint16   x , y;
Sint16   lo, hi;
double slope, b;
Uint8  screen_bpp;
Uint8 *screen_loc;

/* Adjust the bounds */
ADJUSTX(x1); ADJUSTY(y1);
ADJUSTX(x2); ADJUSTY(y2);

PerformBlits();
LOCK_IF_NEEDED();
screen_bpp = screen->format->BytesPerPixel;
if ( y1 == y2 )  {  /* Horizontal line */
if ( x1 < x2 ) {
lo = x1;
hi = x2;
} else {
lo = x2;
hi = x1;
}
screen_loc = screen_mem + y1*screen->pitch + lo*screen_bpp;
for ( x=lo; x<=hi; ++x ) {
PutPixel(screen_loc, screen, color);
screen_loc += screen_bpp;
}
dirty.x = lo;
dirty.y = y1;
dirty.w = (Uint16)(hi-lo+1);
dirty.h = 1;
AddDirtyRect(&dirty);
} else if ( x1 == x2 ) {  /* Vertical line */
if ( y1 < y2 ) {
lo = y1;
hi = y2;
} else {
lo = y2;
hi = y1;
}
screen_loc = screen_mem + lo*screen->pitch + x1*screen_bpp;
for ( y=lo; y<=hi; ++y ) {
PutPixel(screen_loc, screen, color);
screen_loc += screen->pitch;
}
dirty.x = x1;
dirty.y = lo;
dirty.w = 1;
dirty.h = (Uint16)(hi-lo+1);
AddDirtyRect(&dirty);
} else {
/* Equation:  y = mx + b */
slope = ((double)((int)(y2 - y1)) /
(double)((int)(x2 - x1)));
b = (double)(y1 - slope*(double)x1);
if ( ((slope < 0) ? slope > -1 : slope < 1) ) {
if ( x1 < x2 ) {
lo = x1;
hi = x2;
} else {
lo = x2;
hi = x1;
}
for ( x=lo; x<=hi; ++x ) {
y = (int)((slope*(double)x) + b);
screen_loc = screen_mem +
y*screen->pitch + x*screen_bpp;
PutPixel(screen_loc, screen, color);
}
} else {
if ( y1 < y2 ) {
lo = y1;
hi = y2;
} else {
lo = y2;
hi = y1;
}
for ( y=lo; y<=hi; ++y ) {
x = (int)(((double)y - b)/slope);
screen_loc = screen_mem +
y*screen->pitch + x*screen_bpp;
PutPixel(screen_loc, screen, color);
}
}
dirty.x = MIN(x1, x2);
dirty.y = MIN(y1, y2);
dirty.w = (Uint16)(MAX(x1, x2)-dirty.x+1);
dirty.h = (Uint16)(MAX(y1, y2)-dirty.y+1);
AddDirtyRect(&dirty);
}
}
	
	*/
	func drawRect(x x: Int32, y: Int32, width: Int32, height: Int32, color: UInt32) {
		drawRect(x: Int16(x), y: Int16(y), width: Int16(width), height: Int16(height), color: color)
	}
	
	func drawRect(x x: Int16, y: Int16, width: Int16, height: Int16, color: UInt32) {
		
	}
	/*
void
FrameBuf:: DrawRect(Sint16 x, Sint16 y, Uint16 w, Uint16 h, Uint32 color)
{
SDL_Rect dirty;
int i;
Uint8  screen_bpp;
Uint8 *screen_loc;

/* Adjust the bounds */
ADJUSTX(x); ADJUSTY(y);
if ( (x+w) > screen->w ) w = (Uint16)(screen->w-x);
if ( (y+h) > screen->h ) h = (Uint16)(screen->h-y);

PerformBlits();
LOCK_IF_NEEDED();
screen_bpp = screen->format->BytesPerPixel;

/* Horizontal lines */
screen_loc = screen_mem + y*screen->pitch + x*screen_bpp;
for ( i=0; i<w; ++i ) {
PutPixel(screen_loc, screen, color);
screen_loc += screen_bpp;
}
screen_loc = screen_mem + (y+h-1)*screen->pitch + x*screen_bpp;
for ( i=0; i<w; ++i ) {
PutPixel(screen_loc, screen, color);
screen_loc += screen_bpp;
}

/* Vertical lines */
screen_loc = screen_mem + y*screen->pitch + x*screen_bpp;
for ( i=0; i<h; ++i ) {
PutPixel(screen_loc, screen, color);
screen_loc += screen->pitch;
}
screen_loc = screen_mem + y*screen->pitch + (x+w-1)*screen_bpp;
for ( i=0; i<h; ++i ) {
PutPixel(screen_loc, screen, color);
screen_loc += screen->pitch;
}

/* Update rectangle */
dirty.x = x;
dirty.y = y;
dirty.w = w;
dirty.h = h;
AddDirtyRect(&dirty);
}
	*/
	
	func fillRect(x x: Int32, y: Int32, w: Int32, h: Int32, color: UInt32) {
		fillRect(x: Int16(x), y: Int16(y), w: Int16(w), h: Int16(h), color: color)
	}
	
	func fillRect(x x: Int16, y: Int16, w: Int16, h: Int16, color: UInt32) {
		
	}
	
	/*
	
void
FrameBuf:: FillRect(Sint16 x, Sint16 y, Uint16 w, Uint16 h, Uint32 color)
{
SDL_Rect dirty;
Uint16 i, skip;
Uint8 screen_bpp;
Uint8 *screen_loc;

/* Adjust the bounds */
ADJUSTX(x); ADJUSTY(y);
if ( (x+w) > screen->w ) w = (screen->w-x);
if ( (y+h) > screen->h ) h = (screen->h-y);

/* Set the dirty rectangle */
dirty.x = x;
dirty.y = y;
dirty.w = w;
dirty.h = h;

/* Semi-efficient, for now. :) */
LOCK_IF_NEEDED();
screen_bpp = screen->format->BytesPerPixel;
screen_loc = screen_mem + y*screen->pitch + x*screen_bpp;
skip = screen->pitch - (w*screen_bpp);
while ( h-- ) {
for ( i=w; i!=0; --i ) {
PutPixel(screen_loc, screen, color);
screen_loc += screen_bpp;
}
screen_loc += skip;
}
AddDirtyRect(&dirty);
}*/
	
	/* Setup routines */
	func setPalette(colors: UnsafePointer<SDL_Color>) {
		//int i;
		
		if screenfg.memory.format.memory.palette != nil {
			let palette = SDL_AllocPalette(256);
			SDL_SetPaletteColors(palette, colors, 0, 256);
			SDL_SetSurfacePalette(screenfg, palette);
			SDL_SetSurfacePalette(screenbg, screenfg.memory.format.memory.palette);
			SDL_FreePalette(palette);
		}
		for i in 0..<256 {
			image_map[i] = SDL_MapRGB(screenfg.memory.format,
				colors[i].r, colors[i].g, colors[i].b);
		}
		setBackground(R: BGrgb.0, G: BGrgb.1, B: BGrgb.2);
	}
	
	func setBackground(R R: UInt8, G: UInt8, B: UInt8) {
		BGrgb.0 = R;
		BGrgb.1 = G;
		BGrgb.2 = B;
		BGcolor = SDL_MapRGB(screenfg.memory.format, R, G, B);
		focusBG();
		clear();
		focusFG();
	}

	func clear(x x: Int16, y: Int16, w w1: UInt16, h h1: UInt16,
		do_clip: clipval = .NOCLIP) {
			var w = Int(w1)
			var h = Int32(h1)
			/* If we're focused on the foreground, copy from background */
			if ( screen == screenfg ) {
				queueBlit(dstx: Int32(x), dsty: Int32(y), src: screenbg, srcx: Int32(x), srcy: Int32(y), w: Int32(w), h: Int32(h), do_clip: do_clip);
			} else {
				var screen_loc: UnsafeMutablePointer<UInt8> = nil
				
				LOCK_IF_NEEDED();
				let screen_bpp = screen.memory.format.memory.BytesPerPixel;
				screen_loc = screen_mem.advancedBy(Int(y)*Int(screen.memory.pitch) + Int(x)*Int(screen_bpp))
				w *= Int(screen_bpp)
				while ( h-- != 0 ) {
					/* Note that BGcolor is a 32 bit quantity while memset()
					fills with an 8-bit quantity.  This only matters if
					the background is a different color than black on a
					HiColor or TrueColor display.
					*/
					memset(screen_loc, Int32(bitPattern: BGcolor), w);
					screen_loc += Int(screen.memory.pitch)
				}
			}
	}
	
	func clear() {
		clear(x: 0, y: 0, w: UInt16(screen.memory.w), h: UInt16(screen.memory.h))
	}

	func queueBlit(destinationPosition dstPos: (x: Int32, y: Int32),
		source src: UnsafeMutablePointer<SDL_Surface>, sourcePosition srcPos: (x: Int32, y: Int32),
		size: (w: Int32, h: Int32), clip do_clip: clipval) {
			var diff: Int32 = 0
			var w = size.w
			var h = size.h
			var srcx = srcPos.x
			var srcy = srcPos.y
			var dstx = dstPos.x
			var dsty = dstPos.y
			
			/* Perform clipping */
			if do_clip == .DOCLIP {
				diff = clip.x - dstPos.x;
				if ( diff > 0 ) {
					w -= diff;
					guard w > 0 else {
					return;
					}
					srcx += diff;
					dstx = clip.x;
				}
				diff = clip.y - dsty;
				if ( diff > 0 ) {
					h -= diff;
					if ( h <= 0 ) {
					return;
					}
					srcy += diff;
					dsty = clip.y;
				}
				diff = (dstx+w) - (clip.x+clip.w);
				if ( diff > 0 ) {
					w -= diff;
					guard w > 0 else {
					return;
					}
				}
				diff = (dsty+h) - (clip.y+clip.h);
				if ( diff > 0 ) {
					h -= diff;
					guard ( h > 0 ) else {
					return;
					}
				}
			}
			
			/* Lengthen the queue if necessary */
			if ( blitQlen == blitQmax ) {
				
				blitQmax += FrameBuf.QUEUE_CHUNK;
				while blitQ.count <= blitQmax {
					blitQ.append(BlitQ())
				}
			}
			
			/* Add the blit to the queue */
			++src.memory.refcount;
			blitQ[blitQlen].src = src;
			blitQ[blitQlen].srcrect.x = srcx;
			blitQ[blitQlen].srcrect.y = srcy;
			blitQ[blitQlen].srcrect.w = w;
			blitQ[blitQlen].srcrect.h = h;
			blitQ[blitQlen].dstrect.x = dstx;
			blitQ[blitQlen].dstrect.y = dsty;
			blitQ[blitQlen].dstrect.w = w;
			blitQ[blitQlen].dstrect.h = h;
			addDirtyRect(&blitQ[blitQlen].dstrect);
			++blitQlen;
	}

	func queueBlit(dstx dstx: Int32, dsty: Int32, src: UnsafeMutablePointer<SDL_Surface>,
		srcx: Int32, srcy: Int32, w: Int32, h: Int32, do_clip: clipval) {
		queueBlit(destinationPosition: (x: dstx, y: dsty), source: src, sourcePosition: (srcx, srcy), size: (w, h), clip: do_clip)
	}
	
	func queueBlit(x x: Int32, y: Int32, src: UnsafeMutablePointer<SDL_Surface>, do_clip: clipval = .DOCLIP) {
		queueBlit(dstx: x, dsty: y, src: src, srcx: 0, srcy: 0, w: src.memory.w, h: src.memory.h, do_clip: do_clip);
	}

	private func ADJUSTX(inout X: Int32) {
		if X < 0 {
			X = 0;
		} else if X > screen.memory.w {
			X = screen.memory.w
		}
	}
	
	private func ADJUSTY(inout Y: Int32) {
		if Y < 0 {
			Y = 0;
		} else if Y > screen.memory.h {
			Y = screen.memory.h
		}
	}

	
	private(set) var error: String? = nil
	
	//MARK: Blit queue list
	static let QUEUE_CHUNK = 16
	private struct BlitQ {
		var src: UnsafeMutablePointer<SDL_Surface> = nil
		var srcrect: SDL_Rect = SDL_Rect()
		var dstrect: SDL_Rect = SDL_Rect()
	};
	private var blitQ = [BlitQ]()
	private var blitQlen = 0
	private var blitQmax = 0
	
	//MARK: Rectangle update list
	static let UPDATE_CHUNK = QUEUE_CHUNK*2
/** Add a rectangle to the update list
This is a little bit smart -- if the center nearly overlaps the center
of another rectangle update, expand the existing rectangle to include
the new area, instead adding another update rectangle.
*/
	private func addDirtyRect(rect: UnsafeMutablePointer<SDL_Rect>) {
		
	}
	private var updatelen = 0
	private var updatemax = 0
	private var updatelist = [SDL_Rect]()
	private var dirtypitch: UInt16 = 0
	private var dirtymaplen: UInt16 = 0
	private var dirtymap = [UnsafeMutablePointer<SDL_Rect>]()
	private func clearDirtyList() {
		updatelen = 0;
		for i in 0..<dirtymap.count {
			dirtymap[i] = nil
		}
	}
	
	private var BGrgb: (red: UInt8, green: UInt8, blue: UInt8) = (0, 0, 0)
	private var BGcolor: UInt32 = 0
	private var image_map = [UInt32](count: 256, repeatedValue: 0)
	
	func grabArea(x x: UInt16, y: UInt16, w: UInt16, h: UInt16) -> UnsafeMutablePointer<SDL_Surface> {
		return nil
	}
}
