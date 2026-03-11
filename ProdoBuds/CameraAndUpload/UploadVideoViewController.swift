//
//  UploadVideoViewController.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/10/26.
//

import UIKit
import AVFoundation
import AVKit

class UploadVideoViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var captionField: UITextField!
    @IBOutlet weak var timeLabel: UILabel! // Make sure to connect this UILabel in your storyboard
    
    var player: AVPlayer!
    var avpController = AVPlayerViewController()
    var videoURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captionField.delegate = self
        
        videoView.layer.cornerRadius = 10.0
        videoView.clipsToBounds = true
        
        startVideo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func startVideo() {
        guard let url = videoURL else {
            print("Error: videoURL is nil")
            return
        }
        player = AVPlayer(url: url)
        avpController.player = player
        avpController.view.frame.size.height = videoView.frame.size.height
        avpController.view.frame.size.width = videoView.frame.size.width
        self.videoView.addSubview(avpController.view)
        player.play()
    }
    
    // Called when 'return' key pressed

    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Called when the user clicks on the view outside of the UITextField

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

}
