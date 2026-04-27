//
//  TimelapseViewController.swift
//  ProdoBuds
//
//  Created by Trinh, Andy on 4/1/26.
//

import UIKit
import AVFoundation
import AVKit
import FirebaseFirestore

var comments:[Comment] = []
var currentPost: Post? = nil

// Comment model
struct Comment {
    let id: String
    let userId: String
    let username: String
    let commentText: String
    let timestamp: Timestamp?
    
    init(id: String, dictionary: [String: Any]) {
        self.id = id
        self.userId = dictionary["userId"] as? String ?? ""
        self.username = dictionary["username"] as? String ?? ""
        self.commentText = dictionary["commentText"] as? String ?? ""
        self.timestamp = dictionary["timestamp"] as? Timestamp
    }
}

class TimelapseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var timelapseTableView: UITableView!
    @IBOutlet weak var commentBarBottomConstraint: NSLayoutConstraint!
    
    var post: Post?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timelapseTableView.delegate = self
        timelapseTableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // Do any additional setup after loading the view.
        guard let post = post else {
            print("Error: No post data received")
            return
        }
        
        currentPost = post
        
        // Load comments for this post
        loadComments()
    }
    
    func loadComments() {
        guard let postId = post?.getID(), !postId.isEmpty else {
            return
        }
        
        let db = Firestore.firestore()
        db.collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    print("Error loading comments: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    return
                }
                
                comments = documents.map { doc in
                    Comment(id: doc.documentID, dictionary: doc.data())
                }
                
                DispatchQueue.main.async {
                    self?.timelapseTableView.reloadData()
                }
            }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timelapseTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 1 header + number of comments + 1 draft comment cell
        return 1 + comments.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let totalRows = tableView.numberOfRows(inSection: 0)
        
        // First row is always the header
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TimelapseHeaderCellIdentifier", for: indexPath) as! TimelapseHeaderViewCell
            
            if let postData = self.post {
                cell.setupVideo(with: postData.getVideoURL())
                cell.usernameLabel.text = post?.user ?? "unknown"
                
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
                    cell.profileImage.image = UIImage(systemName: "person.circle.fill")
                }
                
                cell.descriptionLabel.text = post?.description ?? "unknown"
                
                let isLiked = post?.checkForUserInLikes(username: UserSession.shared.currentUser?.username ?? "") ?? false
                let heartImageName = isLiked ? "heart.fill" : "heart"
                print(heartImageName)
                cell.likeButton.setImage(UIImage(systemName: heartImageName), for: .normal)
                cell.likeButton.tintColor = .systemGreen
                
                var likeCount = post?.likes.count ?? 0
                cell.numberOfLikesLabel.text = "\(likeCount)"
                
                cell.numberOfCommentsLabel.text = "\(comments.count)"
            }
            
            return cell
        }
        // Last row is always the draft comment cell
        else if indexPath.row == totalRows - 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DraftCommentCellIdentifier", for: indexPath) as! DraftCommentViewCell
            
            // Show the current user's username, not the post owner's
            cell.usernameLabel.text = UserSession.shared.currentUser?.username ?? "unknown"
            
            // Set profile image for current user
            let urlString = UserSession.shared.currentUser?.profileImageURL ?? ""
            if let url = URL(string: urlString) {
                cell.profileImage.image = nil
                
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.profileImage.image = image
                        }
                    }
                }.resume()
            } else {
                cell.profileImage.image = UIImage(systemName: "person.circle.fill")
            }
            
            return cell
        }
        // Middle rows are posted comments
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostedCommentCellIdentifier", for: indexPath) as! PostedCommentViewCell
            
            // Get the comment for this row (subtract 1 because row 0 is the header)
            let commentIndex = indexPath.row - 1
            if commentIndex < comments.count {
                let comment = comments[commentIndex]
                cell.usernameLabel.text = comment.username
                cell.commentLabel.text = comment.commentText
                
                // TODO: Load profile image based on userId
                // For now, use a placeholder
                cell.profileImage.image = UIImage(systemName: "person.circle.fill")
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 890
        }
        
        // Increased height for comment cells to accommodate constraints
        return 150
    }
    
    // show keyboard
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight = keyboardFrame.cgRectValue.height
            let safeAreaBottom = view.safeAreaInsets.bottom
            
            // move bar up, but subtract the safe area to avoid "double jumping"
            commentBarBottomConstraint.constant = keyboardHeight - safeAreaBottom
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
            
            // Scroll to the last row (comment input cell) to make it visible
            let lastRow = tableView(timelapseTableView, numberOfRowsInSection: 0) - 1
            if lastRow >= 0 {
                let indexPath = IndexPath(row: lastRow, section: 0)
                timelapseTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    // hide keyboard
    @objc func keyboardWillHide(notification: NSNotification) {
        // return comment to bottom safe area
        commentBarBottomConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // dismiss keyboard when tapping outside
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

class TimelapseHeaderViewCell: UITableViewCell {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var numberOfCommentsLabel: UILabel!
    @IBOutlet weak var numberOfLikesLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // initialization code
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.clipsToBounds = true
        profileImage.contentMode = .scaleAspectFill
    }
    
    // setup player
    func setupVideo(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        if player == nil {
            player = AVPlayer(url: url)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.videoGravity = .resizeAspectFill
            
            videoContainerView.layoutIfNeeded()
            playerLayer?.frame = videoContainerView.bounds
            
            videoContainerView.layer.addSublayer(playerLayer!)
        }
        
        // for replaying purposes
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { [weak self] _ in
            self?.playButton.setImage(UIImage(systemName: "goforward"), for: .normal)
        }
    }
    
    @IBAction func likeButton2Pressed(_ sender: Any) {
        var username = UserSession.shared.currentUser?.username ?? ""
        
        var id = currentPost?.getID() ?? ""
        let db = Firestore.firestore()
        let postRef = db.collection("posts")
            .document(id)
        
        let config = UIImage.SymbolConfiguration(pointSize: likeButton.frame.height * 0.35, weight: .regular)
        let wasRemoved = currentPost?.changeLikes(username: username) ?? false
        var image = UIImage(systemName: "heart", withConfiguration: config)
        
        if wasRemoved {
            postRef.updateData(["likes" : FieldValue.arrayRemove([username])])
        }
        else {
            image = UIImage(systemName: "heart.fill", withConfiguration: config)
            postRef.updateData(["likes" : FieldValue.arrayUnion([username])])
        }
        
        likeButton.setImage(image, for: .normal)
        likeButton.tintColor = .systemGreen
        numberOfLikesLabel.text = "\(currentPost?.getNumberOfLikes() ?? 0)"
    }
    
    @IBAction func playButton2Pressed(_ sender: Any) {
        if player?.timeControlStatus == .playing {
            player?.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
        else {
            // if player is at the very end, seek to the beginning first
            if player?.currentItem?.duration == player?.currentTime() {
                player?.seek(to: .zero)
            }
            
            player?.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
    }
}

class PostedCommentViewCell: UITableViewCell {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // initialization code
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.clipsToBounds = true
        profileImage.contentMode = .scaleAspectFill
    }
}

class DraftCommentViewCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var draftTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // initialization code
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.clipsToBounds = true
        profileImage.contentMode = .scaleAspectFill
        
        // Set text field delegate to handle return key (with safety check)
        draftTextField?.delegate = self
    }
    
    // Handle return key to dismiss keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    @IBAction func postComment(_ sender: Any) {
        // Safety check for text field
        guard let textField = draftTextField else {
            return
        }
        
        // Get the comment text
        guard let commentText = textField.text, !commentText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Get user information from UserSession
        guard let currentUser = UserSession.shared.currentUser else {
            return
        }
        
        // Get the post ID
        guard let postId = currentPost?.getID(), !postId.isEmpty else {
            return
        }
        
        // Create Firestore reference
        let db = Firestore.firestore()
        let commentsRef = db.collection("posts")
            .document(postId)
            .collection("comments")
        
        // Prepare comment data
        let commentData: [String: Any] = [
            "userId": currentUser.uid,
            "username": currentUser.username,
            "commentText": commentText,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        // Add comment to Firestore
        commentsRef.addDocument(data: commentData) { [weak self] error in
            if let error = error {
                print("Error posting comment: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    // Clear the text field
                    self?.draftTextField?.text = ""
                    
                    // Dismiss the keyboard
                    self?.draftTextField?.resignFirstResponder()
                }
            }
        }
    }
}
