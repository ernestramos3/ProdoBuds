//
//  SettingsViewController.swift
//  ProdoBuds
//
//  Created by Kevin Evans on 4/20/26.
//

import UIKit
import FirebaseAuth
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

    }

    @IBAction private func logoutTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
        UserSession.shared.currentUser = nil
        // `ViewController` presents `HomeScreen` full-screen from the window root after login.
        view.window?.rootViewController?.dismiss(animated: true)
    }
}

