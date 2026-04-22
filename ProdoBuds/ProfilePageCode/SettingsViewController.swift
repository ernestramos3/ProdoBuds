//
//  SettingsViewController.swift
//  ProdoBuds
//
//  Created by Kevin Evans on 4/20/26.
//

import UIKit
import FirebaseAuth

final class SettingsViewController: UIViewController {

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
