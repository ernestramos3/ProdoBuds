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

    /// Mirrors Firestore `users/{uid}` — kept in sync with profile fetch and settings screens.
    var accountIsPrivate: Bool = false
    var blockedUsernames: [String] = []
    var showLikesOnPosts: Bool = true
    var showCommentsOnPosts: Bool = true

    /// Applies optional profile fields from Firestore into an existing session user (settings + core lists).
    static func mergingFirestoreProfile(_ data: [String: Any], into user: AppUser) -> AppUser {
        var u = user
        if let v = data["accountIsPrivate"] as? Bool { u.accountIsPrivate = v }
        if let v = data["blockedUsers"] as? [String] { u.blockedUsernames = v }
        if let v = data["showLikesOnPosts"] as? Bool { u.showLikesOnPosts = v }
        if let v = data["showCommentsOnPosts"] as? Bool { u.showCommentsOnPosts = v }
        return u
    }
}

class UserSession {
    static let shared = UserSession()
    
    var currentUser: AppUser?
    
    private init() { }
}

