//
//  SettingsViewController.swift
//  ProdoBuds
//
//  Created by Kevin Evans on 4/20/26.
//

import UIKit
import Foundation

final class SettingsViewController: UIViewController {
    // Shared account settings data
    enum AccountData {
        // true = private, false = public (On = Private)
        static var isPrivateAccount: Bool = true
        
        // Blocked users shown on the privacy screen
        static var blockedAccountNames: [String] = []
        
        static var showLikesOnPosts: Bool = true
        static var showComments: Bool = true
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        
        // You cannot declare types (enum/class/struct) inside a function like this.
        // Move AccountData OUTSIDE of viewDidLoad.
    }
}

