//
//  Account.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import CodableFirebase

class Firebase {
    
    // MARK: Shared Instance
    static let shared = Firebase()
    
    // MARK: Properties
    public var isSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    private(set) var currentUser: CurrentUser?
    
    // MARK: Classes
    /// This class contains sensitive user data
    struct CurrentUser: Codable {
        let email: String
        
        private(set) var profile: UserProfile
        
        // MARK: Initialiser
        init(email: String, profile: UserProfile) {
            self.email = email
            self.profile = profile
        }
        
        struct Firestore: Codable {
            let email: String
        }
        
        func firestore() -> CurrentUser.Firestore {
            return CurrentUser.Firestore(email: self.email)
        }
    }
    
    /// This class contains publically viewable user data
    class UserProfile: Codable {
        // MARK: Properties
        let identifier: String
        let name: String
        let username: String
        let imageURL: URL?
        
        private(set) var musicServices: [StreamingPlatform]
        let showcase: Music.Showcase
                        
        private(set) var friends: [FriendProfile]?
        
        private(set) var vibes: [VibeManager.Vibe]
        
        private(set) var vibeIdentifier: String? {
            didSet {
                if self.vibeIdentifier != nil {
                    self.getCurrentVibe()
                }
            }
        }
        private(set) var currentVibe: VibeManager.Vibe?
        
        // MARK: Initialiser
        init(name: String, username: String, userIdentifier: String, email: String, friends: [FriendProfile]? = nil, musicServices: [StreamingPlatform] = []) {
            self.name = name
            self.username = username
            self.identifier = userIdentifier
            self.friends = friends
            self.musicServices = musicServices
            self.imageURL = nil
            self.vibeIdentifier = nil
            self.currentVibe = nil
            self.showcase = Music.Showcase(playlists: [], albums: [])
            
            self.getAllVibes()
        }
        
        // MARK: Data Methods
        public func getFriends(completion: ((Result<[FriendProfile], AccountError>) -> Void)? = nil) {
            Firebase.shared.getFriends(for: self.identifier) { (fetchedFriends) in
                if let friends = fetchedFriends {
                    completion?(.success(friends))
                } else {
                    completion?(.failure(.firestoreError))
                }
            }
        }
        
        public func getAllVibes(completion: ((Result<[VibeManager.Vibe], AccountError>) -> Void)? = nil) {
//            guard let vibeIdentifier = self.vibeIdentifier else { return }
            Firebase.shared.getVibe
        }
        
        // MARK: Methods
        public func addMusicPlatform(_ platform: StreamingPlatform) {
            self.musicServices.append(platform)
        }
        
        public func addFriend(_ friend: FriendProfile) {
            self.friends?.append(friend)
        }
        
        public func removeFriend(_ friend: FriendProfile) {
            self.friends?.removeAll(where: {$0.userProfile.username == friend.userProfile.username})
        }
        
    }
    
    // MARK: Structs
    struct FriendProfile: Codable {
        let userProfile: UserProfile
        let friendship: Friendship
    }
    
    enum Friendship: Int, Codable {
        case notFriends = 0
        case followsYou = 1
        case youFollow = 2
        case friends = 3
    }
    
    // MARK: Enums
    enum AccountError: Error {
        case passwordTooShort
        case passwordTooLong
        case passwordWeak
        case usernameTaken
        case accountExists
        case authError
        case accountCreationError
        case firestoreError
        case unknown
    }
    
    enum Resource: Int, Codable {
        case song
        case album
        case playlist
    }
    
    // MARK: Firestore Methods
    public func createUser(name: String, username: String, email: String, password: String, completion: @escaping(Result<CurrentUser, AccountError>) -> Void) {
        self.createAuthUser(email: email, password: password) { (authResult) in
            switch authResult {
            case .success(let userID):
                let userProfile = UserProfile(name: name, username: username, userIdentifier: userID, email: email)
                let currentUser = CurrentUser(email: email, profile: userProfile)
                
                self.createFirestoreUser(currentUser) { (result) in
                    switch result {
                    case .success(let user):
                        self.currentUser = user
                        completion(.success(user))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                print("[Account] Failed to create auth user. \(error)")
                completion(.failure(error))
            }
        }
    }
    
    private func createAuthUser(email: String, password: String, completion: @escaping(Result<String, AccountError>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("[Account] Failed to create account: \(error.localizedDescription)")
                completion(.failure(.accountCreationError))
            } else if let result = result {
                let userID = result.user.uid
                
                completion(.success(userID))
            } else {
                completion(.failure(.authError))
            }
        }
    }
    
    private func createFirestoreUser(_ user: CurrentUser, completion: @escaping(Result<CurrentUser, AccountError>) -> Void) {
        // Setup batch write request
        let batchWrite = Firestore.firestore().batch()
        
        // Encode Profiles
        let encodedPublicProfile = try! FirestoreEncoder().encode(user.profile)
        let encodedPrivateProfile = try! FirestoreEncoder().encode(user.firestore())
        
        // Firestore public profile
        let publicProfileDocument = Firestore.firestore().collection("Users").document(user.profile.identifier)
        batchWrite.setData(encodedPublicProfile, forDocument: publicProfileDocument)
        
        // Firestore private profile
        let privateProfileDocument = Firestore.firestore().collection("Users").document(user.profile.identifier).collection("Private").document(user.profile.identifier)
        batchWrite.setData(encodedPrivateProfile, forDocument: privateProfileDocument)
        
        batchWrite.commit { (error) in
            if let error = error {
                completion(.failure(.accountCreationError))
            } else {
                completion(.success(user))
            }
        }
    }
    
    public func findUsers(matching username: String, limit: Int = 25, completion: @escaping([Firebase.UserProfile]) -> Void) {
        Firestore.firestore().collection("Users").order(by: "username").whereField("username", isGreaterThan: username).whereField("username", isLessThanOrEqualTo: "\(username)z").limit(to: limit).getDocuments { (snapshot, error) in
            if let error = error {
                print("[Account] Error finding users: \(error.localizedDescription)")
                completion([])
            } else if let documents = snapshot?.documents, !documents.isEmpty {
                let matchingUsers = documents.compactMap({try! FirestoreDecoder().decode(UserProfile.self, from: $0.data())})
                
                completion(matchingUsers)
            } else {
                completion([])
            }
        }
    }
    
    public func getFriends(for userIdentifier: String, completion: @escaping([Firebase.FriendProfile]?) -> Void) {
        Firestore.firestore().collection("Users").document(userIdentifier).getDocument() { (snapshot, error) in
            if let error = error {
                print("[Account] Error finding friend: \(error.localizedDescription)")
                completion(nil)
            } else if let snapshot = snapshot, let data = snapshot.data(), snapshot.exists {
                let friends = try! FirestoreDecoder().decode([FriendProfile].self, from: data)
                completion(friends)
            } else {
                completion(nil)
            }
        }
    }
    
    public func getProfile(for userIdentifier: String, completion: @escaping(Firebase.UserProfile?) -> Void) {
        Firestore.firestore().collection("Users").document(userIdentifier).getDocument { (snapshot, error) in
            if let error = error {
                print("[Account] Error finding profile for user \(userIdentifier): \(error.localizedDescription)")
                completion(nil)
            } else if let snapshot = snapshot {
                guard let data = snapshot.data() else { completion(nil); return }
                let profile = try! FirestoreDecoder().decode(UserProfile.self, from: data)
                
                completion(profile)
            } else {
                completion(nil)
            }
        }
    }
    
    public func getCurrentVibe(vibeIdentifier: String, completion: @escaping(VibeManager.Vibe?) -> Void) {
        Firestore.firestore().collection("Vibes").document(vibeIdentifier).getDocument { (snapshot, error) in
            if let error = error {
                print("[Account] Error finding vibe \(vibeIdentifier): \(error.localizedDescription)")
                completion(nil)
            } else if let snapshot = snapshot, let data = snapshot.data() {
                guard let data = snapshot.data() else { completion(nil); return }
                let vibe = try! FirestoreDecoder().decode(VibeManager.Vibe.self, from: data)
                
                completion(vibe)
            } else {
                completion(nil)
            }
        }
    }
    
    public func getAllVibes(for userIdentifier: String, completion: @escaping([VibeManager.Vibe]) -> Void) {
//        Firestore.firestore().collection("Vibes").
    }
    
    private func fetchCurrentUser(completion: @escaping(Result<CurrentUser?, Error>) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { fatalError() }
        Firestore.firestore().collection("Users").document(currentUserID).getDocument { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                guard let data = snapshot.data() else { completion(.success(nil)); return }
                let userProfile = try! FirestoreDecoder().decode(CurrentUser.self, from: data)
                
                completion(.success(userProfile))
            } else {
                completion(.success(nil))
            }
        }
    }
    
    // MARK: User Profile Methods
    public func getCurrentUserProfile(completion: @escaping(CurrentUser?) -> Void) {
        if self.currentUser == nil {
            self.fetchCurrentUser { (result) in
                switch result {
                case .success(let userProfile):
                    completion(userProfile)
                case .failure(_):
                    completion(nil)
                }
            }
        } else {
            completion(self.currentUser)
        }
    }
    
    public func updateUserProfile(with profile: CurrentUser) {
        // TODO
        self.currentUser = profile
    }
    
    public func addFriend(with username: String) {
        // TODO
    }
    
    public func removeFriend(with username: String) {
        // TODO
    }
    
    // MARK: Vibe Methods
    func fetchVibe(with identifier: String) {
        
    }
    
    func fetchVibe(for username: String) {
        
    }
    
    func startVibe(_ vibe: VibeManager.Vibe, completion: @escaping(Bool) -> Void) {
        guard let encodedVibe = try? FirestoreEncoder().encode(vibe) else { completion(false); return }
        Firestore.firestore().collection("Vibes").document(vibe.details.identifier).setData(encodedVibe) { (error) in
            if let error = error {
                print("[Firebase] Error starting vibe: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func pauseVibe() {
        
    }
    
    func stopVibe() {
        
    }
    
}


// MARK: CodableFirebase Requirements
extension DocumentReference: DocumentReferenceType {}
extension GeoPoint: GeoPointType {}
extension FieldValue: FieldValueType {}
extension Timestamp: TimestampType {}
