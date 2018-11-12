//
//  ViewController.swift
//  Hercules
//
//  Created by Patrick Smith on 12/11/18.
//  Copyright © 2018 Royal Icing. All rights reserved.
//

import Cocoa
import WebKit

class ViewController: NSViewController {
	
	var urls: [URL] = [] {
		didSet(previousURLs) {
			let text = urls.map { $0.absoluteString }.joined(separator: "\n") + "\n"
			let textStorage = urlsTextView.textStorage!
			let richText = NSAttributedString(string: text, attributes: [
				.font: NSFont.systemFont(ofSize: 14.0),
				.foregroundColor: NSColor.textColor,
				])
			textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: richText)
		}
	}
	
	@IBOutlet var webStackView: NSStackView!
	@IBOutlet var urlsTextView: NSTextView!

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
		
		self.urls = []
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
	func addPage(url: URL?) {
		let webViewConfig = WKWebViewConfiguration()
		let webView = WKWebView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 100.0), configuration: webViewConfig)
		webView.navigationDelegate = self
		if let url = url {
			webView.load(URLRequest(url: url))
		}
		
		let webScrollView = self.webScrollView
		webView.translatesAutoresizingMaskIntoConstraints = false
		webStackView.addView(webView, in: .trailing)
		NSLayoutConstraint.activate([
			webView.widthAnchor.constraint(greaterThanOrEqualToConstant: 320.0),
			webView.bottomAnchor.constraint(equalTo: webScrollView.contentView.bottomAnchor, constant: -20.0)
			])
	}
	
	func updateURLs(text: String) {
		let urls = text.split(separator: "\n").compactMap { URL(string: String($0)) }
		self.urls = urls
		let webViews = self.webStackView.arrangedSubviews as! [WKWebView]
		let openWebViewCount = webViews.count
		for (index, url) in urls.enumerated() {
			if index < openWebViewCount {
				let webView = webViews[index]
				if webView.url != url {
					webView.load(URLRequest(url: url))
				}
			} else {
				self.addPage(url: url)
			}
		}
	}
}

extension ViewController {
	@IBAction func addPage(_ sender: Any?) {
		let url = URL(string: "https://duckduckgo.com/")!
		self.urls.append(url)
		self.addPage(url: url)
	}

}

extension ViewController : WKNavigationDelegate {
	private func urlDidChange(for webView: WKWebView) {
		guard let index = webStackView.arrangedSubviews.firstIndex(of: webView) else { return }
		guard let url = webView.url else { return }
		self.urls[index] = url
	}
	
	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		self.urlDidChange(for: webView)
	}
	
	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
		self.urlDidChange(for: webView)
	}
}

extension ViewController : NSTextViewDelegate {
	func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
		if commandSelector == #selector(NSTextView.insertNewline(_:)) {
			self.updateURLs(text: textView.string)
		}
		
		return false
	}
}
