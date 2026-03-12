//
//  ViewController.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/5/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

class ViewController: UIViewController {

    @IBOutlet weak var errorMsg: UILabel!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var email: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBAction func loginPressed(_ sender: Any) {
        guard let e = email.text,
              let passcode = password.text else { return }
        
        // ensuring that the fields arent empty
        if e.isEmpty || passcode.isEmpty {
            errorMsg.text = "One of the fields is empty"
            return
        }
        
        // ensuring that the account exist
        Auth.auth().signIn(withEmail: e, password: passcode) { authResult, error in
            if let error = error {
                self.errorMsg.text = "Error: \(error.localizedDescription)"
                return
            }
            
            // building shared instance of AppUser so all viewcontrollers can access the current user's data easily
            guard let currUser = authResult?.user else {
                self.errorMsg.text = "Could not log in user."
                return
            }
            let db = Firestore.firestore()
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
                    profileImageURL: currUserData["profileImageURL"] as? String ?? ""
                )
                // this is how you can access ^ those fields
                UserSession.shared.currentUser = appUser
                
                // success welcome to the prodobuds
                self.errorMsg.text = ""
                self.password.text = ""
                self.email.text = ""
                let storyboard = UIStoryboard(name: "HomeScreen", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "HomeScreenStoryboardID")
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
        }
    }
}


