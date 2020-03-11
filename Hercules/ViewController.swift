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
		self.beginEditing()
		pages.commit(to: self)
		self.endEditing()
		
//		let text = pages.text
//		
//		if text == self.string {
//			return
//		}
//		
//		self.beginEditing()
//		self.formatAsURLField(string: text)
//		self.endEditing()
	}
}

class ViewController: NSViewController {
	@IBOutlet var webStackView: NSStackView!
	@IBOutlet var urlsTextView: NSTextView!
	
	var orientation: NSUserInterfaceLayoutOrientation = .vertical
	
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
	
	var needsUpdate = false
	
	var layoutConstraintsForOrientation: [NSLayoutConstraint] = []
	
	func updateForOrientation() {
		let orientation = self.orientation
		webStackView.orientation = orientation
		webStackView.edgeInsets = .init(top: 20, left: 20, bottom: 20, right: 20)

		let webScrollView = self.webScrollView
		let clipView = webScrollView.contentView
		
		NSLayoutConstraint.deactivate(layoutConstraintsForOrientation)
		layoutConstraintsForOrientation.removeAll()
		
		switch orientation {
		case .horizontal:
			layoutConstraintsForOrientation.append(contentsOf: [
				webStackView.topAnchor.constraint(equalTo: clipView.topAnchor),
				webStackView.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),
				webStackView.widthAnchor.constraint(greaterThanOrEqualTo: clipView.widthAnchor, multiplier: 1.0),
			])
		case .vertical:
			layoutConstraintsForOrientation.append(contentsOf: [
//				webStackView.topAnchor.constraint(equalTo: clipView.topAnchor),
//				webStackView.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),
//				webStackView.widthAnchor.constraint(greaterThanOrEqualTo: clipView.widthAnchor, multiplier: 1.0),
			])
		default: break
		}
		
		layoutConstraintsForOrientation.append(contentsOf: [
			webScrollView.topAnchor.constraint(equalTo: clipView.topAnchor),
			webScrollView.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),
			webScrollView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
			webScrollView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor)
		])
		
		NSLayoutConstraint.activate(layoutConstraintsForOrientation)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		webStackView.translatesAutoresizingMaskIntoConstraints = false
		self.updateForOrientation()
		
		urlsTextView.delegate = self
		urlsTextView.typingAttributes = [
			.font: NSFont.systemFont(ofSize: 14.0),
			.foregroundColor: NSColor.textColor,
		]
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
		webView.uiDelegate = self
		webView.allowsBackForwardNavigationGestures = true
		
		let webScrollView = self.webScrollView
		webView.translatesAutoresizingMaskIntoConstraints = false
		webStackView.addView(webView, in: .trailing)
		if self.orientation == .horizontal {
			NSLayoutConstraint.activate([
						webView.widthAnchor.constraint(greaterThanOrEqualToConstant: 320.0),
						webView.bottomAnchor.constraint(equalTo: webScrollView.contentView.bottomAnchor, constant: -20.0)
						])
		} else {
			NSLayoutConstraint.activate([
						webView.widthAnchor.constraint(equalToConstant: 320.0),
						webView.heightAnchor.constraint(greaterThanOrEqualToConstant: 480.0),
			//			webView.bottomAnchor.constraint(equalTo: webScrollView.contentView.bottomAnchor, constant: -20.0)
						])
		}
		
		return webView
	}
	
	@discardableResult func updateWebViews() -> (added: [WKWebView], removed: [WKWebView]) {
		let webViews = (self.webStackView.arrangedSubviews as NSArray).copy() as! [WKWebView]
		var openWebViewsCount = self.webStackView.arrangedSubviews.count
		
		let pages = self.pagesState.presentedPages
		var added: [WKWebView] = []
		var removed: [WKWebView] = []
		
		for (index, page) in pages.enumerated() {
			let webView: WKWebView
			if index < openWebViewsCount {
				webView = webViews[index]
			} else {
				webView = self.addWebView(for: page.url)
				added.append(webView)
			}
			
			switch page {
			case let .web(url):
				if webView.url != url && url.scheme == "https" || url.scheme == "http" {
					webView.load(URLRequest(url: url))
				}
			case let .uncommittedSearch(query):
				let html = HTMLTemplate.query(query: query).makeHTML()
				webView.loadHTMLString(html, baseURL: nil)
			case let .graphQLQuery(query):
				let html = HTMLTemplate.graphQLQuery(query: query).makeHTML()
				webView.loadHTMLString(html, baseURL: nil)
			case let .markdownDocument(content):
				let html = HTMLTemplate.markdown(content: content).makeHTML()
				webView.loadHTMLString(html, baseURL: nil)
			case .blank:
				webView.loadHTMLString("", baseURL: nil)
			}
		}
		
		openWebViewsCount = self.webStackView.arrangedSubviews.count
		if pages.count < openWebViewsCount {
			for indexToRemove in pages.count ..< openWebViewsCount {
				print("removing", indexToRemove)
				removed.append(webViews[indexToRemove])
				self.webStackView.removeArrangedSubview(webViews[indexToRemove])
			}
		}
		
		return (added, removed)
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

	@IBAction func performClosePage(_ sender: Any?) {
		if self.pagesState.pages.count > 0 {
			self.pagesState.pages.removeLast()
			self.updateWebViews()
		} else {
			NSApp.perform(#selector(NSWindow.performClose(_:)))
		}
		
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
		
		if false {
			webView.evaluateJavaScript("""
	var s = document.createElement("script");
	s.type = "text/javascript";
	s.src = "https://cdn.jsdelivr.net/npm/axe-core@3.1.2/axe.min.js";
	s.integrity = "sha256-wIvlzfT77n6fOnSL6/oLbzB873rY7QHTW/e0Z0mOoYs=";
	s.crossorigin = "anonymous";
	var t = document.getElementsByTagName(o)[0];
	t.parentNode.insertBefore(s, t);
	""") { (result, error) in
			}
		}
	}
}

extension ViewController : WKUIDelegate {
	func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
		let request = navigationAction.request
		if let url = request.url {
			self.pagesState.pages.append(Model.Page.web(url: url))
			let (added, _) = self.updateWebViews()
			return added.first
		}
		
		return nil
	}
}

extension ViewController : NSTextViewDelegate {
	func updatePagesFromText(commitSearches: Bool) {
		self.pagesState.text = self.urlsTextView.string
		if commitSearches {
			self.pagesState.commitSearches()
		}
		self.updateWebViews()
		self.needsUpdate = false
	}
	
	func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
		if commandSelector == #selector(NSTextView.insertNewline(_:)) {
			self.needsUpdate = true
		}
		
		return false
	}
	
	func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
		let before = (textView.string as NSString).substring(with: affectedCharRange)
		if before.contains("\n") {
			self.needsUpdate = true
		}
		
		return true
	}
	
	func textDidChange(_ notification: Notification) {
//		self.urlsTextView.textStorage!.formatAsURLField()
		
		self.updatePagesFromText(commitSearches: self.needsUpdate)
	}
	
	func textViewDidChangeSelection(_ notification: Notification) {
		guard let selection = urlsTextView.selectedRanges.first else { return }
		let start = selection.rangeValue.location
		guard let string = urlsTextView.textStorage?.string else { return }
//		string.range
//		string.prefix(upTo: start)
		
	}
}
