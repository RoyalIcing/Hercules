//
//  ViewController.swift
//  Hercules
//
//  Created by Patrick Smith on 12/11/18.
//  Copyright © 2018 Royal Icing. All rights reserved.
//

import Cocoa
import WebKit

extension NSTextStorage {
	fileprivate func formatAsURLField(string maybeString: String? = nil) {
		let string = maybeString ?? self.string
		let richText = NSAttributedString(string: string, attributes: [
			.font: NSFont.systemFont(ofSize: 14.0),
			.foregroundColor: NSColor.textColor,
			])
		self.replaceCharacters(in: NSRange(location: 0, length: self.length), with: richText)
	}
	
	fileprivate func update(from pages: Model.Pages) {
		self.formatAsURLField(string: pages.text)
	}
}

class ViewController: NSViewController {
	@IBOutlet var webStackView: NSStackView!
	@IBOutlet var urlsTextView: NSTextView!
	
	var document: Document {
		return (self.view.window?.windowController?.document as? Document)!
	}
	
	var pagesState: Model.Pages {
		get {
			return document.pages
		}
		set(new) {
			document.pages = new
			self.urlsTextView.textStorage!.update(from: new)
		}
	}
	
	var needsToUpdateURLsFromText = false

	override func viewDidLoad() {
		super.viewDidLoad()
		
		webStackView.translatesAutoresizingMaskIntoConstraints = false

		let webScrollView = self.webScrollView
		let clipView = webScrollView.contentView
		NSLayoutConstraint.activate([
			webStackView.topAnchor.constraint(equalTo: clipView.topAnchor),
			webStackView.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),
			webStackView.widthAnchor.constraint(greaterThanOrEqualTo: clipView.widthAnchor, multiplier: 1.0),
			
			webScrollView.topAnchor.constraint(equalTo: clipView.topAnchor),
			webScrollView.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),
			webScrollView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
			webScrollView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor)
		])
		
		urlsTextView.delegate = self
	}
	
	override func viewDidAppear() {
		self.urlsTextView.textStorage!.update(from: self.pagesState)
		self.updateWebViews()
	}

	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
		}
	}
	
	var webScrollView: NSScrollView {
		return webStackView.enclosingScrollView!
	}
}

extension ViewController {
	func makeConfiguration() -> WKWebViewConfiguration {
		let webViewConfig = WKWebViewConfiguration()
		return webViewConfig
	}
	
	func addWebView(for: URL?) -> WKWebView {
		let webViewConfig = self.makeConfiguration()
		let webView = WKWebView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 100.0), configuration: webViewConfig)
		webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372"
		webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
		
		let webScrollView = self.webScrollView
		webView.translatesAutoresizingMaskIntoConstraints = false
		webStackView.addView(webView, in: .trailing)
		NSLayoutConstraint.activate([
			webView.widthAnchor.constraint(greaterThanOrEqualToConstant: 320.0),
			webView.bottomAnchor.constraint(equalTo: webScrollView.contentView.bottomAnchor, constant: -20.0)
			])
		
		return webView
	}
	
	func updateWebViews() {
		let webViews = (self.webStackView.arrangedSubviews as NSArray).copy() as! [WKWebView]
		var openWebViewsCount = self.webStackView.arrangedSubviews.count
		
		let pages = self.pagesState.presentedPages
		
		for (index, page) in pages.enumerated() {
			let webView: WKWebView
			if index < openWebViewsCount {
				webView = webViews[index]
			} else {
				webView = self.addWebView(for: page.url)
			}
			
			switch page {
			case let .web(url):
				if webView.url != url {
					webView.load(URLRequest(url: url))
				}
			case let .uncommittedSearch(query):
				var htmlSafeQuery = query
				htmlSafeQuery = htmlSafeQuery.replacingOccurrences(of: "<", with: "&lt;")
				htmlSafeQuery = htmlSafeQuery.replacingOccurrences(of: ">", with: "&gt;")
				htmlSafeQuery = htmlSafeQuery.replacingOccurrences(of: "&", with: "&amp;")
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
				<h1>\(htmlSafeQuery)</h1>
				</main>
				</body>
				</html>
				</div>
"""
				webView.loadHTMLString(html, baseURL: nil)
			case .blank:
				webView.loadHTMLString("", baseURL: nil)
			}
		}
		
		openWebViewsCount = self.webStackView.arrangedSubviews.count
		if pages.count < openWebViewsCount {
			for indexToRemove in pages.count ..< openWebViewsCount {
				print("removing", indexToRemove)
				self.webStackView.removeArrangedSubview(webViews[indexToRemove])
			}
		}
	}
}

extension ViewController {
	var newPageURL: URL {
		return URL(string: "https://start.duckduckgo.com/")!
	}
	
	@IBAction func addPage(_ sender: Any?) {
		let url = self.newPageURL
		self.pagesState.pages.append(Model.Page.web(url: url))
		self.updateWebViews()
	}

}

extension ViewController : WKNavigationDelegate {
	private func urlDidChange(for webView: WKWebView) {
		guard let index = webStackView.arrangedSubviews.firstIndex(of: webView) else { return }
		guard let url = webView.url else { return }
		// TODO: use smarter way to change URL line in text view while keeping pending text editing changes
		switch self.pagesState.pages[index] {
		case .web:
			self.pagesState.pages[index] = Model.Page.web(url: url)
		default:
			break
		}
	}
	
	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		self.urlDidChange(for: webView)
	}
	
	func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
		self.urlDidChange(for: webView)
	}
	
	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
		self.urlDidChange(for: webView)
	}
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		self.urlDidChange(for: webView)
	}
}

extension ViewController : NSTextViewDelegate {
	func updatePagesFromText(commitSearches: Bool) {
		self.pagesState.text = self.urlsTextView.string
		if commitSearches {
			self.pagesState.commitSearches()
		}
		self.updateWebViews()
		self.needsToUpdateURLsFromText = false
	}
	
	func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
		if commandSelector == #selector(NSTextView.insertNewline(_:)) {
			self.needsToUpdateURLsFromText = true
		}
		
		return false
	}
	
	func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
		let before = (textView.string as NSString).substring(with: affectedCharRange)
		if before.contains("\n") {
			self.needsToUpdateURLsFromText = true
		}
		
		return true
	}
	
	func textDidChange(_ notification: Notification) {
//		self.urlsTextView.textStorage!.formatAsURLField()
		
		self.updatePagesFromText(commitSearches: self.needsToUpdateURLsFromText)
	}
}
