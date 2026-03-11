//
//  UploadVideoViewController.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/10/26.
//

import UIKit
import AVFoundation
import AVKit

class UploadVideoViewController: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var timeLabel: UILabel! // Make sure to connect this UILabel in your storyboard
    
    var player: AVPlayer!
    var avpController = AVPlayerViewController()
    var videoURL: URL!
    var timeElapsed: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let timeElapsed = timeElapsed {
            timeLabel.text = timeElapsed
        }
        
        startVideo()
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

}
