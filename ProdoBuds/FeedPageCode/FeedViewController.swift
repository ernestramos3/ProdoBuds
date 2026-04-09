//
//  FeedViewController.swift
//  ProdoBuds
//
//  Created by Trinh, Andy on 4/6/26.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

var globalPosts:[Post] = []

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FeedPostViewCellDelegate  {

    @IBOutlet weak var feedTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        feedTableView.delegate = self
        feedTableView.dataSource = self

        // Do any additional setup after loading the view.
        
        // load posts onto globalPosts
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        db.collection("posts")
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
                    
                    globalPosts = sortedPosts
                    
                    self.feedTableView.reloadData()
                }
            }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return globalPosts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedPostCellIdentifier", for: indexPath) as! FeedPostViewCell
        cell.delegate = self
        
        // get specific post from array
        let specificPost = globalPosts[indexPath.row]
        
        // inject it into cell's post variable
        cell.post = specificPost
        
        cell.profileImage.image = UIImage(systemName: "person.circle.fill")
        
        cell.usernameLabel.text = specificPost.getUser()
        
        cell.descriptionLabel.text = specificPost.getDescription()
        
        cell.numberOfLikesLabel.text = "\(specificPost.likes.count)"
        
        let db = Firestore.firestore()
        
        db.collection("users")
            .whereField("user", isEqualTo: specificPost.getUser())
            .limit(to: 1) // just need one
            .getDocuments { (querySnapshot, error) in
                guard let document = querySnapshot?.documents.first,
                      let urlString = document.data()["profileImageURL"] as? String,
                      let url = URL(string: urlString) else { return }


                    
                URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            if cell.post?.user == specificPost.getUser() {
                                cell.profileImage.image = image
                            }
                        }
                    }
                }.resume()
            }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPost = globalPosts[indexPath.row]
        
        performSegue(withIdentifier: "TimelapseSegueIdentifier", sender: selectedPost)
    }
    
    func didTapProfile(for username: String) {
        performSegue(withIdentifier: "ProfileSegueIdentifier", sender: username)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ProfileSegueIdentifier", let destinationVC = segue.destination as? ProfileViewController, let username = sender as? String {
            
            destinationVC.userToLoad = username
        }
        
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 750
    }
}

class FeedPostViewCell: UITableViewCell {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfCommentsLabel: UILabel!
    @IBOutlet weak var numberOfLikesLabel: UILabel!
    weak var delegate: FeedPostViewCellDelegate?
    var post: Post?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // initialization code
        profileImage.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        profileImage.addGestureRecognizer(tap)
    }
    
    @objc func handleProfileTap() {
        if let username = post?.user {
            delegate?.didTapProfile(for: username)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        profileImage.layer.cornerRadius = profileImage.frame.width / 2
        profileImage.clipsToBounds = true
    }
}


protocol FeedPostViewCellDelegate: AnyObject {
    func didTapProfile(for username: String)
}
