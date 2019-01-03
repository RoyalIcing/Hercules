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
		case uncommittedSearch(query: String)
		
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
		
		mutating func commitSearches() {
			let newPages = self.pages.map { page -> Page in
				switch page {
				case let .uncommittedSearch(query):
					var urlComponents = URLComponents(string: "https://duckduckgo.com/")!
					urlComponents.queryItems = [URLQueryItem(name: "q", value: query)]
					return .web(url: urlComponents.url!)
				default:
					return page
				}
			}
			self.pages = newPages
		}
		
		var text: String {
			get {
				return pages.map { page in
					switch page {
					case let .web(url):
						return url.absoluteString
					case let .uncommittedSearch(query):
						return query
					case .blank:
						return ""
					}
					}.joined(separator: "\n")
			}
			set(newText) {
				let pages = newText.split(separator: "\n", omittingEmptySubsequences: false).map { (input: Substring) -> Page in
					let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
					if trimmedInput == "" {
						return .blank
					}
					
					if
						let url = URL(string: String(trimmedInput)),
						url.scheme != nil
					{
						return Page.web(url: url)
					}
					
					return Page.uncommittedSearch(query: String(input))
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
