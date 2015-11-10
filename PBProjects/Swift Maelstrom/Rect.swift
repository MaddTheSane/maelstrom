//
//  Rect.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/1/15.
//
//

import Foundation

struct Rect {
	var top: Int16 = 0
	var left: Int16 = 0
	var bottom: Int16 = 0
	var right: Int16 = 0
	
	func offsetRectBy(x x: Int32, y: Int32) -> Rect {
		var r = self
		r.left += Int16(x)
		r.top += Int16(y)
		r.right += Int16(x)
		r.bottom += Int16(y)
		return r
	}
	
	func offsetRectBy(x x: Int, y: Int) -> Rect {
		var r = self
		r.left += Int16(x)
		r.top += Int16(y)
		r.right += Int16(x)
		r.bottom += Int16(y)
		return r
	}
	
	mutating func offsetInPlaceWith(x x: Int32, y: Int32) {
		self.left += Int16(x)
		self.top += Int16(y)
		self.right += Int16(x)
		self.bottom += Int16(y)
	}
	
	mutating func offsetInPlaceWith(x x: Int, y: Int) {
		self.left += Int16(x)
		self.top += Int16(y)
		self.right += Int16(x)
		self.bottom += Int16(y)
	}
	
	func inset(x x: Int32, y: Int32) -> Rect {
		var R = self
		R.left += Int16(x)
		R.top += Int16(y)
		R.right -= Int16(x)
		R.bottom -= Int16(y)
		return R
	}
	
	func inset(x x: Int, y: Int) -> Rect {
		var R = self
		R.left += Int16(x)
		R.top += Int16(y)
		R.right -= Int16(x)
		R.bottom -= Int16(y)
		return R
	}
	
	mutating func insetInPlace(x x: Int32, y: Int32) {
		left += Int16(x)
		top += Int16(y)
		right -= Int16(x)
		bottom -= Int16(y)
	}
	
	mutating func insetInPlace(x x: Int, y: Int) {
		left += Int16(x)
		top += Int16(y)
		right -= Int16(x)
		bottom -= Int16(y)
	}
}

func setRect(inout R: Rect, _ left: Int32, _ top: Int32, _ right: Int32, _ bottom: Int32) {
	R.left = Int16(left)
	R.top = Int16(top)
	R.right = Int16(right)
	R.bottom = Int16(bottom)
}

func offsetRect(inout R: Rect, _ x: Int32, _ y: Int32) {
	R.offsetInPlaceWith(x: x, y: y)
}

func insetRect(inout R: Rect, x: Int32, y: Int32) {
	R.insetInPlace(x: x, y: y)
}
