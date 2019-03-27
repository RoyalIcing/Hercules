//
//  HTMLTemplates.swift
//  Hercules
//
//  Created by Patrick Smith on 27/3/19.
//  Copyright © 2019 Royal Icing. All rights reserved.
//

import Foundation


struct HTMLPageVariables {
	var textColor: String = "black"
}

extension String {
	func htmlSafe() -> String {
		var htmlSafe = self
		htmlSafe = htmlSafe.replacingOccurrences(of: "<", with: "&lt;")
		htmlSafe = htmlSafe.replacingOccurrences(of: ">", with: "&gt;")
		htmlSafe = htmlSafe.replacingOccurrences(of: "&", with: "&amp;")
		return htmlSafe
	}
}

func generateHTMLPage(content: String, variables: HTMLPageVariables) -> String {
	let html = """
	<!doctype html>
	<head>
	<meta charset="utf-8">
	<style>
	html {
	font-size: 18px;
	}
	* {
	padding: 0;
	margin: 0;
	}
	main {
	height: 100vh; display: flex; align-items: center;
	color: \(variables.textColor.htmlSafe())
	}
	h1 {
	flex-grow: 1;
	text-align: center;
	padding: 0.5rem;
	font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif, Apple Color Emoji, Segoe UI Emoji, Segoe UI Symbol;
	font-size: 2rem;
	}
	</style>
	</head>
	<html>
	<body>
	<main>
	<h1>\(content.htmlSafe())</h1>
	</main>
	</body>
	</html>
	</div>
	"""
	return html
}

enum HTMLTemplate {
	case query(query: String)
	case markdown(content: String)
	case graphQLQuery(query: String)
	
	private var textColor: String {
		switch self {
		case .graphQLQuery:
			return "#E10098"
		case .markdown:
			return "#111"
		default:
			return "black"
		}
	}
	
	private var htmlPageVariables: HTMLPageVariables {
		return HTMLPageVariables(textColor: self.textColor)
	}
	
	func makeHTML() -> String {
		switch self {
		case let .query(query):
			return generateHTMLPage(content: query, variables: self.htmlPageVariables)
		case let .markdown(markdownContent):
			return generateHTMLPage(content: markdownContent, variables: self.htmlPageVariables)
		case let .graphQLQuery(query):
			return generateHTMLPage(content: query, variables: self.htmlPageVariables)
		}
	}
}
