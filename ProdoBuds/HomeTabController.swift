//
//  HomeTabController.swift
//  ProdoBuds
//
//  Created by Trinh, Andy on 3/11/26.
//

import UIKit

class HomeTabController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool{
        
        if let index = viewControllers?.firstIndex(of: viewController), index == 1{ return true}
        
        return true 
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
