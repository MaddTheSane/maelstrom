//
//  SDL_FrameBuf.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/2/15.
//
//

import Foundation

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
	
	init() {
	
	}
	
	func setUp(width width: Int32, height: Int32, videoFlags: UInt32, colors: UnsafePointer<SDL_Color> = nil, icon: UnsafeMutablePointer<SDL_Surface> = nil) -> Bool {
		window = SDL_CreateWindow("title", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, videoFlags);
		if window == nil {
			error = String(format: "Couldn't create window: %s", SDL_GetError())
			return false
		}
		/* Set the icon, if any */
		if icon != nil {
			SDL_SetWindowIcon(window, icon);
		}
		
		/* old comment: */
		/* Try for the 8-bit video mode that was requested, accept any depth */
		screenfg = SDL_GetWindowSurface(window);
		if screenfg == nil {
			error = String(format: "Couldn't set %dx%d video mode: %s",
				width, height, SDL_GetError());

			return false
		}
		printSurface("Created foreground", surface: screenfg);

		/* Create the background */
		screenbg = SDL_CreateRGBSurface(screen.memory.flags, screen.memory.w, screen.memory.h,
			Int32(screen.memory.format.memory.BitsPerPixel),
			screen.memory.format.memory.Rmask,
			screen.memory.format.memory.Gmask,
			screen.memory.format.memory.Bmask, 0);
		if screenbg == nil {
			error = String(format: "Couldn't create background: %s", SDL_GetError())
			//SetError("Couldn't create background: %s", SDL_GetError());
			return false
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
			return false
		}
		return true;
	}
	
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
			var h = h1
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
					memset(screen_loc, Int32(BGcolor), w);
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
}
