//
//  PrivacyViewController.swift
//  ProdoBuds
//
//  Created by Evans, Kevin on 4/20/26.
//

import Foundation
import UIKit

private let blockedAccountCellId = "BlockedAccountCell"

class PrivacyViewController: UIViewController, UITableViewDataSource {


    @IBOutlet weak var BlockedTable: UITableView!
    @IBOutlet weak var PrivacySwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PrivacySwitch.isOn = SettingsViewController.AccountData.isPrivateAccount
        PrivacySwitch.addTarget(self, action: #selector(privacySwitchChanged), for: .valueChanged)

        BlockedTable.dataSource = self
        BlockedTable.register(UITableViewCell.self, forCellReuseIdentifier: blockedAccountCellId)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PrivacySwitch.isOn = SettingsViewController.AccountData.isPrivateAccount
        BlockedTable.reloadData()
    }

    @objc private func privacySwitchChanged() {
        SettingsViewController.AccountData.isPrivateAccount = PrivacySwitch.isOn
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SettingsViewController.AccountData.blockedAccountNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: blockedAccountCellId, for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = SettingsViewController.AccountData.blockedAccountNames[indexPath.row]
        cell.contentConfiguration = config
        return cell
    }
}
