//
//  SessionManager.swift
//  Basement
//
//  Created by George Nick Gorzynski on 13/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import Foundation

protocol SessionUpdateDelegate {
	
	func didStartSessionSetup()
	func queueDidChangeInSetup()
	func didInitialiseSession()
	
	func didJoinSession()
	func sessionUpdate(isHost: Bool)
	
}

class SessionManager {
    
    // MARK: Static Instance
    static let current = SessionManager()
    
    // MARK: Initialiser
    init() {
		Firebase.shared.sessionListenerUpdateDelegate = self
	}
    
    // MARK: Properties
	public var sessionUpdateDelegate: SessionUpdateDelegate? = nil
    private(set) var setup: Setup? = nil
	private(set) var session: MusicSession? = nil
    private(set) var sessionHistory: [MusicSession] = []
    
    // MARK: Classes
    class Setup: Equatable {
        
        // MARK: Properties
        private(set) var content: [Music.Content]
        private(set) var privacy: MusicSession.Privacy
        private(set) var friendsToNotify: [Firebase.UserProfile]
        
        // MARK: Initialiser
        init() {
            self.content = []
            self.privacy = .public
            self.friendsToNotify = []
        }
        
        // MARK: Update Methods
        @discardableResult
        func addContent(_ contentToAdd: [Music.Content]) -> [Music.Content] {
            self.content.append(contentsOf: contentToAdd)
            
            return self.content
        }
        
        @discardableResult
		func removeContent(_ contentToRemove: [Music.Content]) -> [Music.Content] {
			for contentItem in contentToRemove {
				if self.content.contains(contentItem) {
					guard let indexOfContent = self.content.firstIndex(where: {$0 == contentItem}) else { continue }
					
					self.content.remove(at: indexOfContent)
				}
			}
            
            return self.content
        }
		
		@discardableResult
		func removeIndexOfContent(_ index: Int) -> [Music.Content] {
			self.content.remove(at: index)
			
			return self.content
		}
        
        func updatePrivacy(to privacy: MusicSession.Privacy) {
            self.privacy = privacy
        }
        
        @discardableResult
        func addFriends(_ friendsToAdd: [Firebase.UserProfile]) -> [Firebase.UserProfile] {
            self.friendsToNotify.append(contentsOf: friendsToAdd)
            
            return self.friendsToNotify
        }
        
        // MARK: Equatable
        static func == (lhs: SessionManager.Setup, rhs: SessionManager.Setup) -> Bool {
            return lhs.content == rhs.content && lhs.privacy == rhs.privacy
        }
        
    }
    
    public class MusicSession: Codable, Comparable {
        
        // MARK: Properties
        private(set) var details: MusicSession.Details
        private(set) var content: [Music.Content]
		private(set) var playback: MusicSession.PlaybackDetails
        private(set) var listeners: [MusicSession.Listener]
		
		public var isHost: Bool {
			get {
                return self.details.host.information.identifier == Firebase.shared.currentUserIdentifier ?? ""
			}
		}
        
        // MARK: Initialiser
        init(details: MusicSession.Details, content: [Music.Content] = []) {
            self.details = details
			self.content = content
			self.playback = MusicSession.PlaybackDetails(events: [PlaybackDetails.Event(state: .pause)])
            self.listeners = []
        }
        
        init(from setup: Setup) {
            guard let hostID = Firebase.shared.currentUserIdentifier else { fatalError() }
            self.details = MusicSession.Details(privacy: setup.privacy, hostIdentifier: hostID)
            self.content = setup.content
            self.playback = MusicSession.PlaybackDetails(events: [PlaybackDetails.Event(state: .pause)])
            self.listeners = []
        }
        
        class Details: Codable, Equatable {
            let identifier: String
            let privacy: MusicSession.Privacy
            let startDate: Date
            let endDate: Date?
            private(set) var host: Firebase.UserProfile
            
            init(privacy: MusicSession.Privacy, hostIdentifier: String) {
				self.identifier = (UUID().uuidString + "|\(hostIdentifier)|" + UUID().uuidString)
                self.privacy = privacy
                self.startDate = Date()
                self.endDate = nil
                
                let hostDetails = Firebase.UserInformation(identifier: hostIdentifier, username: "", name: "")
                self.host = Firebase.UserProfile(information: hostDetails, friends: [])
                
                self.hostProfile()
            }
            
            static func == (lhs: SessionManager.MusicSession.Details, rhs: SessionManager.MusicSession.Details) -> Bool {
                return lhs.identifier == rhs.identifier
            }
            
            func hostProfile(completion: ((Firebase.UserProfile?) -> Void)? = nil) {
                if self.host.information.name.isEmpty && self.host.information.username.isEmpty { completion?(self.host); return }
                
                Firebase.shared.fetchUser(with: self.host.information.identifier) { (result) in
                    switch result {
                    case .success(let userProfile):
                        self.host = userProfile
                        completion?(userProfile)
                    default:
                        completion?(nil)
                    }
                }
            }
        }
        
        struct Listener: Codable, Equatable {
            let userInformation: Firebase.UserInformation
            let platform: StreamingPlatform
        }
		
		struct PlaybackDetails: Codable {
			var events: [Event] = []
			
			struct Event: Codable {
				let state: PlaybackManager.PlaybackCommand
				let date: Date
				
				init(state: PlaybackManager.PlaybackCommand) {
					self.state = state
					self.date = Date()
				}
			}
		}
        
        enum Privacy: String, Codable, Equatable {
			case `public`
            case friends
            case inviteOnly
            case party
        }
        
        // MARK: Update Methods
        @discardableResult
        func updateListeners(with listeners: [MusicSession.Listener]) -> [MusicSession.Listener] {
            self.listeners = listeners
            
            return self.listeners
        }
        
        @discardableResult
        func updateContent(with content: [Music.Content]) -> [Music.Content] {
            self.content = content
            
            return self.content
        }
        
        @discardableResult
        func addContent(_ newContent: [Music.Content]) -> [Music.Content] {
			newContent.forEach({self.content.append($0)})
            
            return self.content
        }
        
        @discardableResult
        func updatePlayback(with details: MusicSession.PlaybackDetails) -> MusicSession.PlaybackDetails {
            self.playback = details
            
            return self.playback
        }
        
        @discardableResult
		func newPlaybackEvent(from state: PlaybackManager.PlaybackCommand) -> MusicSession.PlaybackDetails {
			let newEvent = PlaybackDetails.Event(state: state)
			self.playback.events.append(newEvent)
			
            return self.playback
        }
        
        // MARK: Comparable
        static func == (lhs: SessionManager.MusicSession, rhs: SessionManager.MusicSession) -> Bool {
            return lhs.details.identifier == rhs.details.identifier
        }
        
        static func < (lhs: SessionManager.MusicSession, rhs: SessionManager.MusicSession) -> Bool {
			let failableDate = Date()
			return lhs.playback.events.last?.date ?? failableDate < rhs.playback.events.last?.date ?? failableDate
        }
        
        // MARK: Codable
        private enum CodingKeys: String, CodingKey {
            case details, content, playback
        }
        
        // MARK: Decodable
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.details = try container.decode(MusicSession.Details.self, forKey: .details)
            self.content = try container.decode([Music.Song].self, forKey: .content)
            self.playback = try container.decode(MusicSession.PlaybackDetails.self, forKey: .playback)
            self.listeners = []
        }
		
		// MARK: Encodable
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			
			try container.encode(self.details, forKey: .details)
			try container.encode(self.content as! [Music.Song], forKey: .content)
			try container.encode(self.playback, forKey: .playback)
		}
    }
    
    // MARK: - History
    public class HistoricalSession: Codable {
        let details: MusicSession.Details
        let content: [Music.Content]
        
        init(details: MusicSession.Details, content: [Music.Content]) {
            self.details = details
            self.content = content
        }
    }
    
    public func fetchHistory(for userID: String, completion: @escaping(Result<[SessionManager.MusicSession], SessionManager.SessionError>) -> Void) {
        Firebase.shared.fetchUserSessions(for: userID) { (result) in
            switch result {
            case .success(let sessions):
                if userID == Firebase.shared.currentUserIdentifier {
                    self.sessionHistory = sessions
                }
                
                completion(.success(sessions))
            case .failure(_):
                completion(.failure(.unknownError))
            }
        }
    }
    
    // MARK: - Current
    
    // MARK: Fetch Methods
	public func joinSession(from details: MusicSession.Details, completion: @escaping(Result<MusicSession, SessionError>) -> Void) {
        guard details.host.information.identifier != Firebase.shared.currentUserIdentifier else { completion(.failure(.unableToConnect)); return }
		
		// Fetch and subscribe to session
		Firebase.shared.joinSession(sessionID: details.identifier) { (result) in
			switch result {
			case .success(let session):
				self.session = session
				self.sessionUpdateDelegate?.didJoinSession()
				
				completion(.success(session))
			case .failure(_):
				completion(.failure(.unknownError))
			}
		}
	}
	
	public func leaveSession(_ session: MusicSession, completion: ((Result<MusicSession, SessionError>) -> Void)? = nil) {
		Firebase.shared.leaveSession(session) { (result) in
			switch result {
			case .success(let session):
				completion?(.success(session))
			case .failure(_):
				completion?(.failure(.unknownError))
			}
		}
	}
    
    // MARK: Update Methods
    public func setupSession(from content: [Music.Content] = []) {
        if self.setup == nil {
            self.setup = Setup()
			self.sessionUpdateDelegate?.didStartSessionSetup()
        }
        
		self.addContentToSetup(content)
    }
	
	public func addContentToSetup(_ content: [Music.Content] = []) {
		self.setup?.addContent(content)
        
        self.sessionUpdateDelegate?.queueDidChangeInSetup()
	}
    
    public func createSession(from details: MusicSession.Details? = nil, content: [Music.Content]? = nil, users: [Firebase.UserProfile]? = nil, completion: ((Result<MusicSession, SessionError>) -> Void)? = nil) {
        var session: MusicSession? {
            if content == nil && users == nil && details == nil {
                guard let setup = self.setup else { return nil }
                return MusicSession(from: setup)
            } else {
                guard let content = content, let details = details else { return nil }
                return MusicSession(details: details, content: content)
            }
        }
        
        guard let newSession = session else { completion?(.failure(.couldNotInitialise)); return }
        
        // Create a new session in the sessions collection in firestore, including the content to play
        self.initialiseSession(newSession) { (result) in
            switch result {
            case .success(let responseSession):
				print("[SessionManager] Successfully initialised a new session: \(responseSession.details.identifier)")
                print("                 Song IDs for session: \(responseSession.content.map({$0.streamingInformation.identifier}))")
				
				// Change from setup to session
				self.session = responseSession
				self.setup = nil
                
                // Send notifications to selected friends about this session
				completion?(.success(responseSession))
            case .failure(let error):
                completion?(.failure(error))
                return
            }
        }
    }
    
	public func initialiseSession(_ session: MusicSession, completion: @escaping(Result<MusicSession, SessionError>) -> Void) {
		Firebase.shared.newSession(from: session) { (result) in
			switch result {
			case .success(let receivedSession):
				// Notify PlaybackManager about new playback content
				PlaybackManager.current.sessionUpdated(receivedSession)
				self.sessionUpdateDelegate?.didInitialiseSession()
				
				// Complete
				completion(.success(receivedSession))
			case .failure(_):
				completion(.failure(.couldNotInitialise))
			}
		}
    }
	
	public func updateSession(_ session: MusicSession, completion: ((Result<MusicSession, SessionError>) -> Void)? = nil) {
		Firebase.shared.updateSession(session) { (result) in
			switch result {
			case .success(let receivedSession):
				completion?(.success(receivedSession))
			case .failure(_):
				completion?(.failure(.couldNotInitialise))
			}
		}
	}
	
//	public func addToSession(_ content: [Music.Content], completion: ((Bool) -> Void)? = nil) {
//		// Setup session if setup and session are both nil in `SessionManager`
//		if SessionManager.current.setup == nil && SessionManager.current.session == nil {
//			SessionManager.current.setupSession()
//		}
//
//		if SessionManager.current.setup != nil && SessionManager.current.session == nil {
//			// Add to setup
//			if let setup = SessionManager.current.setup, setup.content.hasCommonElements(content) {
//				// Inform user content is already in stream, and whether they'd like to add anyway, ignore duplicates, or cancel
//
//				let duplicateAlert = UIAlertController(title: "Some content is already part of your session", message: "What would you like to do?", preferredStyle: .alert)
//
//				let addAnyway = UIAlertAction(title: "Add Anyway", style: .default) { (alert) in
//					SessionManager.current.addContentToSetup(content)
//					completion?(true)
//				}
//
//				let ignoreDuplicates = UIAlertAction(title: "Ignore Duplicates", style: .default) { (alert) in
//					var contentToAdd = content
//					contentToAdd.removeAll(where: {setup.content.contains($0)})
//
//					SessionManager.current.addContentToSetup(contentToAdd)
//					completion?(true)
//				}
//
//				let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//
//				duplicateAlert.addAction(addAnyway)
//				duplicateAlert.addAction(ignoreDuplicates)
//				duplicateAlert.addAction(cancel)
//
//				self.present(duplicateAlert, animated: true, completion: nil)
//			} else {
//				SessionManager.current.addContentToSetup(content)
//				completion?(true)
//			}
//		} else {
//			// Add to current session
//			SessionManager.current.session?.addContent(content)
//
//			if let currentSession = SessionManager.current.session {
//				SessionManager.current.updateSession(currentSession) { (result) in
//					switch result {
//					case .success(_):
//						completion?(true)
//						break
//						// Show user a notification that content has been added
//					case .failure(_):
//						completion?(false)
//						break
//						// Show user a notification that content has not been added due to failure
//					}
//				}
//			}
//		}
//	}
	
	// MARK: - Playback Update Methods
	public func updateSessionPlaybackState(to state: PlaybackManager.PlaybackCommand, completion: ((Result<MusicSession, SessionError>) -> Void)? = nil) {
        guard let currentSession = self.session else { completion?(.failure(.updateFailed)); return }
		
        currentSession.newPlaybackEvent(from: state)
        print("[SessionManager] A new playback command has been issued by you (the host) - \(String(describing: currentSession.playback.events.last))")
		self.updateSession(currentSession) { (result) in
			switch result {
			case .success(let session):
                completion?(.success(session))
			case .failure(_):
                completion?(.failure(.updateFailed))
			}
		}
	}
    
    // MARK: Errors
    enum SessionError: Error {
		case unknownError
		
        case noConnection
        case failedToStart
        case couldNotInitialise
		case unableToConnect
        case updateFailed
    }
    
}

extension SessionManager: SessionUpdateBroadcaster {
	
	func update(for sessionID: String, update: MusicSession) {
		if let currentSession = self.session {
			guard currentSession.details.identifier == sessionID else { fatalError("Current session (ID: \(currentSession.details.identifier), HostID: \(currentSession.details.host) is in progress and update is trying to replace with inactive session: (ID: \(sessionID), HostID: \(update.details.host)). If this session was previously running, please ensure listener is removed.") }
		}
		
		self.session = update
		self.sessionUpdateDelegate?.sessionUpdate(isHost: update.isHost)
	}
	
}
