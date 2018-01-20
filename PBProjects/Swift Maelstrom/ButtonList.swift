//
//  ButtonList.swift
//  Maelstrom
//
//  Created by C.W. Betts on 11/10/15.
//
//

import Foundation

final class ButtonList {
	fileprivate struct Button {
		/* Sensitive area */
		var x1: UInt16
		var y1: UInt16
		var x2: UInt16
		var y2: UInt16
		var callback: (() -> Void)? = nil
	}
	fileprivate var buttonList = [Button]()
	
	func addButton(x: UInt16, y: UInt16, width: UInt16, height: UInt16, callback: (() -> Void)? = nil) {
		let button = Button(x1: x, y1: y, x2: x + width, y2: y + height, callback: callback)
		buttonList.append(button)
	}
	
	func removeAllButtons() {
		buttonList.removeAll()
	}
	
	func activateButton(x: UInt16, y: UInt16) {
		for belem in buttonList {
			if (x >= belem.x1) && (x <= belem.x2) &&
				(y >= belem.y1) && (y <= belem.y2),
				let callback = belem.callback {
				callback()
			}
		}
	}
}
