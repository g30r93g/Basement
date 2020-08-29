//
//  Firebase.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/08/2020.
//

import Foundation
import Firebase
import CodableFirebase

class Firebase {
    
    // MARK: - Shared Instance
    static let current = Firebase()
    
    // MARK: - Public Interfaces
    
    // MARK: Enums
    enum FirebaseError: Error {
        case generic
        
        case unknownError
        
        case networkUnavailable
        
        case decodeError
        case encodeError
        
        case basementFull
        case basementDoesNotExist
    }
    
    // MARK: Methods
    
    /// Creates a basement for other listeners to join.
    public func createBasement(session: SessionManager.Session, completion: @escaping(Result<SessionManager.Session, FirebaseError>) -> Void) {
        self.generateUniqueBasementCode() { (result) in
            switch result {
            case .success(let joinCode):
                let sessionDetails = session.details
                let newSession = SessionManager.Session(details: SessionManager.SessionDetails(name: sessionDetails.name, code: joinCode, host: sessionDetails.host, listeners: sessionDetails.listeners, maxListeners: sessionDetails.maxListeners), playback: session.playback)
                
                self.uploadBasementSession(newSession, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Joins an existing basement.
    public func joinBasement(code: String, completion: @escaping(Result<SessionManager.Session, FirebaseError>) -> Void) {
        self.basementSessionsCollection.document(code).getDocument(source: .server) { (snapshot, error) in
            if let error = error {
                completion(.failure(.generic))
            } else {
                do {
                    guard let data = snapshot?.data() else { throw FirebaseError.decodeError }
                    let basementSession = try FirestoreDecoder().decode(SessionManager.Session.self, from: data)
                    
                    completion(.success(basementSession))
                } catch {
                    completion(.failure(.decodeError))
                }
            }
        }
    }
    
    /// Leaves a basement.
    public func leaveBasement(session: SessionManager.Session, completion: @escaping(Result<Bool, FirebaseError>) -> Void) {
        self.activeBasementSessionDocument.
    }
    
    /// Adds songs to the queue.
    public func addToQueue(session: SessionManager.Session, song: Music.Song) {
        
    }
    
    // MARK: - Private Interfaces
    
    // MARK: Properties
    private let basementSessionsCollection = Firestore.firestore().collection("Basements")
    private lazy var activeBasementSessionDocument: DocumentReference? = {
        guard let activeSession = SessionManager.current.activeSession else { return nil }
        
        return self.basementSessionsCollection.document(activeSession.details.code)
    }()
    
    // MARK: Methods
    private func generateUniqueBasementCode(completion: @escaping(Result<String, FirebaseError>) -> Void) {
        let uuid = String(UUID().uuidString.suffix(6))
        
        self.basementSessionsCollection.document(uuid).getDocument(source: .server) { (snapshot, error) in
            if let error = error {
                completion(.failure(.generic))
            } else {
                guard let snapshot = snapshot else { completion(.failure(.generic)); return }
                
                if snapshot.exists { self.generateUniqueBasementCode(completion: completion) }
                else { completion(.success(uuid)) }
            }
        }
    }
    
    private func uploadBasementSession(_ session: SessionManager.Session, completion: @escaping(Result<SessionManager.Session, FirebaseError>) -> Void) {
        do {
            guard let encodedSessionDetails = try FirebaseEncoder().encode(session) as? [String : Any] else { completion(.failure(.encodeError)); return }
            
            self.basementSessionsCollection.document(session.details.code).setData(encodedSessionDetails, merge: false) { (error) in
                if let error = error {
                    completion(.failure(.generic))
                } else {
                    completion(.success(session))
                }
            }
        } catch {
            completion(.failure(.encodeError))
        }
    }
    
    private func fetchBasementSession(_ joinCode: String, completion: @escaping(Result<SessionManager.Session, FirebaseError>) -> Void) {
        let basementSessionDocument = self.basementSessionsCollection.document(joinCode)
        
        basementSessionDocument.getDocument(source: .server) { (snapshot, error) in
            if let error = error {
                completion(.failure(.generic))
            } else {
                guard let snapshot = snapshot,
                    let data = snapshot.data(),
                    snapshot.exists
                    else { completion(.failure(.basementDoesNotExist)); return }
                do {
                    let decodedBasementSession = try FirebaseDecoder().decode(SessionManager.Session.self, from: data)
                    
                    completion(.success(decodedBasementSession))
                } catch {
                    completion(.failure(.decodeError))
                }
            }
        }
    }
    
}
