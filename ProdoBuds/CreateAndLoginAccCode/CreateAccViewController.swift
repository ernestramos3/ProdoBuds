//
//  CreateAccViewController.swift
//  ProdoBuds
//
//  Created by Ernest Ramos on 3/5/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CreateAccViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var errorMsg: UILabel!
    @IBOutlet weak var passwordRetyped: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var email: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordRetyped.delegate = self
        password.delegate = self
        email.delegate = self

        // Do any additional setup after loading the view.
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        // saves all the fields
        guard let passcode = password.text,
              let passcodeRe = passwordRetyped.text,
              let e = email.text else { return }
        
        // ensures that none of the fields are empty
        if passcode.isEmpty || passcodeRe.isEmpty || e.isEmpty {
            errorMsg.text = "One of the fields is empty"
            return
        }
        
        // ensures that the passwords match
        if passcode != passcodeRe {
            errorMsg.text = "Passwords do not match"
            return
        }
        
        SignupData.shared.email = e
        SignupData.shared.password = passcode
        self.errorMsg.text = ""
        self.performSegue(withIdentifier: "CreateAccIdentifier", sender: self)
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        let controller = UIAlertController(
            title: "Do you want to stop creating this Account?",
            message: "All progress will be lost",
            preferredStyle: .alert)
        let no = UIAlertAction(title: "No", style: .default){ _ in return}
        let yes = UIAlertAction(title: "Yes", style: .cancel){ _ in
            self.errorMsg.text = ""
            self.password.text = ""
            self.passwordRetyped.text = ""
            SignupData.shared.reset()
            self.performSegue(withIdentifier: "cancel1", sender: self)
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
