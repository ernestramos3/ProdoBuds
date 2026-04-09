//
//  TimelapseViewController.swift
//  ProdoBuds
//
//  Created by Trinh, Andy on 4/1/26.
//

import UIKit
import AVFoundation
import AVKit

var comments:[String] = []

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

        // Do any additional setup after loading the view.
        guard let post = post else {
            print("Error: No post data received")
            return
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let totalRows = tableView.numberOfRows(inSection: 0)
        
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
                
                var likeCount = post?.likes.count ?? 0
                cell.numberOfLikesLabel.text = "\(likeCount)"
                
                cell.numberOfCommentsLabel.text = "0"
            }
            
            return cell
        }
        else if indexPath.row == totalRows - 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DraftCommentCellIdentifier", for: indexPath) as! DraftCommentViewCell
            
            cell.usernameLabel.text = post?.user ?? "unknown"
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostedCommentCellIdentifier", for: indexPath) as! PostedCommentViewCell
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 890
        }
        
        return 120
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight = keyboardFrame.cgRectValue.height
            let safeAreaBottom = view.safeAreaInsets.bottom
            
            // move bar up, but subtract the safe area to avoid "double jumping"
            commentBarBottomConstraint.constant = keyboardHeight - safeAreaBottom
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        // return comment to bottom safe area
        commentBarBottomConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
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
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
                
        // Configure the view for the selected state
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
    }
    
    @IBAction func playButton2Pressed(_ sender: Any) {
        if player?.timeControlStatus == .playing {
            player?.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
        else {
            player?.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
    }
    
    @IBAction func repeatButton2Pressed(_ sender: Any) {
        
    }
}

class PostedCommentViewCell: UITableViewCell {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}

class DraftCommentViewCell: UITableViewCell {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var draftTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func draftComment(_ sender: Any) {
        //draftTextField.text
    }
}
