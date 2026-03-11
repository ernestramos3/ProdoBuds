//
//  BioPicViewController.swift
//  ProdoBuds
//
//  Created by Ernest Ramos on 3/5/26.
//

import UIKit

class BioPicViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
