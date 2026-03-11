//
//  NameViewController.swift
//  ProdoBuds
//
//  Created by Ernest Ramos on 3/5/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore


class NameViewController: UIViewController {

    @IBOutlet weak var errorMsg: UILabel!
    @IBOutlet weak var username: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        guard let name = username.text else { return }
        
        // ensures that the name has something
        if(name.isEmpty){
            errorMsg.text = "Error: Must input a username"
            return
        }
        
        // ensures the correct size for the username
        if(name.count < 5){
            errorMsg.text = "Error: Username must be more then 5 characters"
            return
        }
        if(name.count > 30){
            errorMsg.text = "Error: Username must be under 30 characters"
            return
        }
        SignupData.shared.username = name
        
        Auth.auth().createUser(withEmail: SignupData.shared.email, password: SignupData.shared.password) { result, error in
            if let error = error {
                print("Signup error: \(error.localizedDescription)")
                return
            }
            
            // acc was succesfully made now need to enter it in the data base
            guard let user = result?.user else { return }
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "username": SignupData.shared.username,
                "bio": SignupData.shared.bio,
                "preferences": SignupData.shared.preferences,
                "email": SignupData.shared.email,
                "image": SignupData.shared.profileImageURL
            ]){ error in
                if let error = error {
                    print("Firestore error: \(error.localizedDescription)")
                } else {
                    // success reset th signupData shared instance
                    print("User saved")
                    SignupData.shared.reset()
                    self.performSegue(withIdentifier: "FinishedCreateAccIdentifier", sender: self)
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
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
