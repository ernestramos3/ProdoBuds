//
//  PreferencesViewController.swift
//  ProdoBuds
//
//  Created by Ernest Ramos on 3/5/26.
//

import UIKit

class PreferencesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!
    
    let prefs = [
        "Sports", "Music", "Games",
        "Cleaning", "Studying", "Food",
        "Gym", "Reading", "Travel"
    ]
    
    var selected: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return prefs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreferenceCell", for: indexPath)as! PreferenceCell
        
        let option = prefs[indexPath.row]
        cell.prefLabel.text = option
        
        if selected.contains(option){
            cell.backgroundColor = .systemGray
        }
        else{
            cell.backgroundColor = .systemGreen
        }
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let option = prefs[indexPath.row]
        
        if selected.contains(option) {
            selected.removeAll { $0 == option }
        }
        else {
            if selected.count < 3 {
                selected.append(option)
            }
            else {
                let alert = UIAlertController(
                    title: "Limit Reached",
                    message: "You can only select 3 preferences.",
                    preferredStyle: .alert
                )
                
                let ok = UIAlertAction(title: "OK", style: .default)
                alert.addAction(ok)
                present(alert, animated: true)
                return
            }
        }
        
        collectionView.reloadData()
    }
    
    // aesthetics for the grid
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 12
        let totalPadding = padding * 4
        let width = (collectionView.frame.width - totalPadding) / 3
        
        return CGSize(width: width, height: 45)
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        if selected.count == 0 {
            let alert = UIAlertController(
                title: "Select Preferences",
                message: "Please choose at least one preference.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // save preferences
        SignupData.shared.preferences = selected
        // move to next screen
        performSegue(withIdentifier: "PrefSegue", sender: self)
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        let controller = UIAlertController(
            title: "Do you want to stop creating this Account?",
            message: "All progress will be lost",
            preferredStyle: .alert)
        let no = UIAlertAction(title: "No", style: .default){ _ in return}
        let yes = UIAlertAction(title: "Yes", style: .cancel){ _ in
            SignupData.shared.reset()
            self.performSegue(withIdentifier: "cancel3", sender: self)
            }
        
        controller.addAction(yes)
        controller.addAction(no)
        present(controller, animated: true)
    }

}

class PreferenceCell: UICollectionViewCell {
    @IBOutlet weak var prefLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 10
    }
}
