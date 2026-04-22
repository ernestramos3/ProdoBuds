//
//  AccountPrivacyViewController.swift
//  ProdoBuds
//
//  Created by Kevin Evans on 4/20/26.
//


import UIKit
import FirebaseFirestore

final class AccountPrivacyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var privateAccountSwitch: UISwitch!
    @IBOutlet weak var blockedTableView: UITableView!

    private var blockedUsernames: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Account Privacy"
        blockedTableView.delegate = self
        blockedTableView.dataSource = self
        blockedTableView.register(UITableViewCell.self, forCellReuseIdentifier: "blockedCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshFromSessionThenFirestore()
    }

    private func refreshFromSessionThenFirestore() {
        if let u = UserSession.shared.currentUser {
            privateAccountSwitch.isOn = u.accountIsPrivate
            blockedUsernames = u.blockedUsernames
            blockedTableView.reloadData()
        }

        guard let uid = UserSession.shared.currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let self, let data = snapshot?.data() else { return }
            DispatchQueue.main.async {
                if let v = data["accountIsPrivate"] as? Bool {
                    self.privateAccountSwitch.isOn = v
                }
                if let list = data["blockedUsers"] as? [String] {
                    self.blockedUsernames = list
                    self.blockedTableView.reloadData()
                }
                if let user = UserSession.shared.currentUser {
                    UserSession.shared.currentUser = AppUser.mergingFirestoreProfile(data, into: user)
                }
            }
        }
    }

    @IBAction func privateSwitchChanged(_ sender: UISwitch) {
        persistPrivacy(blockedOverride: nil)
    }

    private func persistPrivacy(blockedOverride: [String]?) {
        guard let uid = UserSession.shared.currentUser?.uid else { return }
        let blocked = blockedOverride ?? blockedUsernames
        Firestore.firestore().collection("users").document(uid).updateData([
            "accountIsPrivate": privateAccountSwitch.isOn,
            "blockedUsers": blocked
        ]) { [weak self] error in
            guard error == nil, let self else { return }
            DispatchQueue.main.async {
                self.blockedUsernames = blocked
                if var user = UserSession.shared.currentUser {
                    user.accountIsPrivate = self.privateAccountSwitch.isOn
                    user.blockedUsernames = blocked
                    UserSession.shared.currentUser = user
                }
                self.blockedTableView.reloadData()
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        blockedUsernames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "blockedCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = blockedUsernames[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        blockedUsernames.remove(at: indexPath.row)
        persistPrivacy(blockedOverride: blockedUsernames)
    }
}
