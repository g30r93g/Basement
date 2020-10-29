//
//  Firebase.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/08/2020.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class Firebase {
    
    // MARK: Shared Instance
    static let auth = FirebaseAuthHandler()
    static let firestore = FirestoreHandler()
    
    // MARK: Enums
    internal enum FirebaseError: Error {
        case undefined
    }
    
}

class FirebaseAuthHandler {
    
    // MARK: Properties
    private var auth: Auth {
        get {
            return Auth.auth()
        }
    }
    
    public var isSignedIn: Bool {
        return self.auth.currentUser != nil
    }
    
    public var user: User? {
        return self.auth.currentUser
    }
    
    // MARK: Methods
    public func signUp(email: String,
                       password: String,
                       userDetails: BasementProfile.UserDetails,
                       completion: @escaping(Result<BasementProfile.UserDetails, Firebase.FirebaseError>) -> Void) {
        
        self.auth.createUser(withEmail: email, password: password) { (result, error) in
            
            Firebase.firestore.createNewUser(details: userDetails, completion: completion)
        }
    }
    
    public func signIn(email: String,
                       password: String,
                       completion: @escaping(Result<BasementProfile.UserDetails, Firebase.FirebaseError>) -> Void) {
        self.auth.signIn(withEmail: email, password: password) { (result, error) in
            if let userID = result?.user.uid {
                Firebase.firestore.fetchUserDetails(for: userID, completion: completion)
            } else {
                completion(.failure(.undefined))
            }
        }
    }
    
}

class FirestoreHandler {
    
    // MARK: Properties
    private var firestore: Firestore {
        get {
            return Firestore.firestore()
        }
    }
    
    private var userCollection: CollectionReference {
        get {
            return self.firestore.collection("User")
        }
    }
    
    private var sessionCollection: CollectionReference {
        get {
            return self.firestore.collection("Session")
        }
    }
    
    private var currentUserDocument: DocumentReference? {
        get {
            if let userID = Firebase.auth.user?.uid {
                return self.userCollection.document(userID)
            } else {
                return nil
            }
        }
    }
    
    private(set) var listeners: [String : ListenerRegistration] = [:]
    
    // MARK: User Methods
    public func createNewUser(details: BasementProfile.UserDetails,
                              completion: @escaping(Result<BasementProfile.UserDetails, Firebase.FirebaseError>) -> Void) {
        do {
            let firestoreUserRepr = try Firestore.Encoder().encode(details)
            
            self.currentUserDocument?.setData(firestoreUserRepr, completion: { (error) in
                if error != nil {
                    completion(.failure(.undefined))
                } else {
                    completion(.success(details))
                }
            })
        } catch {
            completion(.failure(.undefined))
        }
    }
    
    public func updateConnectedService(to service: BasementProfile.ConnectedService,
                                       completion: @escaping(Result<BasementProfile.UserDetails, Firebase.FirebaseError>) -> Void) {
        guard let currentUserDoc = self.currentUserDocument else { completion(.failure(.undefined)); return }
        
        do {
            let encodedService = try Firestore.Encoder().encode(service)
            
            currentUserDoc.updateData(["connectedService" : encodedService]) { (error) in
                if error != nil {
                    self.fetchUserDetails(for: currentUserDoc.documentID, completion: completion)
                } else {
                    completion(.failure(.undefined))
                }
            }
        } catch {
            completion(.failure(.undefined))
        }
    }
    
    public func fetchUserDetails(for userID: String,
                                 completion: @escaping(Result<BasementProfile.UserDetails, Firebase.FirebaseError>) -> Void) {
        self.userCollection.document(userID).getDocument() { (snapshot, error) in
            guard let data = snapshot?.data() else { completion(.failure(.undefined)); return }
            
            do {
                let userDetails = try Firestore.Decoder().decode(BasementProfile.UserDetails.self, from: data)
                
                completion(.success(userDetails))
            } catch {
                completion(.failure(.undefined))
            }
        }
    }
    
    public func fetchPastSessions(for userID: String,
                                  completion: @escaping(Result<[SessionManager.PastSession], Firebase.FirebaseError>) -> Void) {
        self.userCollection.document(userID).collection("Past Sessions").getDocuments(source: .server) { (snapshot, error) in
            guard let data = snapshot?.documents else { completion(.failure(.undefined)); return }
            do {
                let pastSessions = try data.compactMap({ try Firestore.Decoder().decode(SessionManager.PastSession.self, from: $0.data()) })
                
                completion(.success(pastSessions))
            } catch {
                completion(.failure(.undefined))
            }
        }
    }
    
    // MARK: Session Methods
    public func addSessionListener(sessionID: String,
                                   collectionID: String, listener: @escaping(FIRQuerySnapshotBlock)) {
        let listener = self.sessionCollection.document(sessionID).collection(collectionID).addSnapshotListener(listener)
        
        self.listeners.updateValue(listener, forKey: "\(sessionID)-\(collectionID)")
    }
    
    public func removeListeners(with sessionID: String,
                                completion: () -> Void) {
        self.listeners.filter({$0.key.starts(with: sessionID)}).forEach({self.listeners.removeValue(forKey: $0.key)?.remove()})
        
        completion()
    }
    
    // MARK: Session Host Methods
    public func startSession(_ session: SessionManager.Session,
                             completion: @escaping(Result<SessionManager.Session, Firebase.FirebaseError>) -> Void) {
        do {
            let firestoreSessionRepr = try Firestore.Encoder().encode(session)
            let trackList = session.tracks
            
            self.sessionCollection.document(session.details.sessionID).setData(firestoreSessionRepr, merge: false) { (error) in
                if error != nil {
                    completion(.failure(.undefined))
                } else {
                    self.uploadTrackList(trackList, sessionID: session.details.sessionID) {
                        completion(.success(session))
                    }
                }
            }
        } catch {
            completion(.failure(.undefined))
        }
    }
    
    public func endSession(_ session: SessionManager.Session,
                           completion: @escaping(Result<SessionManager.PastSession, Firebase.FirebaseError>) -> Void) {
        do {
            let firestoreSessionRepr = try Firestore.Encoder().encode(session)
            
            self.sessionCollection.document(session.details.sessionID).updateData(firestoreSessionRepr) { (error) in
                if error != nil {
                    completion(.failure(.undefined))
                } else {
                    let pastSession = SessionManager.PastSession(session)
                    self.uploadPastSession(pastSession, completion: completion)
                }
            }
        } catch {
            completion(.failure(.undefined))
        }
    }
    
    private func uploadTrackList(_ tracks: [SessionManager.Track], sessionID: String, completion: @escaping() -> Void) {
        let trackListDispatch = DispatchGroup()
        var totalComplete = 0
        
        for track in tracks {
            trackListDispatch.enter()
            self.addTrack(track, sessionID: sessionID) { (_) in
                totalComplete += 1
                trackListDispatch.leave()
            }
        }
        
        trackListDispatch.notify(queue: .global(qos: .userInitiated)) {
            guard totalComplete == tracks.count else { return }
            
            completion()
        }
    }
    
    private func uploadPastSession(_ pastSession: SessionManager.PastSession,
                                   completion: @escaping(Result<SessionManager.PastSession, Firebase.FirebaseError>) -> Void) {
        do {
            guard let currentUserDoc = self.currentUserDocument else { completion(.failure(.undefined)); return }
            let firestoreRepr = try Firestore.Encoder().encode(pastSession)
            
            currentUserDoc.collection("Past Session").document(pastSession.details.sessionID).setData(firestoreRepr) { (error) in
                if error != nil {
                    completion(.failure(.undefined))
                } else {
                    completion(.success(pastSession))
                }
            }
        } catch {
            completion(.failure(.undefined))
        }
    }
    
    public func newPlaybackCommand(session: SessionManager.Session,
                                   command: PlaybackManager.Playback,
                                   completion: @escaping(Result<PlaybackManager.Playback, Firebase.FirebaseError>) -> Void) {
        do {
            let encodedCommand = try Firestore.Encoder().encode(command)
            
            self.sessionCollection.document(session.details.sessionID)
                .collection("Playback").addDocument(data: encodedCommand) { (error) in
                    if error == nil {
                        completion(.success(command))
                    } else {
                        completion(.failure(.undefined))
                    }
                }
        } catch {
            completion(.failure(.undefined))
        }
    }
    
    public func addTrack(_ track: SessionManager.Track,
                         sessionID: String,
                         completion: @escaping(Bool) -> Void) {
        do {
            let encodedTrack = try Firestore.Encoder().encode(track)
            
            self.sessionCollection.document(sessionID)
                .collection("Tracks").addDocument(data: encodedTrack) { (error) in
                    completion(error == nil)
                }
        } catch {
            completion(false)
        }
    }
    
    public func deleteTrack(_ track: SessionManager.Track,
                            sessionID: String,
                            completion: @escaping(Bool) -> Void) {
        self.sessionCollection.document(sessionID)
            .collection("Tracks")
            .whereField("playbackIndex", isEqualTo: track.playbackIndex)
            .getDocuments { (snapshot, error) in
                guard error == nil,
                      snapshot?.isEmpty != nil,
                      let document = snapshot?.documents.first
                else { completion(false); return }
                
                let trackDocumentID = document.documentID
                
                self.sessionCollection.document(sessionID)
                    .collection("Tracks").document(trackDocumentID)
                    .delete { (error) in
                        completion(error == nil)
                    }
            }
    }
    
    public func moveTrack(_ track: SessionManager.Track,
                          newPosition: Int,
                          sessionID: String,
                          completion: @escaping(Result<[SessionManager.Track], Firebase.FirebaseError>) -> Void) {
        var moveTrackBatch = self.firestore.batch()
        let tracksColl = self.sessionCollection.document(sessionID).collection("Tracks")
        
        let oldPosition = track.playbackIndex
        // Get tracks between oldPosition and newPosition
        // If oldPosition < newPosition, the moving track needs an increase in index, and all subsequent displaced tracks have a decrease in index (ie: the track has moved down the queue)
        // If oldPosition > newPosition, the moving track needs a decrease in index, and all subsequent displaced tracks have an increase in index (ie: the track has moved up the queue)
        let trackHasMovedUpQueue = oldPosition > newPosition
        
        let moveDispatchGroup = DispatchGroup()
        
        // First, get the document of the track that needs moving
        var documentOfMovingTrack: DocumentSnapshot?
        
        moveDispatchGroup.enter()
        tracksColl.whereField("playbackIndex", isEqualTo: oldPosition)
            .getDocuments { (snapshot, error) in
                guard error == nil,
                      snapshot?.isEmpty != nil,
                      let matchingDocument = snapshot?.documents.first
                else { completion(.failure(.undefined)); return }
                
                documentOfMovingTrack = matchingDocument
                moveDispatchGroup.leave()
        }
        
        // Next, get the documents that have been displaced by the track
        var documentsOfDisplacedTracks: [QueryDocumentSnapshot]?
        
        moveDispatchGroup.enter()
        tracksColl.whereField("playbackIndex", isGreaterThan: trackHasMovedUpQueue ? newPosition + 1 : oldPosition) // Lower Bound
            .whereField("playbackIndex", isLessThan: trackHasMovedUpQueue ? oldPosition : newPosition + 1) // Upper Bound
            .getDocuments { (snapshot, error) in
                guard error == nil,
                      snapshot?.isEmpty != nil,
                      let matchingDocuments = snapshot?.documents
                else { completion(.failure(.undefined)); return }
                
                documentsOfDisplacedTracks = matchingDocuments
            }
        
        // Then, change all data
        moveDispatchGroup.notify(queue: .global(qos: .userInitiated)) {
            guard let movingTrackDoc = documentOfMovingTrack,
                  let displacedTrackDocs = documentsOfDisplacedTracks
                  else { return }
            
            // Change Moving Track
            self.changeTrackIndex(trackColl: tracksColl, trackDocID: movingTrackDoc.documentID, newIndex: newPosition, batch: &moveTrackBatch)
            
            // Change Displaced Tracks
            for displacedTrack in displacedTrackDocs {
                var newTrackIndex = displacedTrack.data()["playbackIndex"] as! Int
                
                if trackHasMovedUpQueue {
                    newTrackIndex += 1
                } else {
                    newTrackIndex -= 1
                }
                
                self.changeTrackIndex(trackColl: tracksColl, trackDocID: displacedTrack.documentID, newIndex: newTrackIndex, batch: &moveTrackBatch)
            }
            
            // Finally, upload data
            moveTrackBatch.commit { (error) in
                if error != nil {
                    completion(.failure(.undefined))
                } else {
                    self.fetchTracksOnServer(sessionID: sessionID, completion: completion)
                }
            }
        }
    }
    
    private func changeTrackIndex(trackColl: CollectionReference, trackDocID: String, newIndex: Int, batch: inout WriteBatch) {
        batch.updateData(["playbackIndex" : newIndex], forDocument: trackColl.document(trackDocID))
    }
    
    private func fetchTracksOnServer(sessionID: String, completion: @escaping(Result<[SessionManager.Track], Firebase.FirebaseError>) -> Void) {
        self.sessionCollection.document(sessionID)
            .collection("Tracks").getDocuments(source: .server) { (snapshot, error) in
            guard error == nil,
                  snapshot?.isEmpty == false,
                  let docs = snapshot?.documents
            else { completion(.failure(.undefined)); return }
            
            do {
                let tracksOnServer = try docs.compactMap({ try Firestore.Decoder().decode(SessionManager.Track.self, from: $0.data()) })
                
                self.fetchTrackListDetails(tracksOnServer, completion: completion)
            } catch {
                completion(.failure(.undefined))
            }
        }
    }
    
    public func fetchTrackListDetails(_ tracks: [SessionManager.Track], completion: @escaping(Result<[SessionManager.Track], Firebase.FirebaseError>) -> Void) {
        
        let trackListFetchDispatch = DispatchGroup()
        
        var fetchedTracks: [SessionManager.Track] = []
        
        for track in tracks {
            trackListFetchDispatch.enter()
            
            let trackFetchDispatch = DispatchGroup()
            
            let playbackIndex = track.playbackIndex
            var streamingInfo: [Music.StreamingInfo] = []
            var failedFetches = 0
            
            for info in track.content.streamingInformation {
                trackFetchDispatch.enter()
                
                self.fetchTrackDetails(platform: info.platform, identifier: info.identifier) { (result) in
                    switch result {
                    case .success(let track):
                        track.streamingInformation.forEach({ streamingInfo.append($0) })
                    case .failure(_):
                        failedFetches += 1
                    }
                    
                    trackFetchDispatch.leave()
                }
            }
            
            trackFetchDispatch.notify(queue: .global(qos: .userInitiated)) {
                guard streamingInfo.count + failedFetches > 1 else { return }
                let trackDetails = Music.Content(name: track.content.name, artworkURL: track.content.artwork, streamingInformation: streamingInfo)
                
                fetchedTracks.append(SessionManager.Track(playbackIndex: playbackIndex, content: trackDetails))
            }
        }
    }
    
    private func fetchTrackDetails(platform: StreamingPlatform.Platforms, identifier: String, completion: @escaping(Result<Music.Song, Firebase.FirebaseError>) -> Void) {
        StreamingPlatform().fetchTrack(platform: platform, identifier: identifier) { (result) in
            switch result {
            case .success(let track):
                completion(.success(track))
            case .failure(_):
                completion(.failure(.undefined))
            }
        }
    }
    
    // MARK: Session Join Methods
    public func joinSession(code joinCode: String,
                            completion: @escaping(Result<SessionManager.Session, Firebase.FirebaseError>) -> Void) {
        self.fetchSessionDetails(joinCode: joinCode) { (result) in
            switch result {
            case .success(let session):
                self.addUserToListenerList(session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func leaveSession(_ session: SessionManager.Session,
                             completion: @escaping(Result<SessionManager.Session, Firebase.FirebaseError>) -> Void) {
        self.removeUserFromListenerList(session: session, completion: completion)
    }
    
    private func fetchSessionDetails(joinCode: String,
                                     completion: @escaping(Result<SessionManager.Session, Firebase.FirebaseError>) -> Void) {
        self.sessionCollection.whereField("joinDetails.code", isEqualTo: joinCode)
            .getDocuments(source: .server) { (snapshot, error) in
                guard error == nil,
                      let snapshot = snapshot,
                      let data = snapshot.documents.first.map({$0.data()})
                else { completion(.failure(.undefined)); return }
                
                do {
                    let session = try Firestore.Decoder().decode(SessionManager.Session.self, from: data)
                    
                    session.details.endedAt == nil ? completion(.success(session)) : completion(.failure(.undefined))
                } catch let error {
                    print(error)
                    completion(.failure(.undefined))
                }
            }
    }
    
    private func addUserToListenerList(session: SessionManager.Session,
                                       completion: @escaping(Result<SessionManager.Session, Firebase.FirebaseError>) -> Void) {
        guard let currentUserID = Firebase.auth.user?.uid else { completion(.failure(.undefined)); return }
        
        BasementProfile.shared.fetchCurrentUser { (result) in
            switch result {
            case .success(let userProfile):
                do {
                    let userDetails = SessionManager.Listener(userDetails: userProfile.details)
                    let encodedDetails = try Firestore.Encoder().encode(userDetails)
                    
                    self.sessionCollection.document(session.details.sessionID)
                        .collection("Listeners").document(currentUserID)
                        .setData(encodedDetails) { (error) in
                            if error == nil {
                                completion(.success(session))
                            } else {
                                completion(.failure(.undefined))
                            }
                        }
                } catch {
                    completion(.failure(.undefined))
                }
            case .failure(_):
                completion(.failure(.undefined))
            }
        }
    }
    
    private func removeUserFromListenerList(session: SessionManager.Session,
                                            completion: @escaping(Result<SessionManager.Session, Firebase.FirebaseError>) -> Void) {
        guard let currentUserID = Firebase.auth.user?.uid else { completion(.failure(.undefined)); return }
        
        self.sessionCollection.document(session.details.sessionID)
            .collection("Listeners").document(currentUserID)
            .delete { (error) in
                if error != nil {
                    completion(.failure(.undefined))
                } else {
                    completion(.success(session))
                }
            }
    }
    
}
