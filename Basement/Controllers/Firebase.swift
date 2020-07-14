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
    }
    
    enum FirebaseAuthError: Error {
        case unknownError
        
       
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
    }
    
    class UserRelationship: Codable {
        // MARK: Properties
        let baseUser: UserInformation
        let relatedUser: UserInformation
        let relationship: Relationship
        
        // MARK: Enums
        enum Relationship: String, Codable, Equatable {
            case notFriends
            case isMyFriend
            case areTheirFriend
            case friends
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
        
        // MARK: Deocdable
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
        
        // MARK: Initialiser
        init(information: UserInformation, friends: [UserRelationship]) {
            self.information = information
            self.friends = friends
        }
        
        // MARK: Codable
        private enum CodingKeys: String, CodingKey {
            case information, friends
        }
        
        // MARK: Decodable
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.information = try container.decode(UserInformation.self, forKey: .information)
            self.friends = try container.decode([UserRelationship].self, forKey: .friends)
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
        
        let tokenString = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IllVOUE2MkhTTjYifQ.eyJpc3MiOiIzVjkzQTNBQ1Y5IiwiaWF0IjoxNTk0NzQzMDE5LCJleHAiOjE1OTQ3ODYyMTl9.IDI8pNxx-_3wkrBYMzexYb-Jc0hEa1vuqhgVQWCQchfcfDLrL8NAQF8XL4Bz7H19oYG69ZtNlIg4oTHc95yIJA"
        
        completion(.success(tokenString))
    }
    
    // MARK: - Auth
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
    
    public func addNewRelationship(from baseUser: UserInformation, relationship: UserRelationship.Relationship, to relatedUser: UserInformation,
                                   completion: @escaping(Result<UserRelationship, FirebaseError>) -> Void) {
        let newRelationship = UserRelationship(baseUser: baseUser, relatedUser: relatedUser, relationship: relationship)
        
        let encodedRelationship = try! FirestoreEncoder().encode(newRelationship)
        
        self.userRelationshipsCollection.addDocument(data: encodedRelationship) { (error) in
            if error != nil {
                completion(.failure(.unknownError))
            } else {
                completion(.success(newRelationship))
            }
        }
    }
    
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
        self.sessionsCollection.whereField("details.identifier", arrayContains: userID).getDocuments { (snapshot, error) in
            if error != nil {
                completion(.failure(.unknownError))
            } else {
                guard let data = snapshot?.documents.map({$0.data()}) else { completion(.failure(.unknownError)); return }
                
                do {
                    let userSessions = try FirebaseDecoder().decode([SessionManager.MusicSession].self, from: data)
                    
                    completion(.success(userSessions))
                } catch {
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
                
                    guard sessionID == decodedSession.details.identifier else { completion(.failure(.unknownError)); return }
                    completion(.success(decodedSession))
                    self.sessionListenerUpdateDelegate?.update(for: sessionID, update: decodedSession)
                } catch {
                    completion(.failure(.unknownError))
                }
            }
        }
        
        self.documentListeners.append(sessionListener)
    }
    
    func leaveSession(_ session: SessionManager.MusicSession, completion: ((Result<SessionManager.MusicSession, FirebaseError>) -> Void)? = nil) {
        guard !session.isHost else { completion?(.failure(.notAuthorised)); return }
        
        // Remove from listener list locally and in Firestore
        
        completion?(.failure(.unknownError))
    }
    
}

// MARK: CodableFirebase
extension DocumentReference: DocumentReferenceType {}
extension GeoPoint: GeoPointType {}
extension FieldValue: FieldValueType {}
extension Timestamp: TimestampType {}
