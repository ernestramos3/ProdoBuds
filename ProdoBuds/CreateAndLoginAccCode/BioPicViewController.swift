//
//  BioPicViewController.swift
//  ProdoBuds
//
//  Created by Ernest Ramos on 3/5/26.
//

import UIKit
import Photos

class BioPicViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    
    var selectedImage: UIImage?
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setProfileImageView()

        // Do any additional setup after loading the view.
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imageView.addGestureRecognizer(tap)
        imageView.isUserInteractionEnabled = true
    }
    
    func setProfileImageView(){
        imageView.image = UIImage(named: "Default_pfp")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        imageView.layer.cornerRadius = imageView.frame.width / 2
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imageView.addGestureRecognizer(tapGesture)
        
        
    }
    
    
    // permits the user to access the interace to select an image
    @objc func selectImage() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized:
            openPhotoLibrary()
        case .limited:
            openPhotoLibrary()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    switch newStatus {
                    case .authorized, .limited:
                        self.openPhotoLibrary()
                    case .denied, .restricted:
                        self.showPhotoAccessDeniedAlert()
                    default:
                        break
                    }
                }
            }
            
        case .denied, .restricted:
            showPhotoAccessDeniedAlert()
            
        @unknown default:
            break
        }
    }
    
    // opens the photo library
    func openPhotoLibrary() {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = .photoLibrary
        controller.allowsEditing = false
        
        present(controller, animated: true, completion: nil)
    }
    
    // alert for when they seny access
    func showPhotoAccessDeniedAlert() {
        let alert = UIAlertController(
            title: "Photos Access Needed",
            message: "Please allow access to your photo library in Settings so you can choose a profile picture.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }
    
    //if a user didnt select anuy image
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // user finished and picked a photo
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
            selectedImage = image
            SignupData.shared.profileImage  = selectedImage
        }
        picker.dismiss(animated: true, completion: nil)
    }
    

    // need to find a way to insert a bio picture and save it tot he shared instance of the thing
    @IBAction func cancelButtonPressed(_ sender: Any) {
        let controller = UIAlertController(
            title: "Do you want to stop creating this Account?",
            message: "All progress will be lost",
            preferredStyle: .alert)
        let no = UIAlertAction(title: "No", style: .default){ _ in return}
        let yes = UIAlertAction(title: "Yes", style: .cancel){ _ in
            SignupData.shared.reset()
            self.performSegue(withIdentifier: "cancel2", sender: self)
            }
        
        controller.addAction(yes)
        controller.addAction(no)
        present(controller, animated: true)
        
    }
    
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        if SignupData.shared.profileImage == nil {
            SignupData.shared.profileImage = UIImage(named: "Default_pfp")
        }
        
        self.performSegue(withIdentifier: "bioPicIdentifier", sender: self)
        
        
    }
    
    
    @IBAction func skipButtonPressed(_ sender: Any) {
        if SignupData.shared.profileImage == nil {
            SignupData.shared.profileImage = UIImage(named: "Default_pfp")
        }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
