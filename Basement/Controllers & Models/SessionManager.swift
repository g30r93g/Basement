//
//  SessionManager.swift
//  Basement
//
//  Created by George Nick Gorzynski on 24/08/2020.
//

import Firebase
import FirebaseFirestoreSwift

class SessionManager {
    
    // MARK: Shared Instance
    static let current = SessionManager()
    
    // MARK: Properties
    private(set) public var activeSession: Session? = nil
    public var sessionUpdateDelegate: SessionUpdateDelegate? = nil
    
    // MARK: Structs
    class Session: Codable, Equatable {
        // MARK: Properties
        var details: SessionDetails
        let joinDetails: JoinDetails
        
        var listeners: [Listener] = []
        var playback: [PlaybackManager.Playback] {
            didSet {
                self.playback.sort()
            }
        }
        var tracks: [Track] = [] {
            didSet {
                self.tracks.sort()
            }
        }
        
        // MARK: Initialisers
        init(details: SessionDetails, joinDetails: JoinDetails, tracks: [Track]) {
            self.details = details
            self.joinDetails = joinDetails
            self.tracks = tracks
            self.listeners = []
            self.playback = []
            
            self.addHostListeners()
        }
        
        func addHostListeners() {
            self.setupListenersListListener()
        }
        
        func addJoinerListeners() {
            self.setupTracksListener()
            self.setupListenersListListener()
            self.setupPlaybackListener()
        }
        
        func removeAllListeners(completion: () -> Void) {
            Firebase.firestore.removeListeners(with: self.details.sessionID, completion: completion)
        }
        
        // MARK: Listener Methods
        private func setupTracksListener() {
            Firebase.firestore.addSessionListener(sessionID: self.details.sessionID, collectionID: "Tracks") { (querySnapshot, error) in
                guard error == nil,
                      let docs = querySnapshot?.documents
                else { return }
                
                do {
                    let tracksOnServer = try docs.compactMap({ try Firestore.Decoder().decode(Track.self, from: $0.data()) })
                    
                    Firebase.firestore.fetchTrackListDetails(tracksOnServer) { (result) in
                        switch result {
                        case .success(let tracks):
                            self.tracks = tracks
                            
                            SessionManager.current.updateQueueReacter()
                        case .failure(_):
                            return
                        }
                    }
                } catch {
                    return
                }
            }
        }
        
        private func setupListenersListListener() {
            Firebase.firestore.addSessionListener(sessionID: self.details.sessionID, collectionID: "Listeners") { (querySnapshot, error) in
                guard error == nil,
                      let docs = querySnapshot?.documents
                else { return }
                
                do {
                    print("Listener Documents: \(docs)")
                    self.listeners = try docs.compactMap({ try Firestore.Decoder().decode(Listener.self, from: $0.data()) })
                    
                    SessionManager.current.sessionUpdateDelegate?.listenersUpdated()
                } catch let error {
                    print(error)
                    return
                }
            }
        }
        
        private func setupPlaybackListener() {
            Firebase.firestore.addSessionListener(sessionID: self.details.sessionID, collectionID: "Playback") { (querySnapshot, error) in
                guard error == nil,
                      let docs = querySnapshot?.documents
                else { return }
                
                do {
                    self.playback = try docs.compactMap({ try Firestore.Decoder().decode(PlaybackManager.Playback.self, from: $0.data()) })
                    
                    SessionManager.current.updatePlaybackStateReacter()
                } catch {
                    return
                }
            }
            
        }
        
        // MARK: Host Modifier Methods
        public func addPlaybackCommand(_ command: PlaybackManager.Playback) -> [PlaybackManager.Playback] {
            self.playback.append(command)
            
            return self.playback
        }
        
        public func addTrack(_ track: Track) -> [Track] {
            self.tracks.append(track)
            
            return self.tracks
        }
        
        public func removeTrack(_ track: Track) -> [Track] {
            self.tracks.removeAll(where: {$0 == track})
            
            return self.tracks
        }
        
        public func moveTrack(_ track: Track, position: Int) -> [Track] {
            self.tracks.remove(at: track.playbackIndex)
            self.tracks.insert(track, at: position)
            
            return self.tracks
        }
        
        // MARK: Codable
        internal enum CodingKeys: String, CodingKey {
            case details
            case joinDetails
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(self.details, forKey: .details)
            try container.encode(self.joinDetails, forKey: .joinDetails)
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.details = try container.decode(SessionDetails.self, forKey: .details)
            self.joinDetails = try container.decode(JoinDetails.self, forKey: .joinDetails)
            
            self.listeners = []
            self.tracks = []
            self.playback = []
            
            self.addJoinerListeners()
        }
        
        // MARK: Equatable
        static func == (lhs: SessionManager.Session, rhs: SessionManager.Session) -> Bool {
            return lhs.details.sessionID == rhs.details.sessionID
        }
    }
    
    struct PastSession: Codable {
        let details: SessionDetails
        let tracks: [Track]
        
        init(_ session: Session) {
            self.details = session.details
            self.tracks = session.tracks
        }
    }
    
    struct SessionDetails: Codable, Equatable {
        let sessionID: String
        let title: String
        let host: BasementProfile.UserDetails
        let startedAt: Date
//        @ExplicitNull private(set) var endedAt: Date?
        private(set) var endedAt: Date?
        
        mutating func addEndDate() {
            self.endedAt = Date()
        }
    }
    
    struct JoinDetails: Codable, Equatable {
        let visibility: SessionVisibility
        let code: String
    }
    
    struct Listener: Codable, Equatable {
        let userDetails: BasementProfile.UserDetails
    }
    
    struct Track: Codable, Comparable {
        let playbackIndex: Int
        let streamInformation: Music.Content
        
        static func < (lhs: SessionManager.Track, rhs: SessionManager.Track) -> Bool {
            return lhs.playbackIndex < rhs.playbackIndex
        }
    }
    
    struct TrackListModifier {
        let track: Track
        let modification: Modification
    }
    
    // MARK: Enums
    enum SessionVisibility: String, Codable {
        case `public`
        case byInvite
    }
    
    enum Modification: Equatable {
        case add
        case remove
        case move(index: Int)
    }
    
    // MARK: Reacter Methods
    // Called reacter methods because they react to incoming updates
    fileprivate func updateQueueReacter() {
        guard let tracks = self.activeSession?.tracks else { return }
        
        PlaybackManager.current.updateQueue(with: tracks) { (result) in
            switch result {
            case .success(let tracks):
                break
            case .failure(let error):
                break
            }
        }
    }
    
    fileprivate func updatePlaybackStateReacter() {
        guard let latestPlayback = self.activeSession?.playback.last else { return }
        
        PlaybackManager.current.updatePlaybackState(to: latestPlayback) { (_) in }
    }
    
    // MARK: Host Methods
    public func startSession(details: SessionDetails,
                             joinDetails: JoinDetails,
                             tracks: [Track],
                             completion: @escaping(Result<Session, Firebase.FirebaseError>) -> Void) {
        // Create Session Object
        let session = Session(details: details, joinDetails: joinDetails, tracks: tracks)
        
        // Upload to Firestore
        Firebase.firestore.startSession(session) { (result) in
            switch result {
            case .success(let serverSession):
                self.activeSession = serverSession
                
                let sessionStartDispatchGroup = DispatchGroup()
                var queueSet = false
                var playbackStateUploaded = false
                
                sessionStartDispatchGroup.enter()
                PlaybackManager.current.updateQueue(with: tracks) { (_) in
                    queueSet = true
                    sessionStartDispatchGroup.leave()
                }
                
                sessionStartDispatchGroup.enter()
                self.uploadPlaybackStateChange(command: .awaitStart) { (_) in
                    playbackStateUploaded = true
                    sessionStartDispatchGroup.leave()
                }
                
                sessionStartDispatchGroup.notify(queue: .global(qos: .userInitiated)) {
                    guard queueSet && playbackStateUploaded else { return }
                    completion(.success(serverSession))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func endSession(completion: @escaping(Result<PastSession, Firebase.FirebaseError>) -> Void) {
        guard let session = self.activeSession,
              let endPlaybackCommand = self.generatePlayback(from: .end)
            else { completion(.failure(.undefined)); return }
        
        // End Playback
        PlaybackManager.current.updatePlaybackState(to: endPlaybackCommand) { (_) in
            // Upload Playback State Change
            self.uploadPlaybackStateChange(command: .end) { (endPlaybackResult) in
                switch endPlaybackResult {
                case .success(_):
                    // Remove Listeners
                    session.removeAllListeners {
                        // Re-Upload with end date added
                        session.details.addEndDate()
                        
                        // Convert to Past Session
                        // Upload Past Session
                        Firebase.firestore.endSession(session, completion: completion)
                    }
                case .failure(_):
                    completion(.failure(.undefined))
                }
            }
        }
    }
    
    public func uploadPlaybackStateChange(command: PlaybackManager.PlaybackCommand,
                                   completion: @escaping(Result<[PlaybackManager.Playback], Firebase.FirebaseError>) -> Void) {
        guard let session = self.activeSession,
              let playback = self.generatePlayback(from: command)
        else { completion(.failure(.undefined)); return }
        
        // Update active session to have new playback state.
        let playbackList = session.addPlaybackCommand(playback)
        
        // Next update playback manager to update playback state
        PlaybackManager.current.updatePlaybackState(to: playback) { (success) in
            guard success else { completion(.failure(.undefined)); return }
            
            // Then update firestore with command
            Firebase.firestore.newPlaybackCommand(session: session, command: playback) { (result) in
                switch result {
                case .success(_):
                    completion(.success(playbackList))
                case .failure(_):
                    completion(.failure(.undefined))
                }
            }
        }
    }
    
    private func generatePlayback(from command: PlaybackManager.PlaybackCommand) -> PlaybackManager.Playback? {
        if command != .awaitStart {
            guard let currentTrack = PlaybackManager.current.nowPlaying else { return nil }
            let currentPlaybackPosition = PlaybackManager.current.playbackPosition
            
            let details = PlaybackManager.PlaybackDetails(trackIndex: currentTrack.playbackIndex, time: currentPlaybackPosition)
            
            return PlaybackManager.Playback(details: details, command: command, issuedAt: Date())
        } else {
            
            let details = PlaybackManager.PlaybackDetails(trackIndex: 0, time: 0)
            
            return PlaybackManager.Playback(details: details, command: command, issuedAt: Date())
        }
    }
    
    public func modifyTrackList(track: Track,
                                modification: Modification,
                                completion: @escaping(Result<[Track], Firebase.FirebaseError>) -> Void) {
        guard let session = self.activeSession  else { completion(.failure(.undefined)); return }
        let sessionID = session.details.sessionID
        
        let trackList: [Track] = {
            switch modification {
            case .add:
                return session.addTrack(track)
            case .remove:
                return session.removeTrack(track)
            case .move(index: let position):
                return session.moveTrack(track, position: position)
            }
        }()
        
        switch modification {
        case .add:
            Firebase.firestore.addTrack(track, sessionID: sessionID) { (success) in
                completion(success ? .success(trackList) : .failure(.undefined))
            }
        case .remove:
            Firebase.firestore.deleteTrack(track, sessionID: sessionID){ (success) in
                completion(success ? .success(trackList) : .failure(.undefined))
            }
        case .move(index: let position):
            Firebase.firestore.moveTrack(track, newPosition: position, sessionID: sessionID, completion: completion)
        }
    }
    
    // MARK: Join Methods
    public func joinSession(joinCode: String,
                            completion: @escaping(Result<Session, Firebase.FirebaseError>) -> Void) {
        // Leave any active session
        if self.activeSession != nil {
            self.leaveSession(session: &self.activeSession!, completion: { (_) in self.joinSession(joinCode: joinCode, completion: completion) })
            return
        }
        
        // Match join code to session
        // Add user to session listener list
        // Start listening to updates
        Firebase.firestore.joinSession(code: joinCode) { (result) in
            switch result {
            case .success(let session):
                self.activeSession = session
                
                // Update Queue
                PlaybackManager.current.updateQueue(with: session.tracks) { (_) in
                    guard let lastPlaybackCommand = session.playback.last else { completion(.failure(.undefined)); return }
                    
                    // TODO: Synchronise Playback
                    PlaybackManager.current.synchronisePlayback { (success) in
                        guard success else { completion(.failure(.undefined)); return }
                        
                        // Update Player's State
                        PlaybackManager.current.updatePlaybackState(to: lastPlaybackCommand) { (success) in
                            guard success else { completion(.failure(.undefined)); return }
                            
                            completion(.success(session))
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func leaveSession(session: inout Session,
                             completion: @escaping(Result<Session, Firebase.FirebaseError>) -> Void) {
        // TODO - End Playback
        
        // Stop listener updates
        session.removeAllListeners {
            // Remove user from session listener list
            Firebase.firestore.leaveSession(session) { (result) in
                switch result {
                case .success(let session):
                    // TODO - Clear Track List
                    
                    self.activeSession = nil
                    
                    completion(.success(session))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
}

protocol SessionUpdateDelegate {
    
    func listenersUpdated()
    
}
