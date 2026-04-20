//
//  SettingsViewController.swift
//  ProdoBuds
//
//  Created by Kevin Evans on 4/20/26.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// add the shared account settings data here ...

extension SettingsViewController {

    enum AccountData {
        // true = private, false = public (matches privacy switch: On = Private).
        static var isPrivateAccount: Bool = true

        // Blocked users shown on the privacy screen.
        static var blockedAccountNames: [String] = []

        static var showLikesOnPosts: Bool = true
        static var showComments: Bool = true
    }
}
