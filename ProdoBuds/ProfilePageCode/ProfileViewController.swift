//
//  ProfileViewController.swift
//  ProdoBuds
//
//  Created by Trinh, Andy on 3/11/26.
//

import UIKit
class ProfileViewController: UIViewController {
    
    // fields to be populated by database
    @IBOutlet weak var followingCount: UILabel!
    @IBOutlet weak var followerCount: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var bio: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // populate fields with data from the database
        // UserSession.shared.currentUser? - syntax for accessing currentUser fields
        
        // because application does not allow users to view other profiles, these fields are hardcoded for now
        followingCount.text = "0"
        followerCount.text = "0"
        
        username.text = UserSession.shared.currentUser?.username
        bio.text = UserSession.shared.currentUser?.bio
        
        // DISCLAIMER:  this class originally had protocols like UICollectionViewDelegate with the intention of
        // implementing a CollectionView to establish a grid of videos. With each video post, it was intended to
        // be clickable so it would be directed to another ViewController where the user could view the video post.
        // Due to time constraints, this would have to be scrapped for Alpha release and be delegated to Beta release.
    }
}

