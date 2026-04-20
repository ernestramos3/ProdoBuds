// This file defines a UIViewControllerRepresentable wrapper for UploadVideoViewController.
// It enables presenting the UIKit video preview from SwiftUI sheets.

import SwiftUI

struct UploadVideoControllerWrapper: UIViewControllerRepresentable {
    let videoURL: URL?
    
    func makeUIViewController(context: Context) -> UploadVideoViewController {
        print("UploadVideoControllerWrapper: makeUIViewController called")
        let storyboard = UIStoryboard(name: "CameraAndUpload", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "UploadVideoViewControllerID") as! UploadVideoViewController
        vc.videoURL = videoURL
        // Ensure full-screen presentation when shown from SwiftUI
        vc.modalPresentationStyle = .fullScreen
        
        // Prevent SwiftUI from adding additional safe area insets
        vc.additionalSafeAreaInsets = .zero
        
        // Force light mode appearance
        vc.overrideUserInterfaceStyle = .light
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UploadVideoViewController, context: Context) {
        // No dynamic updates required.
    }
}

