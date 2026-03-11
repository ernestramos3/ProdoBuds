//
//  ViewController.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/7/26.
//

import UIKit
import SwiftUI

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func showSwiftUIView(_ sender: Any) {
        
        let view = ContentView()
        let hostingController = UIHostingController(rootView: view)
        hostingController.modalPresentationStyle = .fullScreen
        
        present(hostingController, animated: true, completion: nil)
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
