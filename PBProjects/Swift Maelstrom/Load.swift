//
//  Load.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/11/15.
//
//

import Foundation
import SDL2

final class LibPath {
	private static let searchURLs: [URL] = {
		let ourBundle = Bundle.main
		var toRet = [URL]()
		
		do {
			let fm = FileManager.default
			var userDir = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: ourBundle.bundleURL, create: false)
			userDir = userDir.appendingPathComponent("Maelstrom", isDirectory: true)
			if !((try? (userDir).checkResourceIsReachable()) ?? false) {
				try fm.createDirectory(at: userDir, withIntermediateDirectories: true, attributes: nil)
			}
			toRet.append(userDir)
		} catch _ {}
		
		toRet.append(ourBundle.bundleURL.deletingLastPathComponent())
		if let resURL = ourBundle.resourceURL {
			toRet.append(resURL)
		}
		
		return toRet
	}()
	
	func path(_ fileName: String) -> URL? {
		//The SDL port of Maelstrom has some wonky file-name conventions due to different ways of storing Mac resource forks
		let posibleFileNames: [String] = {
			var toRet = [String]()
			toRet.append(fileName)
			toRet.append("%\(fileName)")
			toRet.append("._\(fileName)")
			toRet.append((fileName as NSString).appendingPathExtension("bin")!)
			
			let tmpRet = toRet.map({ (aName) -> String in
				var tmpName = aName
				tmpName.replaceAllInstancesOfCharacter(" ", withCharacter: "_")
				return tmpName
			})
			
			toRet.append(contentsOf: tmpRet)
			
			return toRet
		}()
		for url in LibPath.searchURLs {
			for aFileName in posibleFileNames {
				let combined = url.appendingPathComponent(aFileName)
				if (combined as NSURL).checkResourceIsReachableAndReturnError(nil) {
					//But the APIs still expect the base file name
					return url.appendingPathComponent(fileName)
				}
			}
		}
		
		return nil
	}
}

func loadTitle(_ screen: FrameBuf, title_id: Int32) -> UnsafeMutablePointer<SDL_Surface>? {
	let path = LibPath()
	var title: UnsafeMutablePointer<SDL_Surface>? = nil

	/* Open the title file -- we know its colormap is our global one */
	let file = ("Images" as NSString).appendingPathComponent("Maelstrom_Titles#\(title_id).bmp")
	guard let bmp = SDL_LoadBMP((path.path(file)! as NSURL).fileSystemRepresentation) else {
		return nil
	}
	
	/* Create an image from the BMP */
	title = screen.loadImage(w: UInt16(bmp.pointee.w), h: UInt16(bmp.pointee.h), pixels: bmp.pointee.pixels.assumingMemoryBound(to: UInt8.self), mask: nil)
	SDL_FreeSurface(bmp)
	return title
}

func getCIcon(_ screen: FrameBuf, cicn_id: Int16) -> UnsafeMutablePointer<SDL_Surface>? {
	let path = LibPath()
	var w: UInt16 = 0
	var h: UInt16 = 0
	var pixels: [UInt8]
	var mask: [UInt8]
	
	/* Open the cicn sprite file.. */
	let file = ("Images" as NSString).appendingPathComponent("Maelstrom_Icon#\(cicn_id).cicn")
	guard let cicn_src = SDL_RWFromFile((path.path(file)! as NSURL).fileSystemRepresentation, "r") else {
		print("GetCIcon(\(cicn_id)): Can't open CICN \(path.path(file)!): ");
		return nil;
	}
	
	defer {
		SDL_RWclose(cicn_src);
	}
	
	w = SDL_ReadBE16(cicn_src);
	h = SDL_ReadBE16(cicn_src);
	pixels = [UInt8](repeating: 0, count: Int(w*h))
	if SDL_RWread(cicn_src, &pixels, 1, Int(w*h)) != Int(w*h) {
		print("GetCIcon(\(cicn_id)): Corrupt CICN!");
		return nil;
	}
	mask = [UInt8](repeating: 0, count: Int(w/8*h))
	if SDL_RWread(cicn_src, &mask, 1, Int((w/8)*h)) != Int((w/8)*h) {
		print("GetCIcon(\(cicn_id)): Corrupt CICN!");
		return nil;
	}
	
	guard let cicn = screen.loadImage(w: w, h: h, pixels: &pixels, mask: &mask) else {
		print("GetCIcon(\(cicn_id)): Couldn't convert CICN!");
		return nil
	}
	return cicn
}
