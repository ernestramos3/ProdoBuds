//
//  IntViewController.swift
//  ProdoBuds
//
//  Created by Evans, Kevin on 4/20/26.
//

import Foundation
import UIKit

class IntViewController: UIViewController {

    @IBOutlet weak var CommentSwitch: UISwitch!
    @IBOutlet weak var LikeSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        syncFromAccountData()
        LikeSwitch.addTarget(self, action: #selector(likeSwitchChanged), for: .valueChanged)
        CommentSwitch.addTarget(self, action: #selector(commentSwitchChanged), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncFromAccountData()
    }

    private func syncFromAccountData() {
        LikeSwitch.isOn = SettingsViewController.AccountData.showLikesOnPosts
        CommentSwitch.isOn = SettingsViewController.AccountData.showComments
    }

    @objc private func likeSwitchChanged() {
        SettingsViewController.AccountData.showLikesOnPosts = LikeSwitch.isOn
    }

    @objc private func commentSwitchChanged() {
        SettingsViewController.AccountData.showComments = CommentSwitch.isOn
    }
}
