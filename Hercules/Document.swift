//
//  Document.swift
//  Hercules
//
//  Created by Patrick Smith on 12/11/18.
//  Copyright © 2018 Royal Icing. All rights reserved.
//

import Cocoa


class Document: NSDocument {
	
	var pages: Model.Pages = Model.Pages(parsedPages: []) {
		didSet(old) {
			if old.pages != pages.pages {
				self.updateChangeCount(.changeDone)
			}
		}
	}
	
	override init() {
		super.init()
		// Add your subclass-specific initialization here.
	}
	
	override class var autosavesInPlace: Bool {
		return true
	}
	
	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
		let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
		self.addWindowController(windowController)
	}
	
	var plainTextType: String { return kUTTypePlainText as String }
	
	override func data(ofType typeName: String) throws -> Data {
		switch typeName {
		case plainTextType:
			return self.pages.text.data(using: .utf8)!
		default:
			throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}
	}
	
	override func read(from data: Data, ofType typeName: String) throws {
		switch typeName {
		case plainTextType:
			guard let text = String(data: data, encoding: .utf8) else {
				throw NSError(domain: NSOSStatusErrorDomain, code: readErr, userInfo: nil)
			}
			self.pages.text = text
			;
		default:
			throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}
	}
	
	
}

