//
//  Pages.swift
//  Hercules
//
//  Created by Patrick Smith on 15/11/18.
//  Copyright © 2018 Royal Icing. All rights reserved.
//

import Cocoa

extension Model {
	enum Page : Equatable {
		case blank
		case web(url: URL)
		
		var url: URL? {
			switch self {
			case let .web(url):
				return url
			default:
				return nil
			}
		}
	}
	
	struct Pages {
		var pages: [Page]
		var presentedPages: [Page] {
			guard let lastValidIndex = pages.lastIndex(where: { $0 != .blank }) else {
				return self.pages
			}
			let slice = self.pages[...lastValidIndex]
			return Array(slice)
		}
		
		var text: String {
			get {
				return pages.map { page in
					guard case let .web(url) = page else { return "" }
					if url.scheme == "about" { return "" }
					return url.absoluteString
					}.joined(separator: "\n")
			}
			set(newText) {
				let pages = newText.split(separator: "\n", omittingEmptySubsequences: false).map { (input: Substring) -> Page in
					let input = input.trimmingCharacters(in: .whitespacesAndNewlines)
					if input == "" {
						return .blank
					}
					
					var maybeURL = URL(string: String(input))
					
					if maybeURL?.scheme == nil {
						var urlComponents = URLComponents(string: "https://duckduckgo.com/")!
						urlComponents.queryItems = [URLQueryItem(name: "q", value: String(input))]
						maybeURL = urlComponents.url
					}
					
					guard let url = maybeURL else { return .blank }
					return Page.web(url: url)
				}
				print("set pages", pages)
				self.pages = pages
			}
		}
		
		func commit(to mas: NSMutableAttributedString) {
			let text = self.text
			let richText = NSAttributedString(string: text, attributes: [
				.font: NSFont.systemFont(ofSize: 14.0),
				.foregroundColor: NSColor.textColor,
				])
			mas.replaceCharacters(in: NSRange(location: 0, length: mas.length), with: richText)
		}
	}
}
