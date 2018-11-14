//
//  Pages.swift
//  Hercules
//
//  Created by Patrick Smith on 15/11/18.
//  Copyright © 2018 Royal Icing. All rights reserved.
//

import Cocoa

extension Model {
	struct Pages {
		var urls: [URL?]
		
		var text: String {
			get {
				return urls.map { url in
					guard let url = url else { return "" }
					if url.scheme == "about" { return "" }
					return url.absoluteString
					}.joined(separator: "\n")
			}
			set(newText) {
				let urls = newText.split(separator: "\n", omittingEmptySubsequences: false).map { (input: Substring) -> URL? in
					let input = input.trimmingCharacters(in: .whitespacesAndNewlines)
					if input == "" {
						return nil
					}
					
					var url = URL(string: String(input))
					if url?.scheme == nil {
						var urlComponents = URLComponents(string: "https://duckduckgo.com/")!
						urlComponents.queryItems = [URLQueryItem(name: "q", value: String(input))]
						url = urlComponents.url
					}
					return url
				}
				print("set urls", urls)
				self.urls = urls
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
