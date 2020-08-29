//
//  SessionManager.swift
//  Basement
//
//  Created by George Nick Gorzynski on 24/08/2020.
//

import Foundation

class SessionManager {
    
    // MARK: - Shared Instance
    static let current = SessionManager()
    
    // MARK: - Public Interfaces
    
    // MARK: Properties
    private(set) public var activeSession: Session? = nil
    
    // MARK: Structs
    struct Session: Codable, Equatable {
        let details: SessionDetails
        
        let playback: PlaybackManager.Playback
    }
    
    struct SessionDetails: Codable, Equatable {
        let name: String
        let code: String
        
        let host: UserDetails
        let listeners: [UserDetails]
        let maxListeners: Int
    }
    
    struct UserDetails: Codable, Equatable {
        let username: String
        let joinedAt: Date
    }
    
    struct PlaybackDetails: Codable, Equatable {
        let currentSongIndex: Int
    }
    
    // MARK: Enums
    enum SessionError: Error {
        case generic
    }
    
    // MARK: Methods
    /// Creates a new basement session
    public func createBasementSession(name: String, hostUsername: String, maxListeners: Int, completion: @escaping(Result<SessionManager.Session, SessionError>) -> Void) {
        let sessionDetails = SessionDetails(name: name, code: "", host: UserDetails(username: hostUsername, joinedAt: Date()), listeners: [], maxListeners: maxListeners)
        let sessionPlayback = PlaybackManager.Playback(tracks: [], currentTrackIndex: -1)
        let newSession = Session(details: sessionDetails, playback: sessionPlayback)
        
        Firebase.current.createBasement(session: newSession) { (result) in
            switch result {
            case .success(let session):
                self.activeSession = session
                
                completion(.success(session))
            case .failure(let error):
                completion(.failure(.generic))
            }
        }
    }
    
    public func joinBasementSession(joinCode: String, completion: @escaping(Result<SessionManager.Session, SessionError>) -> Void) {
        Firebase.current.joinBasement(code: joinCode) { (result) in
            switch result {
            case .success(let session):
                self.activeSession = session
                
                completion(.success(session))
            case .failure(let error):
                completion(.failure(.generic))
            }
        }
    }
    
    public func leaveBasementSession(completion: @escaping(Result<Bool, SessionError>) -> Void) {
        guard let sessionToLeave = self.activeSession else { completion(.failure(.generic)); return }
        
        Firebase.current.leaveBasement(sessionToLeave) { (result) in
            switch result {
                
            }
        }
    }
    
    // MARK: - Private Interfaces
    
}
