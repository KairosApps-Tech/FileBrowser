//
//  FileBrowserNavigationController.swift
//  FileBrowserNavigationController
//
//  Created by Roy Marmelstein on 14/02/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import UIKit

/// File browser containing navigation controller.
open class FileBrowserNavigationController: UINavigationController, ClosingDelegate {

    let parser = FileParser.sharedInstance
    
    var fileList: FileListTableViewController?
    
    var onDismiss: (() -> Void)?
    
    /// File types to exclude from the file browser.
    open var excludesFileExtensions: [String]? {
        didSet {
            parser.excludesFileExtensions = excludesFileExtensions
        }
    }
    
    /// File paths to exclude from the file browser.
    open var excludesFilepaths: [URL]? {
        didSet {
            parser.excludesFilepaths = excludesFilepaths
        }
    }
    
    /// Override default preview and actionsheet behaviour in favour of custom file handling.
    open var didSelectFile: ((FBFile) -> ())? {
        didSet {
            fileList?.didSelectFile = didSelectFile
        }
    }
    
    public convenience init() {
        let parser = FileParser.sharedInstance
        let path = parser.documentsURL
        self.init(initialPath: path, allowEditing: true, onDismiss: nil)
    }
    
    /// Initialise file browser.
    ///
    /// - Parameters:
    ///   - initialPath: NSURL filepath to containing directory.
    ///   - allowEditing: Whether to allow editing.
    ///   - showCancelButton: Whether to show the cancel button.
    public convenience init(initialPath: URL? = nil, allowEditing: Bool = false, showCloseButton: Bool = true, onDismiss: (() -> Void)?) {
        let validInitialPath = initialPath ?? FileParser.sharedInstance.documentsURL
        
        let fileListViewController = FileListTableViewController(initialPath: validInitialPath, showCloseButton: showCloseButton)

        self.init(rootViewController: fileListViewController)

        fileListViewController.allowEditing = allowEditing
        fileListViewController.closingDelegate = self

        self.fileList = fileListViewController
        self.onDismiss = onDismiss
    }

    func didTouchCloseButton() {
        onDismiss?()
        dismiss(animated: true)
    }

}
