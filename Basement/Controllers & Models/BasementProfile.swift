//
//  BasementProfile.swift
//  Basement
//
//  Created by George Nick Gorzynski on 21/10/2020.
//

import Foundation

class BasementProfile {
    
    // MARK: Static Instance
    static let shared = BasementProfile()
    
    // MARK: Properties
    private(set) var currentUser: Profile? = nil
    
    // MARK: Structs
    public struct Profile: Codable {
        let details: UserDetails
        let pastSessions: [SessionManager.PastSession]
    }
    
    public struct UserDetails: Codable, Equatable {
        let username: String
        let connectedService: ConnectedService?
    }
    
    public struct ConnectedService: Codable, Equatable {
        let platform: StreamingPlatform.Platforms
        let username: String
    }
    
    // MARK: Enums
    
    // MARK: Methods
    public func fetchUser(id userID: String, completion: @escaping(Result<Profile, Firebase.FirebaseError>) -> Void) {
        let userFetchDispatch = DispatchGroup()
        
        var userDetails: UserDetails?
        var pastSessions: [SessionManager.PastSession]?
        
        userFetchDispatch.enter()
        Firebase.firestore.fetchUserDetails(for: userID) { (result) in
            switch result {
            case .success(let fetchedUserDetails):
                userDetails = fetchedUserDetails
            case .failure(let error):
                completion(.failure(error))
            }
            
            userFetchDispatch.leave()
        }
        
        userFetchDispatch.enter()
        Firebase.firestore.fetchPastSessions(for: userID) { (result) in
            switch result {
            case .success(let fetchedPastSessions):
                pastSessions = fetchedPastSessions
            case .failure(let error):
                completion(.failure(error))
            }
            
            userFetchDispatch.leave()
        }
        
        userFetchDispatch.notify(queue: .global(qos: .userInitiated)) {
            guard let userDetails = userDetails,
                  let pastSessions = pastSessions
            else { return }
            
            let fetchedProfile = Profile(details: userDetails, pastSessions: pastSessions)
            
            completion(.success(fetchedProfile))
        }
    }
    
    public func fetchCurrentUser(completion: @escaping(Result<Profile, Firebase.FirebaseError>) -> Void) {
        guard Firebase.auth.isSignedIn, let currentUserID = Firebase.auth.user?.uid else { completion(.failure(.undefined)); return }
        
        self.fetchUser(id: currentUserID, completion: completion)
    }
    
}
