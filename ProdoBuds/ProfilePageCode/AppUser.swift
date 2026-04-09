//
//  AppUser.swift
//  ProdoBuds
//
//  Created by Ernest Ramos on 3/9/26.
//
// used so the current user data can be easily access throughout all viewcontrollers and we dont need to pass basic data through the segue

import Foundation

struct AppUser {
    let uid: String
    let username: String
    let bio: String
    let preferences: [String]
    let profileImageURL: String
    var followers: [String]
    var following: [String]
}

class UserSession {
    static let shared = UserSession()
    
    var currentUser: AppUser?
    
    private init() { }
}

