//
//  FBFile.swift
//  FileBrowser
//
//  Created by Roy Marmelstein on 14/02/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import UIKit

/// FBFile is a class representing a file in FileBrowser
@objc open class FBFile: NSObject {
    /// Display name. String.
    @objc public let displayName: String
    // is Directory. Bool.
    public let isDirectory: Bool
    /// File extension.
    public let fileExtension: String?
    /// File attributes (including size, creation date etc).
    public let fileAttributes: NSDictionary?
    /// NSURL file path.
    public let filePath: URL
    // FBFileType
    public let type: FBFileType
    
    open func delete() {
        do {
            try FileParser.sharedInstance.fileManager.removeItem(at: self.filePath)
        } catch {
            print("An error occured when trying to delete file:\(self.filePath) Error:\(error)")
        }
    }
    
    /**
     Initialize an FBFile object with a filePath
     
     - parameter filePath: NSURL filePath
     
     - returns: FBFile object.
     */
    init(filePath: URL) {
        self.filePath = filePath
        let isDirectory = checkDirectory(filePath)
        self.isDirectory = isDirectory
        if self.isDirectory {
            self.fileAttributes = nil
            self.fileExtension = nil
            self.type = .directory
        }
        else {
            self.fileAttributes = getFileAttributes(self.filePath)
            self.fileExtension = filePath.pathExtension
            if let fileExtension {
                self.type = FBFileType(rawValue: fileExtension) ?? .default
            }
            else {
                self.type = .default
            }
        }
        self.displayName = filePath.lastPathComponent 
    }
}

/**
 FBFile type
 */
public enum FBFileType: String {
    /// Directory
    case directory = "directory"
    /// GIF file
    case gif = "gif"
    /// JPG file
    case jpg = "jpg"
    /// PLIST file
    case json = "json"
    /// PDF file
    case pdf = "pdf"
    /// PLIST file
    case plist = "plist"
    /// PNG file
    case png = "png"
    /// ZIP file
    case zip = "zip"
    /// Any file
    case `default` = "file"
    
    /**
     Get representative image for file type
     
     - returns: UIImage for file type
     */
    public func image() -> UIImage? {
        switch self {
        case .directory: return UIImage(systemName: "folder")
        case .jpg, .png, .gif: return UIImage(systemName: "photo")
        case .pdf: return UIImage(systemName: "doc.richtext")
        case .zip: return UIImage(systemName: "doc.zipper")
        default: return UIImage(systemName: "doc")
        }
    }
}

/**
 Check if file path NSURL is directory or file.
 
 - parameter filePath: NSURL file path.
 
 - returns: isDirectory Bool.
 */
func checkDirectory(_ filePath: URL) -> Bool {
    var isDirectory = false
    do {
        var resourceValue: AnyObject?
        try (filePath as NSURL).getResourceValue(&resourceValue, forKey: URLResourceKey.isDirectoryKey)
        if let number = resourceValue as? NSNumber, number == true {
            isDirectory = true
        }
    }
    catch { }
    return isDirectory
}

func getFileAttributes(_ filePath: URL) -> NSDictionary? {
    let path = filePath.path
    let fileManager = FileParser.sharedInstance.fileManager
    do {
        let attributes = try fileManager.attributesOfItem(atPath: path) as NSDictionary
        return attributes
    } catch {}
    return nil
}
