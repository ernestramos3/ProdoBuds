//
//  Post.swift
//  ProdoBuds
//
//  Created by Trinh, Andy on 4/1/26.
//

import FirebaseFirestore

class Post {
    var user:String
    var description:String
    var likes:[String] // list of usernames that like posts
    var taggedUsers:[String]
    var videoLink:String
    var timestamp:Timestamp?
    
    //var comments:Dictionary<String, [String]>
    
    // maybe?
    // var thumbnail:String (url?)
    
    init(dictionary: [String: Any]) {
        self.user = dictionary["user"] as? String ?? ""
        self.description = dictionary["description"] as? String ?? ""
        self.likes = dictionary["likes"] as? [String] ?? []
        self.taggedUsers = dictionary["tagged_users"] as? [String] ?? []
        self.videoLink = dictionary["videoURL"] as? String ?? ""
        self.timestamp = dictionary["timestamp"] as? Timestamp
        //self.comments = [:]
    }
    
    // when the "heart" symbol is clicked on
    func changeLikes(username:String) {
        // if username is already in list of likes, this means post will be unliked
        if let index = self.likes.firstIndex(of: username) {
            self.likes.remove(at: index)
        }
        // else username isn't in the list of likes, meaning post will be liked
        else {
            self.likes.append(username)
        }
    }
    
    // returns username
    func getUser() -> String {
        return self.user
    }
    
    // returns description
    func getDescription() -> String {
        return self.description
    }
    
    // for displaying purposes
    func getNumberOfLikes() -> Int {
        return self.likes.count
    }
    
    // returns URL
    func getVideoURL() -> String {
        return self.videoLink
    }
    
    // add new comment to post from username
    //func addComments(comment:String, username:String) {
        //self.comments[username, default: []].append(comment)
    //}
}
