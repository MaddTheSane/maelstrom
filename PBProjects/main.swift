//
//  main.swift
//  Maelstrom
//
//  Created by C.W. Betts on 10/31/15.
//
//

import Cocoa

var gArgc: Int32 = 0
var gArgv = [UnsafeMutablePointer<Int8>](count: 20, repeatedValue: nil)
func ADD_ARG(x: UnsafePointer<Int8>) {
	assert(gArgc < 20)
	gArgv[Int(gArgc)] = strdup(x)
	gArgc += 1
}

for i in 0..<Process.argc {
	ADD_ARG(Process.unsafeArgv[Int(i)])
}

//if Process.argc == 1 {
	NSApplicationMain(Process.argc, Process.unsafeArgv)
//} else {
//	SDL_main(Process.argc, Process.unsafeArgv)
//}
