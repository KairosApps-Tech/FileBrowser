//
//  WebviewPreviewViewContoller.swift
//  FileBrowser
//
//  Created by Roy Marmelstein on 16/02/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import UIKit
import WebKit

/// Webview for rendering items QuickLook will struggle with.
class WebviewPreviewViewContoller: UIViewController {
    
    var webView = WKWebView()

    var file: FBFile? {
        didSet {
            self.title = file?.displayName
            self.processForDisplay()
        }
    }

    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)

        webView.backgroundColor = .systemBackground

        // Add share button
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(WebviewPreviewViewContoller.shareFile(_:)))
        navigationItem.rightBarButtonItem = shareButton
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        webView.frame = view.bounds
    }
    
    //MARK: Share
    
    @objc func shareFile(_ sender: UIBarButtonItem) {
        guard let file = file else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [file.filePath], applicationActivities: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad &&
            activityViewController.responds(to: #selector(getter: popoverPresentationController)) {
            activityViewController.popoverPresentationController?.barButtonItem = sender
        }
        
        self.present(activityViewController, animated: true, completion: nil)
    }

    //MARK: Processing
    
    func processForDisplay() {
        guard let file = file, let data = try? Data(contentsOf: file.filePath as URL) else {
            return
        }
        var rawString: String?
        
        if file.type == .plist {
            do {
                if let plistDescription = try (PropertyListSerialization.propertyList(from: data, options: [], format: nil) as AnyObject).description {
                    rawString = plistDescription
                }
            } catch {}
        } else if file.type == .json {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if JSONSerialization.isValidJSONObject(jsonObject) {
                    let prettyJSON = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                    var jsonString = String(data: prettyJSON, encoding: String.Encoding.utf8)
                    // Unescape forward slashes
                    jsonString = jsonString?.replacingOccurrences(of: "\\/", with: "/")
                    rawString = jsonString
                }
            } catch {}
        }
        
        // Default prepare for display
        if rawString == nil {
            rawString = String(data: data, encoding: String.Encoding.utf8)
        }
        
        // Convert and display string
        if let convertedString = convertSpecialCharacters(rawString) {
            let htmlString = """
<html>
<head>
    <meta name='viewport' content='initial-scale=1.0, user-scalable=no'>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: white;
            color: black;
        }

        /* Dark Mode automatique */
        @media (prefers-color-scheme: dark) {
            body {
                background-color: #1e1e1e;
                color: #f5f5f5;
            }
        }
    </style>
</head>
<body>
    <pre>\(convertedString)</pre>
</body>
</html>
"""
            webView.loadHTMLString(htmlString, baseURL: nil)
        }
        
    }
    

    // Make sure we convert HTML special characters
    // Code from https://gist.github.com/mikesteele/70ae98d04fdc35cb1d5f
    func convertSpecialCharacters(_ string: String?) -> String? {
        guard let string = string else {
            return nil
        }
        var newString = string
        let char_dictionary = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'"
        ];
        for (escaped_char, unescaped_char) in char_dictionary {
            newString = newString.replacingOccurrences(of: escaped_char, with: unescaped_char, options: NSString.CompareOptions.regularExpression, range: nil)
        }
        return newString
    }
}
