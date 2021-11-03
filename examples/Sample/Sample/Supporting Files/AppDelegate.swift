//
//  AppDelegate.swift
//  Sample
//
//  Created by Mihail Șalari on 9/16/16.
//  Copyright © 2016 Mihail Șalari. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.populateTableViewWithFiles()
        
        return true
    }

    fileprivate func populateTableViewWithFiles() {
        let defaultsKey = "firstLaunch"
        let userDefaults = UserDefaults.standard
        let fileManager = FileManager.default
        let fileNames = ["Baymax.jpg", "BB8.jpg", "Stitch.jpg", "Info.plist"]
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let bundleUrl = Bundle.main.resourceURL
        
        // Copy zip file to an images directory
        let imagesDirectoryURL = documentsUrl.appendingPathComponent("images")
        let zipFileName = "Images.zip"
        let imagesDirectoryPath = imagesDirectoryURL.path
        
        if userDefaults.bool(forKey: defaultsKey) == false {
            userDefaults.set(true, forKey: defaultsKey)
            userDefaults.synchronize()
            
            // Copy images to documents folder
            for file in fileNames {
                if let srcPath = bundleUrl?.appendingPathComponent(file).path {
                    let toPath = documentsUrl.appendingPathComponent(file).path
                    do {
                        try fileManager.copyItem(atPath: srcPath, toPath: toPath)
                    } catch {}
                }
            }
            
            // Copy zip file to an images directory
            do {
                try fileManager.createDirectory(atPath: imagesDirectoryPath, withIntermediateDirectories: false, attributes: nil)
                if let srcPath = bundleUrl?.appendingPathComponent(zipFileName).path {
                    let toPath = imagesDirectoryURL.appendingPathComponent(zipFileName).path
                    do {
                        try fileManager.copyItem(atPath: srcPath, toPath: toPath)
                    } catch {}
                }
            } catch {}
        }
    }
}

