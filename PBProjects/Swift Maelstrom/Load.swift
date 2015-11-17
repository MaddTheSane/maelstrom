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
		//The SDL port of Maelstrom has some wonky file-name conventions due to different ways of storing Mac resource forks
		let posibleFileNames: [String] = {
			var toRet = [String]()
			toRet.append(fileName)
			toRet.append("%\(fileName)")
			toRet.append("._\(fileName)")
			toRet.append((fileName as NSString).stringByAppendingPathExtension("bin")!)
			
			let tmpRet = toRet.map({ (var tmpName) -> String in
				tmpName.replaceAllInstancesOfCharacter(" ", withCharacter: "_")
				return tmpName
			})
			
			toRet.appendContentsOf(tmpRet)
			
			return toRet
		}()
		for url in LibPath.searchURLs {
			for aFileName in posibleFileNames {
				let combined = url.URLByAppendingPathComponent(aFileName)
				if combined.checkResourceIsReachableAndReturnError(nil) {
					//But the APIs still expect the base file name
					return url.URLByAppendingPathComponent(fileName)
				}
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
	let file = ("Images" as NSString).stringByAppendingPathComponent("Maelstrom_Titles#\(title_id).bmp")
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
	let file = ("Images" as NSString).stringByAppendingPathComponent("Maelstrom_Icon#\(cicn_id).bmp")
	cicn_src = SDL_RWFromFile(path.path(file)!.fileSystemRepresentation, "r")
	if ( cicn_src == nil ) {
		print("GetCIcon(\(cicn_id)): Can't open CICN \(path.path(file)!): ");
		return nil;
	}
	
	w = SDL_ReadBE16(cicn_src);
	h = SDL_ReadBE16(cicn_src);
	pixels = [UInt8](count: Int(w*h), repeatedValue: 0)
	if ( SDL_RWread(cicn_src, &pixels, 1, Int(w*h)) != Int(w*h) ) {
		print("GetCIcon(\(cicn_id)): Corrupt CICN!");
		SDL_RWclose(cicn_src);
		return nil;
	}
	mask = [UInt8](count: Int(w/8*h), repeatedValue: 0)
	if ( SDL_RWread(cicn_src, &mask, 1, Int((w/8)*h)) != Int((w/8)*h) ) {
		print("GetCIcon(\(cicn_id)): Corrupt CICN!");
		SDL_RWclose(cicn_src);
		return nil;
	}
	SDL_RWclose(cicn_src);
	
	cicn = screen.loadImage(w: w, h: h, pixels: &pixels, mask: &mask)
	if cicn == nil {
		print("GetCIcon(\(cicn_id)): Couldn't convert CICN!");
	}
	return cicn
}
