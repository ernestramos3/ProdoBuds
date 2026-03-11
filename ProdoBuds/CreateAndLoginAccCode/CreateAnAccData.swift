//
//  CreateAnAccData.swift
//  ProdoBuds
//
//  Created by Ernest Ramos on 3/9/26.
//

// this class is used to easily access the user inputs when theya re making an account

import Foundation

class SignupData {
    static let shared = SignupData()
    
    var email: String = ""
    var password: String = ""
    var username: String = ""
    var bio: String = ""
    var preferences: [String] = []
    var profileImageURL: String = ""
    
    public init() { }
    
    func reset() {
        email = ""
        password = ""
        username = ""
        bio = ""
        preferences = []
        profileImageURL = ""
    }
}
