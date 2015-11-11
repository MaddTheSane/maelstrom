//
//  init.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/11/15.
//
//

import Foundation

var gLastHigh: Int32 = 0


/* -- The prize CICN's */

//SDL_Surface *gAutoFireIcon, *gAirBrakesIcon, *gMult2Icon, *gMult3Icon;
//SDL_Surface *gMult4Icon, *gMult5Icon, *gLuckOfTheIrishIcon, *gLongFireIcon;
//SDL_Surface *gTripleFireIcon, *gKeyIcon, *gShieldIcon;

var gKeyIcon: UnsafeMutablePointer<SDL_Surface> = nil
