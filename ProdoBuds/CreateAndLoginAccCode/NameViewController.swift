//
//  NameViewController.swift
//  ProdoBuds
//
//  Created by Ernest Ramos on 3/5/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage


class NameViewController: UIViewController, UITextFieldDelegate{

    @IBOutlet weak var errorMsg: UILabel!
    @IBOutlet weak var username: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        username.delegate = self
    }
    
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        guard let name = username.text else { return }
        if name.isEmpty {
            errorMsg.text = "Error: Must input a username"
            return
        }
        if name.count < 5 {
            errorMsg.text = "Error: Username must be more then 5 characters"
            return
        }
        if name.count > 30 {
            errorMsg.text = "Error: Username must be under 30 characters"
            return
        }
        
        SignupData.shared.username = name
        Auth.auth().createUser(withEmail: SignupData.shared.email, password: SignupData.shared.password) { result, error in
            if let error = error {
                print("Signup error: \(error.localizedDescription)")
                return
            }
            guard let user = result?.user else { return }
            // first make sure there is an image
            guard let image = SignupData.shared.profileImage,
                  let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("No profile image found")
                return
            }
            // upload image to Firebase Storage
            let storageRef = Storage.storage().reference()
            let imageRef = storageRef.child("profile_images/\(user.uid).jpg")
            imageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Image upload error: \(error.localizedDescription)")
                    return
                }
                
                // get the download URL
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("Download URL error: \(error.localizedDescription)")
                        return
                    }
                    guard let downloadURL = url else { return }
                    
                    // saves everything to the firestore
                    let db = Firestore.firestore()
                    db.collection("users").document(user.uid).setData([
                        "username": SignupData.shared.username,
                        "bio": SignupData.shared.bio,
                        "preferences": SignupData.shared.preferences,
                        "email": SignupData.shared.email,
                        "profileImageURL": downloadURL.absoluteString,
                        "following": [String](),
                        "followers": [String]()
                    ]) { error in
                        if let error = error {
                            print("Firestore error: \(error.localizedDescription)")
                        } else {
                            print("User saved")
                            SignupData.shared.reset()
                            self.performSegue(withIdentifier: "FinishedCreateAccIdentifier", sender: self)
                        }
                    }
                    
                    // grabs the user and logs them in
                    guard let currUser = Auth.auth().currentUser else {
                        self.errorMsg.text = "Could not log in user."
                        return
                    }
                    
                    // building shared instance of AppUser so all viewcontrollers can access the current user's data easily
                    db.collection("users").document(currUser.uid).getDocument { snapshot, error in
                        if let error = error {
                            self.errorMsg.text = error.localizedDescription
                            return
                        }
                        guard let currUserData = snapshot?.data() else {
                            self.errorMsg.text = "User data not found."
                            return
                        }
                        let appUser = AppUser(
                            uid: currUser.uid,
                            username: currUserData["username"] as? String ?? "",
                            bio: currUserData["bio"] as? String ?? "",
                            preferences: currUserData["preferences"] as? [String] ?? [],
                            profileImageURL: currUserData["profileImageURL"] as? String ?? "",
                            followers: currUserData["followers"] as? [String] ?? [],
                            following: currUserData["following"] as? [String] ?? []
                        )
                        // this is how you can access ^ those fields
                        UserSession.shared.currentUser = appUser
                        
                        // changes to the fyp
                        let storyboard = UIStoryboard(name: "HomeScreen", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "HomeScreenStoryboardID")
                        vc.modalPresentationStyle = .fullScreen
                        self.present(vc, animated: true)
                    }
                }
            }
        }
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        let controller = UIAlertController(
            title: "Do you want to stop creating this Account?",
            message: "All progress will be lost",
            preferredStyle: .alert)
        let no = UIAlertAction(title: "No", style: .default){ _ in return}
        let yes = UIAlertAction(title: "Yes", style: .cancel){ _ in
            SignupData.shared.reset()
            self.performSegue(withIdentifier: "FinishedCreateAccIdentifier", sender: self)
            }
        
        controller.addAction(yes)
        controller.addAction(no)
        present(controller, animated: true)
    }
    
    
    
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Called when the user clicks on the view outside of the UITextField

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
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
