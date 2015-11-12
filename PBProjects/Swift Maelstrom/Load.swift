//
//  Load.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/11/15.
//
//

import Foundation

final class LibPath {
	private static let searchURLs: [NSURL] = {
		let ourBundle = NSBundle.mainBundle()
		var toRet = [NSURL]()
		
		do {
			let fm = NSFileManager.defaultManager()
			var userDir = try fm.URLForDirectory(.ApplicationSupportDirectory, inDomain: .UserDomainMask, appropriateForURL: ourBundle.bundleURL, create: false)
			userDir = userDir.URLByAppendingPathComponent("Maelstrom", isDirectory: true)
			if !userDir.checkResourceIsReachableAndReturnError(nil) {
				try fm.createDirectoryAtURL(userDir, withIntermediateDirectories: true, attributes: nil)
			}
			toRet.append(userDir)
		} catch _ {}
		
		toRet.append(ourBundle.bundleURL.URLByDeletingLastPathComponent!)
		toRet.append(ourBundle.resourceURL!)
		
		return toRet
	}()
	
	func path(fileName: String) -> NSURL? {
		for url in LibPath.searchURLs {
			let combined = url.URLByAppendingPathComponent(fileName)
			if combined.checkResourceIsReachableAndReturnError(nil) {
				return combined
			}
		}
		
		return nil
	}
}

@asmname("Load_Icon") func loadIcon(xpm: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>) -> UnsafeMutablePointer<SDL_Surface>

func loadTitle(screen: FrameBuf, title_id: Int32) -> UnsafeMutablePointer<SDL_Surface> {
	let path = LibPath()
	var bmp: UnsafeMutablePointer<SDL_Surface> = nil
	var title: UnsafeMutablePointer<SDL_Surface> = nil

	/* Open the title file -- we know its colormap is our global one */
	let file = "Images/Maelstrom_Titles#\(title_id).bmp"
	bmp = SDL_LoadBMP(path.path(file)!.fileSystemRepresentation);
	if bmp == nil {
		return nil;
	}
	
	/* Create an image from the BMP */
	title = screen.loadImage(w: UInt16(bmp.memory.w), h: UInt16(bmp.memory.h), pixels: UnsafeMutablePointer<UInt8>(bmp.memory.pixels), mask: nil)
	SDL_FreeSurface(bmp)
	return title
}

func getCIcon(screen: FrameBuf, cicn_id: Int16) -> UnsafeMutablePointer<SDL_Surface> {
	let path = LibPath()
	var w: UInt16 = 0
	var h: UInt16 = 0
	var pixels: [UInt8]
	var mask: [UInt8]
	var cicn_src: UnsafeMutablePointer<SDL_RWops> = nil
	var cicn: UnsafeMutablePointer<SDL_Surface> = nil
	
	/* Open the cicn sprite file.. */
	let file = "Images/Maelstrom_Icon#\(cicn_id).cicn"
	cicn_src = SDL_RWFromFile(path.path(file)!.fileSystemRepresentation, "r")
	if ( cicn_src == nil ) {
		//error("GetCIcon(%hd): Can't open CICN %s: ",
		//	cicn_id, path.Path(file));
		return nil;
	}
	
	w = SDL_ReadBE16(cicn_src);
	h = SDL_ReadBE16(cicn_src);
	pixels = [UInt8](count: Int(w*h), repeatedValue: 0)
	if ( SDL_RWread(cicn_src, &pixels, 1, Int(w*h)) != Int(w*h) ) {
		//error("GetCIcon(%hd): Corrupt CICN!\n", cicn_id);
		SDL_RWclose(cicn_src);
		return nil;
	}
	mask = [UInt8](count: Int(w/8*h), repeatedValue: 0)
	if ( SDL_RWread(cicn_src, &mask, 1, Int((w/8)*h)) != Int((w/8)*h) ) {
		//error("GetCIcon(%hd): Corrupt CICN!\n", cicn_id);
		SDL_RWclose(cicn_src);
		return nil;
	}
	SDL_RWclose(cicn_src);
	
	cicn = screen.loadImage(w: w, h: h, pixels: &pixels, mask: &mask)
	if cicn == nil {
		//error("GetCIcon(%hd): Couldn't convert CICN!\n", cicn_id);
	}
	return cicn
}