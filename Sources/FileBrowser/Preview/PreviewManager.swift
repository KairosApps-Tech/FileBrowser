//
//  PreviewManager.swift
//  FileBrowser
//
//  Created by Roy Marmelstein on 16/02/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import Foundation
import QuickLook

class PreviewManager: NSObject, QLPreviewControllerDataSource {
    
    var filePath: URL?
    
    func previewViewControllerForFile(_ file: FBFile) -> UIViewController {
        if file.type == .plist || file.type == .json {
            let webviewPreviewViewController = WebviewPreviewViewContoller()
            webviewPreviewViewController.file = file
            return webviewPreviewViewController
        } else {
            let quickLookPreviewController = FBQLPreviewController()
            quickLookPreviewController.dataSource = self

            filePath = file.filePath

            return quickLookPreviewController
        }
    }

    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        if let filePath = filePath {
            return filePath as QLPreviewItem
        }
        fatalError("Fail")
    }
    
}

class FBQLPreviewController: QLPreviewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
}
