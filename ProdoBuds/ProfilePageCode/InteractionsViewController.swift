//
//  InteractionsViewController.swift
//  ProdoBuds
//
//  Created by Kevin Evans on 4/20/26.
//

import UIKit
import FirebaseFirestore

final class InteractionsViewController: UIViewController {

    @IBOutlet weak var showLikesSwitch: UISwitch!
    @IBOutlet weak var showCommentsSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interactions"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshFromSessionThenFirestore()
    }

    private func refreshFromSessionThenFirestore() {
        if let u = UserSession.shared.currentUser {
            showLikesSwitch.isOn = u.showLikesOnPosts
            showCommentsSwitch.isOn = u.showCommentsOnPosts
        }

        guard let uid = UserSession.shared.currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let self, let data = snapshot?.data() else { return }
            DispatchQueue.main.async {
                if let v = data["showLikesOnPosts"] as? Bool {
                    self.showLikesSwitch.isOn = v
                }
                if let v = data["showCommentsOnPosts"] as? Bool {
                    self.showCommentsSwitch.isOn = v
                }
                if let user = UserSession.shared.currentUser {
                    UserSession.shared.currentUser = AppUser.mergingFirestoreProfile(data, into: user)
                }
            }
        }
    }

    @IBAction func showLikesChanged(_ sender: UISwitch) {
        persistInteractions()
    }

    @IBAction func showCommentsChanged(_ sender: UISwitch) {
        persistInteractions()
    }

    private func persistInteractions() {
        guard let uid = UserSession.shared.currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).updateData([
            "showLikesOnPosts": showLikesSwitch.isOn,
            "showCommentsOnPosts": showCommentsSwitch.isOn
        ]) { [weak self] error in
            guard error == nil, let self else { return }
            DispatchQueue.main.async {
                if var user = UserSession.shared.currentUser {
                    user.showLikesOnPosts = self.showLikesSwitch.isOn
                    user.showCommentsOnPosts = self.showCommentsSwitch.isOn
                    UserSession.shared.currentUser = user
                }
            }
        }
    }
}
