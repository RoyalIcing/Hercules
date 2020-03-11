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
		case graphQLQuery(query: String)
		case markdownDocument(content: String)
		
		var url: URL? {
			switch self {
			case let .web(url):
				return url
			default:
				return nil
			}
		}
		
		func string() -> String {
			switch self {
			case .blank: return ""
			case .web(let url): return url.absoluteString
			case .uncommittedSearch(let query): return query
			case .graphQLQuery(let query): return query
			case .markdownDocument(let content): return content
			}
		}
		
		mutating func commitSearch() {
			switch self {
				case let .uncommittedSearch(query):
					var urlComponents = URLComponents(string: "https://duckduckgo.com/")!
					urlComponents.queryItems = [URLQueryItem(name: "q", value: query)]
					self = .web(url: urlComponents.url!)
			default:
				break
			}
		}
	}
	
	struct ParsedPage {
		var page: Page
		var input: Substring
		
		static func parse(input: String) -> [ParsedPage] {
			return input.split(separator: "\n", omittingEmptySubsequences: false).map { (input: Substring) -> ParsedPage in
				let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
				if trimmedInput == "" {
					return ParsedPage(page: .blank, input: input)
				}
				
				if
					let url = URL(string: String(trimmedInput)),
					url.scheme != nil
				{
					return ParsedPage(page: .web(url: url), input: input)
				}
				
				if input.first == "{" {
					return ParsedPage(page: .graphQLQuery(query: String(input)), input: input)
				}
				else if input.first == "#" {
					return ParsedPage(page: .markdownDocument(content: String(input)), input: input)
				}
				
				return ParsedPage(page: .uncommittedSearch(query: String(input)), input: input)
			}
		}
		
		enum Highlight {
			case vanilla
			
			private static let font = NSFont.systemFont(ofSize: 14.0)
			
			private static let paragraphStyle: NSParagraphStyle = {
				let style = NSMutableParagraphStyle()
				style.lineSpacing = 4
				return style
			}()
			
			private static var newline: NSAttributedString = NSAttributedString(string: "\n", attributes: [
				.font: font,
				.paragraphStyle: paragraphStyle
			])
			
			var newline: NSAttributedString { Highlight.newline }
			
			func highlight(parsedPage: ParsedPage) -> NSAttributedString {
				var color: NSColor {
					switch parsedPage.page {
					case .web:
						return NSColor(srgbRed: 0.1, green: 0.5, blue: 0.9, alpha: 1.0)
					case .graphQLQuery:
						return NSColor(srgbRed: 0.9, green: 0.0, blue: 0.5, alpha: 1.0)
					case .markdownDocument:
						return NSColor(srgbRed: 0.2, green: 0.5, blue: 0.3, alpha: 1.0)
					default:
						return NSColor.textColor
					}
				}
				
				return NSAttributedString(string: String(parsedPage.input), attributes: [
					.font: Highlight.font,
					.paragraphStyle: Highlight.paragraphStyle,
					.foregroundColor: color,
				])
			}
		}
	}
	
	struct Pages {
		var parsedPages: [ParsedPage]
		var pages: [Page] {
			get {
				return parsedPages.map { $0.page }
			}
			set(newPages) {
				let string = newPages.map { page -> String in
					var changedPage = page
					changedPage.commitSearch()
					return changedPage.string()
				}
				.joined(separator: "\n")
				
				self.parsedPages = ParsedPage.parse(input: string)
			}
		}
		var presentedPages: [Page] {
			guard let lastValidIndex = pages.lastIndex(where: { $0 != .blank }) else {
				return self.pages
			}
			let slice = self.pages[...lastValidIndex]
			return Array(slice)
		}
		
		mutating func commitSearches() {
			let pages = self.pages.map { page -> String in
				var changedPage = page
				changedPage.commitSearch()
				return changedPage.string()
			}
			
			self.parsedPages = ParsedPage.parse(input: pages.joined(separator: "\n"))
		}
		
		var text: String {
			get {
				return pages.map { page in
					switch page {
					case let .web(url):
						return url.absoluteString
					case let .uncommittedSearch(query):
						return query
					case let .graphQLQuery(query):
						return query
					case let .markdownDocument(content):
						return content
					case .blank:
						return ""
					}
					}.joined(separator: "\n")
			}
			set(newText) {
				self.parsedPages = ParsedPage.parse(input: newText)
			}
		}
		
		func commit(to mas: NSMutableAttributedString) {
//			let text = self.text
			
			let highlight = ParsedPage.Highlight.vanilla
			let richText = NSMutableAttributedString()
			for (index, parsedPage) in self.parsedPages.enumerated() {
				richText.append(highlight.highlight(parsedPage: parsedPage))
				if index + 1 != self.parsedPages.endIndex {
					richText.append(highlight.newline)
				}
			}
			
//			let richText = NSAttributedString(string: text, attributes: [
//				.font: NSFont.systemFont(ofSize: 14.0),
//				.foregroundColor: NSColor.textColor,
//				])
			mas.replaceCharacters(in: NSRange(location: 0, length: mas.length), with: richText)
		}
	}
}
