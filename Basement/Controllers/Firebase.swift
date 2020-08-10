//
//  Account.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import CodableFirebase

protocol SessionUpdateBroadcaster {
    
    func update(for sessionID: String, update: SessionManager.MusicSession)
    
}

class Firebase {
    
    // MARK: Shared Instance
    static let shared = Firebase()
    
    // MARK: Properties
    class var isSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    var currentUserIdentifier: String? {
        return Auth.auth().currentUser?.uid
    }
    
    private var currentUser: PrivateProfile? = nil
    var sessionListenerUpdateDelegate: SessionUpdateBroadcaster? = nil
    var documentListeners: [ListenerRegistration] = []
    
    // MARK: Firestore Collection References
    private let functionsReference = Functions.functions()
    private let usersCollection = Firestore.firestore().collection("Users")
    private let sessionsCollection = Firestore.firestore().collection("Sessions")
    private let userRelationshipsCollection = Firestore.firestore().collection("UserRelationships")
    
    private lazy var userDocument: DocumentReference? = {
        guard let userIdentifier = self.currentUserIdentifier else { return nil }
        
        return self.usersCollection.document(userIdentifier)
    }()
    
    private lazy var privateUserDocument: DocumentReference? = {
        guard let userIdentifier = self.currentUserIdentifier else { return nil }
        
        return self.userDocument?.collection("PrivateUser").document(userIdentifier)
    }()
    
    private lazy var currentSessionCollection: CollectionReference? = {
        return self.userDocument?.collection("Session")
    }()
    
    // MARK: Error
    enum FirebaseError: Error {
        case unknownError
        case noResponse
        
        case networkError
        case userNotFound
        case tooManyRequests
        case invalidAPIKey
        case credentialError
        case notAuthorised
        case keychainError
        case internalError
        
        case invalidEmailFormat
        case accountWithEmailExists
        case incorrectPassword
        case passwordTooWeak
        case userDisabled
        
        case authUserCreationFailure
        case firestoreUserCreationFailure
        case userFetchFailure(String)
        case friendFetchFailure(String)
        
        case usernameInUse
    }
    
    // MARK: Structs
    struct UserInformation: Codable, Equatable {
        // MARK: Properties
        let identifier: String
        let username: String
        let name: String
        
        // MARK: Initialiser
        init(identifier: String, username: String, name: String) {
            self.identifier = identifier
            self.username = username
            self.name = name
        }
        
        // MARK: Codable
        private enum CodingKeys: String, CodingKey {
            case identifier, username, name
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.identifier = try container.decode(String.self, forKey: .identifier)
            self.username = try container.decode(String.self, forKey: .username)
            self.name = try container.decode(String.self, forKey: .name)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(self.identifier, forKey: .identifier)
            try container.encode(self.username, forKey: .username)
            try container.encode(self.name, forKey: .name)
        }
    }
    
    class UserRelationship: Codable {
        // MARK: Properties
        let baseUser: UserInformation
        let relatedUser: UserInformation
        let relationship: Relationship
        
        // MARK: Enums
        enum Relationship: String, Codable, Equatable {
            case notFriends
            case followsMe
            case followsThem
            case friends
            case blocked
        }
        
        // MARK: Initialisers
        init(baseUser: UserInformation, relatedUser: UserInformation, relationship: Relationship) {
            self.baseUser = baseUser
            self.relatedUser = relatedUser
            self.relationship = relationship
        }
        
        // MARK: Codable
        private enum CodingKeys: String, CodingKey {
            case baseUser, relatedUser, relationship
        }
        
        // MARK: Decodable
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.baseUser = try container.decode(UserInformation.self, forKey: .baseUser)
            self.relatedUser = try container.decode(UserInformation.self, forKey: .relatedUser)
            self.relationship = try container.decode(Relationship.self, forKey: .relationship)
        }
        
        // MARK: Encodable
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(self.baseUser, forKey: .baseUser)
            try container.encode(self.relatedUser, forKey: .relatedUser)
            try container.encode(self.relationship, forKey: .relationship)
        }
    }
    
    class UserProfile: Codable {
        // MARK: Properties
        let information: UserInformation
        let friends: [UserRelationship]
        private(set) var streams: [SessionManager.MusicSession]
        
        // MARK: Initialiser
        init(information: UserInformation, friends: [UserRelationship]) {
            self.information = information
            self.friends = friends
            self.streams = []
            
            self.fetchSessions { (sessions) in
                self.streams = sessions
            }
        }
        
        func fetchSessions(completion: @escaping([SessionManager.MusicSession]) -> Void) {
            Firebase.shared.fetchUserSessions(for: self.information.identifier) { (result) in
                switch result {
                case .success(let sessions):
                    completion(sessions)
                case .failure(_):
                    completion([])
                }
            }
        }
        
        // MARK: Codable
        private enum CodingKeys: String, CodingKey {
            case information, friends, pastStreams
        }
        
        // MARK: Decodable
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.information = try container.decode(UserInformation.self, forKey: .information)
            self.friends = try container.decode([UserRelationship].self, forKey: .friends)
            self.streams = []
            
            self.fetchSessions { (sessions) in
                self.streams = sessions
            }
        }
        
        // MARK: Encodable
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(self.information, forKey: .information)
            try container.encode(self.friends, forKey: .friends)
        }
    }
    
    class PrivateProfile: Codable {
        // MARK: Properties
        let publicProfile: UserProfile
        let email: String
        
        // MARK: Initialisers
        init(profile: UserProfile, email: String) {
            self.publicProfile = profile
            self.email = email
        }
        
        // MARK: Methods
        func userIdentifier() -> String {
            return self.publicProfile.information.identifier
        }
        
        // MARK: Codable
        private enum CodingKeys: String, CodingKey {
            case user, email
        }
        
        // MARK: Decodable
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.publicProfile = try container.decode(UserProfile.self, forKey: .user)
            self.email = try container.decode(String.self, forKey: .email)
        }
        
        // MARK: Encodable
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(self.publicProfile, forKey: .user)
            try container.encode(self.email, forKey: .email)
        }
    }
    
    // MARK: - Functions
    struct AppleMusicToken: Codable {
        let authToken: String
    }
    
    struct UsernameAvailability: Decodable {
        let requestedUsername: String
        let isAvailable: Bool
    }
    
    public func fetchAppleMusicAuthToken(completion: @escaping(Result<String, FirebaseError>) -> Void) {
//        Functions.functions().httpsCallable("appleMusicAuthorizationToken").call { (result, error) in
//            if error != nil {
//                completion(.failure(.unknownError))
//            } else {
//                guard let jsonData = result?.data as? [String : Any],
//                      let token = jsonData["authToken"] as? String
//                else { completion(.failure(.unknownError)); return }
//
//                completion(.success(token))
//            }
//        }
        
        let tokenString = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IkdYRjI2UEFGQjUifQ.eyJpc3MiOiIzVjkzQTNBQ1Y5IiwiaWF0IjoxNTk2OTczNTY2LCJleHAiOjE1OTcwMTY3NjZ9.DENkyCP9gFn8RKh-ETGAFqPR5LTq8dAWMdhGkRPWA1tjsd4ldMIAPLzs9MPbdgUG48_QdzUbt2FjA2pfP31bVw"
        
        completion(.success(tokenString))
    }
    
    public func determineUsernameAvailability(_ username: String, completion: @escaping(Result<Bool, FirebaseError>) -> Void) {
        self.functionsReference.httpsCallable("usernameAvailability").call(["requestedUsername" : username]) { (result, error) in
            if error != nil {
                completion(.failure(.unknownError))
            } else {
                do {
                    guard let result = result,
                          let data = result.data as? [String : Any]
                    else { completion(.failure(.unknownError)); return }
                    
                    let response = try FirebaseDecoder().decode(UsernameAvailability.self, from: data)
                    
                    completion(.success(response.isAvailable))
                } catch {
                    completion(.failure(.unknownError))
                }
            }
        }
    }
    
    public func sendFriendRequest(from baseUser: UserInformation, to relatedUser: UserInformation, completion: @escaping(Result<UserRelationship, FirebaseError>) -> Void) {
        
        self.functionsReference.httpsCallable("sendFriendRequest").call(["baseUser" : baseUser.identifier, "relatedUser" : relatedUser.identifier]) { (result, error) in
            if error != nil {
                completion(.failure(.unknownError))
            } else {
                do {
                    guard let result = result,
                          let data = result.data as? [String : Any]
                    else { completion(.failure(.unknownError)); return }
                    
                    let decodedRelationship = try FirebaseDecoder().decode(UserRelationship.self, from: data)
                    
                    completion(.success(decodedRelationship))
                } catch {
                    completion(.failure(.unknownError))
                }
            }
        }
    }
    
    // MARK: - Auth
    public func signOut(completion: ((Bool) -> Void)?) {
        do {
            try Auth.auth().signOut()
            completion?(true)
        } catch {
            completion?(false)
        }
    }
    
    public func signIn(email: String, password: String, completion: @escaping(Result<Void, FirebaseError>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if result != nil {
                completion(.success(Void()))
            } else {
                completion(.failure(.unknownError))
            }
        }
    }
    
    // MARK: Auth User Creation Methods
    public func createUser(name: String, email: String, username: String, password: String, completion: @escaping(Result<PrivateProfile, FirebaseError>) -> Void) {
        self.createAuthUser(email: email, password: password) { (result) in
            switch result {
            case .success(let userIdentifier):
                let profile = UserProfile(information: UserInformation(identifier: userIdentifier, username: username, name: name), friends: [])
                let privateProfile = PrivateProfile(profile: profile, email: email)
                
                self.createFirestoreUser(profile: privateProfile) { (result) in
                    switch result {
                    case .success(let profile):
                        completion(.success(profile))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                print("Error creating auth user: \(error)")
                
                completion(.failure(error))
            }
        }
    }
    
    private func createAuthUser(email: String, password: String, completion: @escaping(Result<String, FirebaseError>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let errorCode = error?._code, let error = AuthErrorCode(rawValue: errorCode) {
                switch error {
                case .invalidCustomToken, .customTokenMismatch:
                    completion(.failure(.credentialError))
                case .operationNotAllowed:
                    completion(.failure(.unknownError))
                case .emailAlreadyInUse:
                    completion(.failure(.accountWithEmailExists))
                case .invalidEmail, .missingEmail:
                    completion(.failure(.invalidEmailFormat))
                case .tooManyRequests:
                    completion(.failure(.tooManyRequests))
                case .networkError:
                    completion(.failure(.networkError))
                case .weakPassword:
                    completion(.failure(.passwordTooWeak))
                default:
                    completion(.failure(.unknownError))
                }
            } else if let userIdentifier = authResult?.user.uid {
                completion(.success(userIdentifier))
            } else {
                completion(.failure(.unknownError))
            }
        }
    }
    
    // MARK: Firestore User Creation Methods
    private func createFirestoreUser(profile: PrivateProfile, completion: @escaping(Result<PrivateProfile, FirebaseError>) -> Void) {
        guard let publicProfileDoc = self.userDocument else { completion(.failure(.firestoreUserCreationFailure)); return }
        guard let privateProfileDoc = self.privateUserDocument else { completion(.failure(.firestoreUserCreationFailure)); return }
        
        // Encode Profiles
        let encodedPublicProfile = try! FirestoreEncoder().encode(profile.publicProfile)
        let encodedPrivateProfile = try! FirestoreEncoder().encode(profile)
        
        let batchWrite = Firestore.firestore().batch()
        
        batchWrite.setData(encodedPublicProfile, forDocument: publicProfileDoc)
        batchWrite.setData(encodedPrivateProfile, forDocument: privateProfileDoc)
        
        batchWrite.commit { (error) in
            if error != nil {
                completion(.failure(.firestoreUserCreationFailure))
            } else {
                completion(.success(profile))
            }
        }
    }
    
    // MARK: - Firestore
    
    // MARK: Firestore User Methods
    public func currentUser(completion: ((Result<PrivateProfile, FirebaseError>) -> Void)? = nil) {
        guard let privateUserDoc = self.privateUserDocument,
              let userIdentifier = self.currentUserIdentifier
        else { completion?(.failure(.unknownError)); return }
        
        privateUserDoc.getDocument(completion: { (snapshot, error) in
            if error != nil {
                completion?(.failure(.userFetchFailure(userIdentifier)))
            } else if let snapshot = snapshot {
                let data = snapshot.data()
                
                let profile = try! FirebaseDecoder().decode(PrivateProfile.self, from: data)
                
                completion?(.success(profile))
            } else {
                completion?(.failure(.unknownError))
            }
        })
    }
    
    public func currentUserFriendRequests(completion: @escaping(Result<[String], FirebaseError>) -> Void) {
        guard let friendRequestCollection = self.userDocument?.collection("FriendRequests") else { completion(.failure(.unknownError)); return }
        
        friendRequestCollection.getDocuments { (snapshot, error) in
            if error != nil || snapshot == nil {
                completion(.failure(.noResponse))
            } else if let snapshot = snapshot {
                let data = snapshot.documents.compactMap({$0.data()})
                
                let friendRequests = try! FirebaseDecoder().decode([String].self, from: data)
                
                completion(.success(friendRequests))
            } else {
                completion(.failure(.unknownError))
            }
        }
    }
    
    public func fetchUser(with identifier: String, completion: @escaping(Result<UserProfile, FirebaseError>) -> Void) {
        self.usersCollection.document(identifier).getDocument { (snapshot, error) in
            if error != nil || snapshot == nil {
                completion(.failure(.userFetchFailure(identifier)))
            } else if let snapshot = snapshot {
                let data = snapshot.data()
                
                let profile = try! FirebaseDecoder().decode(UserProfile.self, from: data)
                
                completion(.success(profile))
            } else {
                completion(.failure(.unknownError))
            }
        }
    }
    
    public func searchUsers(by username: String, limit: Int = 15, completion: @escaping(Result<[UserProfile], FirebaseError>) -> Void) {
        self.usersCollection.order(by: "information.username").whereField("information.username", isGreaterThanOrEqualTo: username).whereField("information.username", isLessThanOrEqualTo: "\(username)z").limit(to: limit).getDocuments { (snapshot, error) in
            if error != nil {
                completion(.failure(.userFetchFailure(username)))
            } else {
                guard let data = snapshot?.documents.map({ $0.data() }) else { completion(.failure(.userFetchFailure(username))); return }
                
                do {
                    let profiles = try FirebaseDecoder().decode([UserProfile].self, from: data)
                    
                    completion(.success(profiles))
                } catch {
                    completion(.failure(.userFetchFailure(username)))
                }
            }
        }
    }
    
    public func getFriends(for userIdentifier: String,completion: @escaping(Result<[UserRelationship], FirebaseError>) -> Void) {
        self.userRelationshipsCollection.whereField("user.identifier", isEqualTo: userIdentifier).getDocuments { (snapshot, error) in
            if error != nil || snapshot == nil {
                completion(.failure(.noResponse))
            } else {
                guard let snapshot = snapshot,
                      !snapshot.isEmpty
                else { completion(.failure(.friendFetchFailure(userIdentifier))); return }
                
                let data = snapshot.documents.map({$0.data()})
                
                do {
                    let friends = try FirebaseDecoder().decode([UserRelationship].self, from: data)

                    completion(.success(friends))
                } catch {
                    completion(.failure(.friendFetchFailure(userIdentifier)))
                }
            }
        }
    }
    
//    public func addNewRelationship(from baseUser: UserInformation, relationship: UserRelationship.Relationship, to relatedUser: UserInformation,
//                                   completion: @escaping(Result<UserRelationship, FirebaseError>) -> Void) {
//        let newRelationship = UserRelationship(baseUser: baseUser, relatedUser: relatedUser, relationship: relationship, desiredRelationship: <#Firebase.UserRelationship.Relationship#>)
//        
//        let encodedRelationship = try! FirestoreEncoder().encode(newRelationship)
//        
//        self.userRelationshipsCollection.addDocument(data: encodedRelationship) { (error) in
//            if error != nil {
//                completion(.failure(.unknownError))
//            } else {
//                completion(.success(newRelationship))
//            }
//        }
//    }
    
    public func removeRelationship(between baseUser: UserInformation, and relatedUser: UserInformation,
                                   completion: @escaping(Result<UserRelationship, FirebaseError>) -> Void) {
        self.userRelationshipsCollection.whereField("baseUser.identifier", isEqualTo: baseUser.identifier).whereField("relatedUser.identifier", isEqualTo: relatedUser.identifier).getDocuments { (snapshot, error) in
            if error != nil {
                completion(.failure(.unknownError))
            } else {
                guard let documents = snapshot?.documents,
                      let firstRelationshipData = documents.first?.data()
                else { completion(.failure(.unknownError)); return }
                
                let decodedFirstRelationship = try! FirebaseDecoder().decode(UserRelationship.self, from: firstRelationshipData)
                
                documents.forEach({self.userRelationshipsCollection.document($0.documentID).delete()})
                completion(.success(decodedFirstRelationship))
            }
        }
    }
    
    // MARK: - Session
    func fetchSession(for sessionID: String, completion: @escaping(Result<SessionManager.MusicSession, FirebaseError>) -> Void) {
        let sessionDocument = self.sessionsCollection.document(sessionID)
        
        // Get main document
        sessionDocument.getDocument { (snapshot, error) in
            if error != nil || snapshot == nil {
                completion(.failure(.noResponse))
            } else {
                guard let data = snapshot?.data() else { completion(.failure(.unknownError)); return }
                
                do {
                    let session = try FirebaseDecoder().decode(SessionManager.MusicSession.self, from: data)
                    
                    completion(.success(session))
                } catch {
                    completion(.failure(.unknownError))
                }
            }
        }
    }
    
    func fetchUserSessions(for userID: String, completion: @escaping(Result<[SessionManager.MusicSession], FirebaseError>) -> Void) {
        self.sessionsCollection
            .whereField("details.host.information.identifier", isEqualTo: userID)
            .order(by: "details.startDate", descending: true)
            .getDocuments { (snapshot, error) in
            if error != nil {
                completion(.failure(.unknownError))
            } else {
                guard let documents = snapshot?.documents else { completion(.failure(.unknownError)); return }
                let data = documents.map({ $0.data() })
                
                do {
                    let userSessions = try FirebaseDecoder().decode([SessionManager.MusicSession].self, from: data)
                    
                    completion(.success(userSessions))
                } catch let error {
                    let decodeError = (error as? DecodingError)
                    completion(.failure(.unknownError))
                }
            }
        }
    }
    
    func newSession(from session: SessionManager.MusicSession, completion: @escaping(Result<SessionManager.MusicSession, FirebaseError>) -> Void) {
        let sessionID = session.details.identifier
        
        let sessionDocument = self.sessionsCollection.document(sessionID)
        guard let userCurrentSessionDocument = self.currentSessionCollection?.document(sessionID) else { completion(.failure(.userNotFound)); return }
        
        let encodedSession = try! FirestoreEncoder().encode(session)
        
        let batchWrite = Firestore.firestore().batch()
        
        batchWrite.setData(encodedSession, forDocument: sessionDocument, merge: false)
        batchWrite.setData(encodedSession, forDocument: userCurrentSessionDocument, merge: false)
        
        batchWrite.commit { (error) in
            if error != nil {
                completion(.failure(.unknownError))
            } else {
                completion(.success(session))
            }
        }
    }
    
    func updateSession(_ session: SessionManager.MusicSession, completion: @escaping(Result<SessionManager.MusicSession, FirebaseError>) -> Void) {
        let sessionID = session.details.identifier
        
        let sessionDocument = self.sessionsCollection.document(sessionID)
        guard let userCurrentSessionDocument = self.currentSessionCollection?.document(sessionID) else { completion(.failure(.userNotFound)); return }
        
        let encodedSession = try! FirestoreEncoder().encode(session)
        
        let batchWrite = Firestore.firestore().batch()
        
        batchWrite.updateData(encodedSession, forDocument: sessionDocument)
        batchWrite.updateData(encodedSession, forDocument: userCurrentSessionDocument)
        
        batchWrite.commit { (error) in
            if error != nil {
                completion(.failure(.unknownError))
            } else {
                completion(.success(session))
            }
        }
    }
    
    func joinSession(sessionID: String, completion: @escaping(Result<SessionManager.MusicSession, FirebaseError>) -> Void) {
        let sessionDocument = self.sessionsCollection.document(sessionID)
        
        let sessionListener = sessionDocument.addSnapshotListener(includeMetadataChanges: true) { (snapshot, error) in
            if error != nil {
                completion(.failure(.unknownError))
            } else {
                guard let snapshot = snapshot,
                      let data = snapshot.data()
                else { completion(.failure(.unknownError)); return }
                
                do {
                    let decodedSession = try FirebaseDecoder().decode(SessionManager.MusicSession.self, from: data)
                
                    guard sessionID == decodedSession.details.identifier,
                          let currentUserID = self.currentUserIdentifier
                    else { completion(.failure(.unknownError)); return }
                    
                    self.addToListenerList(sessionDocumentReference: sessionDocument, userID: currentUserID) { (result) in
                        switch result {
                        case .success(_):
                            completion(.success(decodedSession))
                            self.sessionListenerUpdateDelegate?.update(for: sessionID, update: decodedSession)
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } catch {
                    completion(.failure(.unknownError))
                }
            }
        }
        
        self.documentListeners.append(sessionListener)
    }
    
    func leaveSession(_ session: SessionManager.MusicSession, completion: ((Result<SessionManager.MusicSession, FirebaseError>) -> Void)? = nil) {
        guard let currentUserID = self.currentUserIdentifier,
              !session.isHost
        else { completion?(.failure(.notAuthorised)); return }
        let sessionDocument = self.sessionsCollection.document(session.details.identifier)
        
        // Remove from listener list locally and in Firestore
        self.removeFromListenerList(sessionDocumentReference: sessionDocument, userID: currentUserID) { (result) in
            switch result {
            case .success(_):
                completion?(.success(session))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    private func addToListenerList(sessionDocumentReference: DocumentReference, userID: String, completion: @escaping(Result<Bool, FirebaseError>) -> Void) {
        let listenerCollection = sessionDocumentReference.collection("Listeners")
        
        listenerCollection.document(userID).setData(["joinedAt" : Timestamp(date: Date())], merge: true) { (error) in
            if error != nil {
                completion(.failure(.unknownError))
            } else {
                completion(.success(true))
            }
        }
    }
    
    private func removeFromListenerList(sessionDocumentReference: DocumentReference, userID: String, completion: @escaping(Result<Bool, FirebaseError>) -> Void) {
        let listenerDocument = sessionDocumentReference.collection("Listeners").document(userID)
        
        listenerDocument.delete { (error) in
            if error != nil {
                completion(.failure(.unknownError))
            } else {
                completion(.success(true))
            }
        }
    }
    
}

// MARK: CodableFirebase
extension DocumentReference: DocumentReferenceType { }
extension GeoPoint: GeoPointType { }
extension FieldValue: FieldValueType { }
extension Timestamp: TimestampType { }
