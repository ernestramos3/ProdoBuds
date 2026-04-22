//
//  UploadVideoViewController.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/10/26.
//

import UIKit
import AVFoundation
import AVKit
import Photos
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

func generateRandomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map { _ in letters.randomElement()! })
}

class UploadVideoViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var captionField: UITextField!
    @IBOutlet weak var timeLabel: UILabel! // Make sure to connect this UILabel in your storyboard
    @IBOutlet weak var fpsLabel: UILabel!
    
    var player: AVPlayer!
    var avpController = AVPlayerViewController()
    var videoURL: URL!
    var selectedFPS: Int32 = 5 // Default to 5 fps
    
    var privacy: String = "public"
    var taggedUsersString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Ensure proper background color (especially important for SwiftUI transitions)
        view.backgroundColor = UIColor(named: "Cream Color")
        
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
        
        // Update labels with video info
        updateVideoInfoLabels()
    }
    
    private func updateVideoInfoLabels() {
        guard let url = videoURL else { return }
        
        let asset = AVURLAsset(url: url)
        
        // Get video duration
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        
        // Format duration as MM:SS
        let minutes = Int(durationInSeconds) / 60
        let seconds = Int(durationInSeconds) % 60
        let durationString = String(format: "%02d:%02d", minutes, seconds)
        
        // Update time label
        timeLabel.text = durationString
        
        // Update FPS label
        fpsLabel.text = "\(selectedFPS) FPS"
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

    @IBAction func uploadVideo(_ sender: Any) {
        Task {
            await performUpload()
        }
    }
    
    private func performUpload() async {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let randomString = generateRandomString(length: 10)
        let videoRef = storageRef.child("videos/\(randomString)")
        let thumbnailRef = storageRef.child("thumbnails/\(randomString)")
        
        let videoMetadata = StorageMetadata()
        videoMetadata.contentType = "video/quicktime"
        
        // get comma-separated users and convert to array
        let taggedUsers: [String] = taggedUsersString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.hasPrefix("@") ? String($0.dropFirst()) : $0 }
            .filter { !$0.isEmpty }
        
        do {
            // Upload video
            let _ = try await videoRef.putFileAsync(from: videoURL, metadata: videoMetadata)
            
            // Get download URL
            let downloadURL = try await videoRef.downloadURL()
            
            // Generate and upload thumbnail
            let thumbnailURL = try await generateAndUploadThumbnail(
                videoURL: videoURL,
                thumbnailRef: thumbnailRef
            )
            
            // Create Firestore document
            let db = Firestore.firestore()
            try await db.collection("posts").addDocument(data: [
                "id" : db.collection("posts").document().documentID,
                "description": captionField.text ?? "",
                "likes": [],
                "tagged_users": taggedUsers,
                "user": UserSession.shared.currentUser?.username ?? "",
                "videoURL": downloadURL.absoluteString,
                "thumbnailURL": thumbnailURL,
                "privacy": privacy,
                "timestamp": FieldValue.serverTimestamp()
            ])
            
            print("Upload successful!")
            
            // Delete the local video file after successful upload
            deleteLocalVideo()
            
            // Navigate to home screen
            await MainActor.run {
                let storyboard = UIStoryboard(name: "HomeScreen", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "HomeScreenStoryboardID")
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
            
        } catch {
            print("Upload failed: \(error.localizedDescription)")
            // Show error to user
            await MainActor.run {
                let controller = UIAlertController(
                    title: "Upload Failed",
                    message: "There was an error uploading your video. Please try again.",
                    preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(controller, animated: true)
            }
        }
    }
    
    private func generateAndUploadThumbnail(videoURL: URL, thumbnailRef: StorageReference) async throws -> String {
        // Generate thumbnail from first frame
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Request image at time zero (first frame)
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        
        // Use the newer async API
        let cgImage: CGImage = try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImageAsynchronously(for: time) { image, actualTime, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: NSError(domain: "UploadVideoViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate thumbnail image"]))
                }
            }
        }
        
        let thumbnail = UIImage(cgImage: cgImage)
        
        // Convert to JPEG data
        guard let imageData = thumbnail.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "UploadVideoViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert thumbnail to JPEG"])
        }
        
        // Upload thumbnail
        let thumbnailMetadata = StorageMetadata()
        thumbnailMetadata.contentType = "image/jpeg"
        
        let _ = try await thumbnailRef.putDataAsync(imageData, metadata: thumbnailMetadata)
        
        // Get download URL
        let thumbnailURL = try await thumbnailRef.downloadURL()
        return thumbnailURL.absoluteString
    }
    
    private func deleteLocalVideo() {
        guard let url = videoURL else {
            print("No video URL to delete")
            return
        }
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                print("Local video file deleted successfully: \(url.path)")
            } else {
                print("Video file doesn't exist at path: \(url.path)")
            }
        } catch {
            print("Failed to delete local video file: \(error.localizedDescription)")
        }
    }
    
    @IBAction func draftVideo(_ sender: Any) {
        // Save video to Photos library when drafting
        if let url = videoURL {
            Task {
                await saveDraftToPhotosLibrary(url: url)
                
                // Navigate to home screen
                await MainActor.run {
                    let storyboard = UIStoryboard(name: "HomeScreen", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "HomeScreenStoryboardID")
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                }
            }
        } else {
            // Navigate to home screen even if no video URL
            let storyboard = UIStoryboard(name: "HomeScreen", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "HomeScreenStoryboardID")
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }
    }
    
    private func saveDraftToPhotosLibrary(url: URL) async {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        var authorized = status == .authorized
        
        if status == .notDetermined {
            authorized = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
        }
        
        guard authorized else {
            print("Photo library access denied")
            return
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
            print("Draft video saved to Photos library successfully")
        } catch {
            print("Failed to save draft video to Photos library: \(error.localizedDescription)")
        }
    }
    
    @IBAction func selectMusic(_ sender: Any) {
        makePopup(popupMessage: "Music has not been added yet.")
    }
    
    @IBAction func selectPrivacy(_ sender: Any) {
        let controller = UIAlertController(title: "Privacy", message: "Who can see this video:", preferredStyle: .actionSheet)
        
        let publicAction = UIAlertAction(title: "Public", style: .default) { _ in
            self.privacy = "public"
        }
        
        let friendsAction = UIAlertAction(title: "Friends Only", style: .default) { _ in
            self.privacy = "friends"
        }
        
        let privateAction = UIAlertAction(title: "Private", style: .default) { _ in
            self.privacy = "private"
        }
        
        controller.addAction(publicAction)
        controller.addAction(friendsAction)
        controller.addAction(privateAction)
        
        present(controller, animated: true)
    }
    
    @IBAction func selectMentions(_ sender: Any) {
        // work on adding tagged users
        let controller = UIAlertController(title: "Tags", message: "Add users:", preferredStyle: .alert)
        
        controller.addTextField { textField in
            textField.placeholder = "@orlando, @redial"
            textField.autocapitalizationType = .none
            textField.text = self.taggedUsersString
        }
        
        controller.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            let text = controller.textFields?.first?.text ?? ""
            self.taggedUsersString = text
            print("Entered: \(text)")
        })

        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(controller, animated: true)
    }
    
    @IBAction func selectVoiceover(_ sender: Any) {
        makePopup(popupMessage: "Voiceover has not been added yet.")
    }
    
    func makePopup(popupMessage:String) {
        let controller = UIAlertController(
                title: "Coming soon!",
                message: popupMessage,
                preferredStyle: .alert)
            
        controller.addAction(UIAlertAction(title: "OK", style: .default))
            
        present(controller,animated:true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        if view.frame.origin.y == 0 {
            view.frame.origin.y -= keyboardFrame.height
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }
}
