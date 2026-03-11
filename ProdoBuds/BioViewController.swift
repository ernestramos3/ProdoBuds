//
//  BioViewController.swift
//  ProdoBuds
//
//  Created by Ernest Ramos on 3/10/26.
//

import UIKit

class BioViewController: UIViewController {
    
    @IBOutlet weak var bio: UITextField!
    @IBOutlet weak var errorMsg: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        guard let bioStr = bio.text else { return }
        
        // ensure thar it is not emoty and not above 150 characters
        if(bioStr.count == 0){
            errorMsg.text = "Error: Must include a bio"
        }
        if(bioStr.count > 150){
            errorMsg.text = "Error: Bio must be under 150 characters"
        }
        
        errorMsg.text = ""
        SignupData.shared.bio = bioStr
        self.performSegue(withIdentifier: "bioSegue", sender: self)
    }
    
    
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        let controller = UIAlertController(
            title: "Do you want to stop creating this Account?",
            message: "All progress will be lost",
            preferredStyle: .alert)
        let no = UIAlertAction(title: "No", style: .default){ _ in return}
        let yes = UIAlertAction(title: "Yes", style: .cancel){ _ in
            SignupData.shared.reset()
            self.errorMsg.text = ""
            self.performSegue(withIdentifier: "cancel4", sender: self)
            }
        
        controller.addAction(yes)
        controller.addAction(no)
        present(controller, animated: true)

    }

}
