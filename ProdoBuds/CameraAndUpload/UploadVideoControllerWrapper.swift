// This file defines a UIViewControllerRepresentable wrapper for UploadVideoViewController.
// It enables presenting the UIKit video preview from SwiftUI sheets.

import SwiftUI

struct UploadVideoControllerWrapper: UIViewControllerRepresentable {
    let videoURL: URL?
    
    func makeUIViewController(context: Context) -> UploadVideoViewController {
        print("UploadVideoControllerWrapper: makeUIViewController called")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "UploadVideoViewControllerID") as! UploadVideoViewController
        vc.videoURL = videoURL
        // Ensure full-screen presentation when shown from SwiftUI
        vc.modalPresentationStyle = .fullScreen
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UploadVideoViewController, context: Context) {
        // No dynamic updates required.
    }
}

