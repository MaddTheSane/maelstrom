//
//  Scores.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/10/15.
//
//

import Foundation

/* The high scores structure */
struct Score {
	//var name: (Int8, Int8)
	//char name[20];
	var name = ""
	var wave: UInt32
	var score: UInt32
}

var gNetScores = false



var hScores = [Score]()

func printHighScores() {
	
}

func getStartLevel() -> Int32 {
	return 0
}

func zapHighScores() -> Bool {
	return false
}


func loadScores() {
	
}

