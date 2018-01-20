//
//  main.swift
//  Maelstrom
//
//  Created by C.W. Betts on 10/31/15.
//
//

import Cocoa

var gArgc: Int32 = 0
var gArgv = [UnsafeMutablePointer<Int8>?](repeating: nil, count: 20)
func ADD_ARG(_ x: UnsafePointer<Int8>) {
	assert(gArgc < 20)
	gArgv[Int(gArgc)] = strdup(x)
	gArgc += 1
}

for i in 0..<CommandLine.argc {
	ADD_ARG(CommandLine.unsafeArgv[Int(i)]!)
}

//if Process.argc == 1 {
	let ret = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
	exit(ret)
//} else {
//	SDL_main(Process.argc, Process.unsafeArgv)
//}
