// This file defines a UIViewControllerRepresentable wrapper for UploadVideoViewController.
// It enables presenting the UIKit video preview from SwiftUI sheets.

import SwiftUI

struct UploadVideoControllerWrapper: UIViewControllerRepresentable {
    let videoURL: URL
    let timeElapsed: String
    
    func makeUIViewController(context: Context) -> UploadVideoViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "UploadVideoViewController") as! UploadVideoViewController
        vc.videoURL = videoURL
        vc.timeElapsed = timeElapsed
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UploadVideoViewController, context: Context) {
        // No dynamic updates required.
    }
}
