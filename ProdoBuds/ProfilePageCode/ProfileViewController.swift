//
//  ProfileViewController.swift
//  ProdoBuds
//
//  Created by Trinh, Andy on 3/11/26.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var profileView: UICollectionView!
    
    var userToLoad:String?
    var currentUserPosts:[Post] = []
    var profileOwnerData:[String: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var targetedUser = userToLoad ?? UserSession.shared.currentUser?.username ?? ""
        
        profileView.delegate = self
        profileView.dataSource = self
        
        if let layout = profileView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layout.minimumInteritemSpacing = 2
            layout.minimumLineSpacing = 2
        }
        
        // Do any additional setup after loading the view.
        fetchProfileData(username: targetedUser)
        fetchPosts(username: targetedUser)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let targetedUser = userToLoad ?? UserSession.shared.currentUser?.username ?? ""
        fetchProfileData(username: targetedUser)
        fetchPosts(username: targetedUser)
    }
    
    func fetchProfileData(username: String) {
        let db = Firestore.firestore()
        
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { (snapshot, error) in
            if let document = snapshot?.documents.first {
                let data = document.data()
                self.profileOwnerData = data
                
                // reload header info to show new info
                DispatchQueue.main.async {
                    self.profileView.reloadItems(at: [IndexPath(item: 0, section: 0)])
                }
            }
            else {
                print("No user document")
            }
        }
        
    }
    
    func fetchPosts(username: String) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        // query into database to fetch posts made by user of the current profile being viewed
        db.collection("posts")
            .whereField("user", isEqualTo: username)
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
                    let sortedPosts = fetchedPosts.sorted {
                        ($0.timestamp?.dateValue() ?? Date.distantPast) > ($1.timestamp?.dateValue() ?? Date.distantPast)
                    }
                    
                    self.currentUserPosts = sortedPosts
                    
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
            
            // determine if this profile of currently logged in user to show/hide follow button
            let isMe = (userToLoad == nil || userToLoad == UserSession.shared.currentUser?.username)
            cell.followButton.isHidden = isMe
            
            // Update follow button text based on whether we're already following this user
            if !isMe, let targetUsername = profileOwnerData?["username"] as? String {
                let isFollowing = UserSession.shared.currentUser?.following.contains(targetUsername) ?? false
                cell.followButton.setTitle(isFollowing ? "Unfollow" : "Follow", for: .normal)
            }
            
            // if the user is viewing themselves grab their own following base
            if isMe {
                cell.followingCountLabel.text = String(UserSession.shared.currentUser?.following.count ?? 0)
                cell.followersCountLabel.text = String(UserSession.shared.currentUser?.followers.count ?? 0)
            }
            // if the user is viewing another person, grab the person they are viewing following base
            else {
                if let data = profileOwnerData {
                    let followingArray = data["following"] as? [String] ?? []
                    let followersArray = data["followers"] as? [String] ?? []
                    cell.followingCountLabel.text = String(followingArray.count)
                    cell.followersCountLabel.text = String(followersArray.count)
                }
                else {
                    cell.followingCountLabel.text = "0"
                    cell.followersCountLabel.text = "0"
                }
            }
            
            if let data = profileOwnerData {
                cell.usernameLabel.text = data["username"] as? String
                cell.bioLabel.text = data["bio"] as? String
                
                let urlString = data["profileImageURL"] as? String ?? ""
                
                cell.profileImage.image = UIImage(systemName: "person.circle.fill")
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
                
                cell.profileImage.contentMode = .scaleAspectFill
                cell.profileImage.clipsToBounds = true
                
                cell.profileImage.layer.cornerRadius = cell.profileImage.frame.width / 2
                cell.profileImage.layer.borderWidth = 1
                cell.profileImage.layer.borderColor = UIColor.lightGray.cgColor
            }
            
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostGridCellIdentifier", for: indexPath) as! PostGridViewCell
        
        var specificPost = currentUserPosts[indexPath.item - 1]
                
        // download thumbnail image
        if let thumbnailURL = URL(string: specificPost.thumbnailURL) {
            self.downloadImage(from: thumbnailURL) { image in
                DispatchQueue.main.async {
                    cell.postImageView?.image = image
                }
            }
        }
        
        return cell
    }
    
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                completion(UIImage(data: data))
            }
            else {
                completion(nil)
            }
        }.resume()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == 0 {
            return CGSize(width: collectionView.frame.width, height: 436)
        }
        
        let availableWidth = collectionView.frame.width - 4
        let width = floor(availableWidth / 3)
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
    @IBOutlet weak var followButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func configure() {
        
    }
    
    @IBAction func followButton2Pressed(_ sender: Any) {
        let db = Firestore.firestore()
        
        let buttonText = followButton.titleLabel?.text
        
        // meaning that you are trying to follow the user
        if buttonText == "Follow"{
            db.collection("users")
                .whereField("username", isEqualTo: usernameLabel.text ?? "")
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("No user was found")
                        return
                    }
                    
                    let doc = documents.first!
                    let data = doc.data()
                    let targetUsername = data["username"] as? String ?? ""
                    let targetUID = doc.documentID
                    
                    // add the user that you are following to your following
                    db.collection("users").document(UserSession.shared.currentUser?.uid ?? "").updateData([
                        "following": FieldValue.arrayUnion([targetUsername])
                    ]) { error in
                        if error == nil {
                            // Update local UserSession with the new following
                            if var user = UserSession.shared.currentUser,
                               !user.following.contains(targetUsername) {
                                user.following.append(targetUsername)
                                UserSession.shared.currentUser = user
                            }
                        }
                    }
                    
                    // add yourself to the user that you are following followers
                    db.collection("users").document(targetUID).updateData([
                        "followers": FieldValue.arrayUnion([UserSession.shared.currentUser?.username ?? ""])
                    ]) { error in
                        if error == nil {
                            // Update the follower count in the UI
                            DispatchQueue.main.async {
                                if let currentCount = Int(self.followersCountLabel.text ?? "0") {
                                    self.followersCountLabel.text = String(currentCount + 1)
                                }
                            }
                        }
                    }
                }
        UIView.transition(with: followButton, duration: 0.3, options: .transitionCrossDissolve, animations:{
            self.followButton.setTitle("Unfollow", for: .normal)
        }, completion: nil)
        }
        // meaning that they want to unfollow
        else{
            db.collection("users")
                .whereField("username", isEqualTo: usernameLabel.text ?? "")
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("No user was found")
                        return
                    }
                    
                    let doc = documents.first!
                    let data = doc.data()
                    let targetUsername = data["username"] as? String ?? ""
                    let targetUID = doc.documentID
                    
                    // remove the that person from your following
                    db.collection("users").document(UserSession.shared.currentUser?.uid ?? "").updateData([
                        "following": FieldValue.arrayRemove([targetUsername])
                    ]) { error in
                        if error == nil {
                            // Update local UserSession by removing from following
                            if var user = UserSession.shared.currentUser,
                               let index = user.following.firstIndex(of: targetUsername) {
                                user.following.remove(at: index)
                                UserSession.shared.currentUser = user
                            }
                        }
                    }
                    
                    // remove yourself from that persons followers list
                    db.collection("users").document(targetUID).updateData([
                        "followers": FieldValue.arrayRemove([UserSession.shared.currentUser?.username ?? ""])
                    ]) { error in
                        if error == nil {
                            // Update the follower count in the UI
                            DispatchQueue.main.async {
                                if let currentCount = Int(self.followersCountLabel.text ?? "0"), currentCount > 0 {
                                    self.followersCountLabel.text = String(currentCount - 1)
                                }
                            }
                        }
                    }
                }
            UIView.transition(with: followButton, duration: 0.3, options: .transitionCrossDissolve, animations:{
                self.followButton.setTitle("Follow", for: .normal)
            }, completion: nil)
        }
    }
}

class PostGridViewCell: UICollectionViewCell {
    @IBOutlet weak var postImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func configure() {
        
    }
}
