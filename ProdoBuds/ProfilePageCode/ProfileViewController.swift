//
//  ProfileViewController.swift
//  ProdoBuds
//
//  Created by Trinh, Andy on 3/11/26.
//

var currentUserPosts:[Post] = []

import UIKit
import FirebaseFirestore
import FirebaseStorage

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var profileView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileView.delegate = self
        profileView.dataSource = self
        
//        let layout = UICollectionViewFlowLayout()
//        layout.minimumInteritemSpacing = 1
//        layout.minimumLineSpacing = 1
//        profileView.collectionViewLayout = layout
        
        if let layout = profileView.collectionViewLayout as? UICollectionViewFlowLayout {
            let padding: CGFloat = 2
//            let totalPadding = padding
//            let individualWidth = (view.frame.width - totalPadding) / 3
//            
//            layout.itemSize = CGSize(width: individualWidth, height: individualWidth)
            
            layout.minimumLineSpacing = padding
            layout.minimumInteritemSpacing = padding
//            layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        }
        
        // Do any additional setup after loading the view.
        fetchPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchPosts()
    }
    
    func fetchPosts() {
        guard let currentUsername = UserSession.shared.currentUser?.username else { return }
        
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        db.collection("posts")
            .whereField("user", isEqualTo: currentUsername)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("error in getting documents: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else { return }
                // create a group to track all background URL fetches
                let group = DispatchGroup()
                var fetchedPosts: [Post] = []
                
                for document in documents {
                    var data = document.data()
                    let gsPath = data["videoURL"] as? String ?? ""
                    
                    if gsPath.hasPrefix("gs://") {
                        group.enter() // tells group we are starting a task
                        
                        let ref = storage.reference(forURL: gsPath)
                        ref.downloadURL { (url, error) in
                            if let downloadURL = url {
                                // swap internal path for public https link
                                data["videoURL"] = downloadURL.absoluteString
                            }
                            
                            let post = Post(dictionary: data)
                            fetchedPosts.append(post)
                            
                            group.leave() // tells group this task is done
                        }
                    }
                    else {
                        let post = Post(dictionary: data)
                        fetchedPosts.append(post)
                    }
                }
                
                group.notify(queue: .main) {
                    currentUserPosts = fetchedPosts
                    self.profileView.reloadData()
                }
            }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentUserPosts.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileHeaderCellIdentifier", for: indexPath) as! ProfileHeaderViewCell
            // populate fields with data from the database
            // UserSession.shared.currentUser? - syntax for accessing currentUser fields
            
            // because application does not allow users to view other profiles, these fields are hardcoded for now
            cell.followingCountLabel.text = "0"
            cell.followersCountLabel.text = "0"
                        
            cell.usernameLabel.text = UserSession.shared.currentUser?.username
            cell.bioLabel.text = UserSession.shared.currentUser?.bio
            
            let urlString = UserSession.shared.currentUser?.profileImageURL ?? ""
            
            if let url = URL(string: urlString) {
                cell.profileImage.image = nil
                
                URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.profileImage.image = image
                        }
                    }
                }.resume()
            }
            else {
                cell.profileImage.image = UIImage(named: "yes")
            }
            
            cell.profileImage.contentMode = .scaleAspectFill
            cell.profileImage.clipsToBounds = true
            
            cell.profileImage.layer.cornerRadius = cell.profileImage.frame.width / 2
            cell.profileImage.layer.borderWidth = 1
            cell.profileImage.layer.borderColor = UIColor.lightGray.cgColor
            
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostGridCellIdentifier", for: indexPath) as! PostGridViewCell
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == 0 {
            return CGSize(width: collectionView.frame.width, height: 436)
        }
        
        let padding: CGFloat = 2
        let totalPadding = padding * 4
        let width = floor((collectionView.frame.width - totalPadding) / 3)
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // skip profile header
        guard indexPath.item > 0 else { return }
        
        let selectedPost = currentUserPosts[indexPath.item - 1]
        
        performSegue(withIdentifier: "TimelapseSegueIdentifier", sender: selectedPost)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TimelapseSegueIdentifier" {
            // get destination controller
            if let timelapseVC = segue.destination as? TimelapseViewController {
                // cast sender back into a Post object
                
                if let post = sender as? Post {
                    // inject data into the destination
                    timelapseVC.post = post
                    print("Success in passing postdata")
                }
                else {
                    print("Failure in passing postdata")
                }
            }
        }
    }
}

class ProfileHeaderViewCell: UICollectionViewCell {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var followersCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func configure() {
        
    }
}

class PostGridViewCell: UICollectionViewCell {
    @IBOutlet weak var postView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func configure() {
        
    }
}
