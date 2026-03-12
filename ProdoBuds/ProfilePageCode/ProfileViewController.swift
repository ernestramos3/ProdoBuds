//
//  ProfileViewController.swift
//  ProdoBuds
//
//  Created by Trinh, Andy on 3/11/26.
//

import UIKit
//class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
class ProfileViewController: UIViewController {
    
    
    //var collectionView: UICollectionView!
    @IBOutlet weak var followingCount: UILabel!
    @IBOutlet weak var followerCount: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var bio: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //let layout = UICollectionViewFlowLayout()
        //let screenWidth = UIScreen.main.bounds.width
        //let spacing: CGFloat = 2
        //let itemSize = (screenWidth - (spacing * 2)) / 3
        
        
        //layout.itemSize = CGSize(width: itemSize, height: itemSize)
        //layout.minimumInteritemSpacing = spacing
        //layout.minimumLineSpacing = spacing
        
        //populate fields with data from the database
        //UserSession.shared.currentUser?
        followingCount.text = "0"
        followerCount.text = "0"
        username.text = UserSession.shared.currentUser?.username
        bio.text = UserSession.shared.currentUser?.bio
        
        //collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        //collectionView.backgroundColor = .white
        //collectionView.dataSource = self
        //collectionView.delegate = self
        //collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        //view.addSubview(collectionView)
        print("running")
    }
    
    //func collectionView(_ collectionView: UICollectionView, //numberOfItemsInSection section: Int) -> Int {
        //return 9
    //}
    
    //func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    //    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    //    let imageView = UIImageView(frame: cell.contentView.frame)
    //    imageView.image = UIImage(named: "exampleImage")
    //    imageView.contentMode = .scaleAspectFill
    //    imageView.clipsToBounds = true
    //    cell.contentView.addSubview(imageView)
        
    //    return cell
    //}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

