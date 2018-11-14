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
	@IBOutlet var webStackView: NSStackView!
	@IBOutlet var urlsTextView: NSTextView!
	
	enum State {
		struct Pages {
			var urls: [URL]
			
			var text: String {
				get {
					return urls.map { $0.absoluteString }.joined(separator: "\n") + "\n"
				}
				set(newText) {
					let searchURLComponents = URLComponents(string: "https://duckduckgo.com/?q=")!
					let urls = newText.split(separator: "\n").compactMap { (input: Substring) -> URL? in
						var url = URL(string: String(input))
						if url?.scheme == nil {
							var urlComponents = searchURLComponents
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
	
	var pagesState: State.Pages = State.Pages(urls: []) {
		didSet {
			self.pagesState.commit(to: self.urlsTextView.textStorage!)
		}
	}

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
		
		pagesState.commit(to: self.urlsTextView.textStorage!)
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
	
	func addPage(url: URL?) {
		let webViewConfig = self.makeConfiguration()
		let webView = WKWebView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 100.0), configuration: webViewConfig)
		webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372"
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
		self.pagesState.text = text
		let webViews = (self.webStackView.arrangedSubviews as NSArray).copy() as! [WKWebView]
		let openWebViewCount = webViews.count
		for (index, url) in self.pagesState.urls.enumerated() {
			if index < openWebViewCount {
				let webView = webViews[index]
				if webView.url != url {
					webView.load(URLRequest(url: url))
				}
			} else {
				self.addPage(url: url)
			}
		}
		
//		for indexToRemove in openWebViewCount...webViews.count {
//			self.webStackView.removeArrangedSubview(webViews[indexToRemove])
//		}
	}
}

extension ViewController {
	@IBAction func addPage(_ sender: Any?) {
		let url = URL(string: "https://start.duckduckgo.com/")!
		self.pagesState.urls.append(url)
		self.addPage(url: url)
	}

}

extension ViewController : WKNavigationDelegate {
	private func urlDidChange(for webView: WKWebView) {
		guard let index = webStackView.arrangedSubviews.firstIndex(of: webView) else { return }
		guard let url = webView.url else { return }
		self.pagesState.urls[index] = url
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
