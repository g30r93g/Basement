//
//  VibeManager.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 13/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import Foundation
import FirebaseFirestore

class VibeManager {
    
    // MARK: Static Instance
    static let current = VibeManager()
    
    // MARK: Initialiser
    init() { }
    
    // MARK: Properties
    private(set) var currentVibe: Vibe? = nil
    private(set) var currentVibeSetup: VibeSetup? = nil
    
    // MARK: Classes
    class VibeSetup: Equatable {
        
        // MARK: Properties
        private(set) var content: [Music.Content]
        private(set) var privacy: Vibe.Privacy
        private(set) var friendsToNotify: [Firebase.UserProfile]
        
        // MARK: Initialiser
        init() {
            self.content = []
            self.privacy = .Public
            self.friendsToNotify = []
        }
        
        // MARK: Update Methods
        @discardableResult
        func addContent(_ contentToAdd: [Music.Content]) -> [Music.Content] {
            self.content.append(contentsOf: contentToAdd)
            updateMiniPlayerView()
            
            return self.content
        }
        
        @discardableResult
        func removeContent(_ contentToRemove: [Music.Content]) -> [Music.Content] {
            self.content.removeAll(where: {contentToRemove.contains($0)})
            
            return self.content
        }
        
        func updatePrivacy(to privacy: Vibe.Privacy) {
            self.privacy = privacy
        }
        
        @discardableResult
        func addFriends(_ friendsToAdd: [Firebase.UserProfile]) -> [Firebase.UserProfile] {
            self.friendsToNotify.append(contentsOf: friendsToAdd)
            updateMiniPlayerView()
            
            return self.friendsToNotify
        }
        
        // MARK: Equatable
        static func == (lhs: VibeManager.VibeSetup, rhs: VibeManager.VibeSetup) -> Bool {
            return lhs.content == rhs.content && lhs.privacy == rhs.privacy
        }
        
    }
    
    class Vibe: Codable, Comparable {
        
        // MARK: Properties
        private(set) var details: Vibe.Details
        private(set) var content: [Music.Content]
        private(set) var playback: [Music.PlaybackDetails]
        private(set) var listeners: [Vibe.Listener]
        
        // MARK: Initialiser
        init(details: Vibe.Details, content: [Music.Content] = []) {
            self.details = details
            self.content = content
            self.playback = []
            self.listeners = []
        }
        
        init(from setup: VibeSetup) {
            guard let hostID = Firebase.shared.currentUser?.profile.identifier else { fatalError() }
            self.details = Vibe.Details(privacy: setup.privacy, hostIdentifier: hostID)
            self.content = setup.content
            self.playback = []
            self.listeners = []
        }
        
        class Details: Codable, Equatable {
            let identifier: String
            let privacy: Vibe.Privacy
            let host: DocumentReference
            let startDate: Date?
            
            init(privacy: Vibe.Privacy, hostIdentifier: String, startDate: Date? = nil) {
                self.identifier = UUID().uuidString
                self.privacy = privacy
                self.host = Firestore.firestore().collection("Profiles").document(hostIdentifier)
                self.startDate = nil
            }
            
            static func == (lhs: VibeManager.Vibe.Details, rhs: VibeManager.Vibe.Details) -> Bool {
                return lhs.identifier == rhs.identifier
            }
        }
        
        struct Listener: Codable, Equatable {
            let profile: DocumentReference
            let platform: StreamingPlatform
        }
        
        enum Privacy: String, Codable, Equatable {
            case Public
            case Friends
            case InviteOnly
            case Party
        }
        
        // MARK: Update Methods
        @discardableResult
        func updateListeners(with listeners: [Vibe.Listener]) -> [Vibe.Listener] {
            self.listeners = listeners
            
            return self.listeners
        }
        
        @discardableResult
        func updateContent(with content: [Music.Content]) -> [Music.Content] {
            self.content = content
            
            return self.content
        }
        
        @discardableResult
        func updatePlayback(with playbackDetails: [Music.PlaybackDetails]) -> [Music.PlaybackDetails] {
            self.playback = playbackDetails
            
            return self.playback
        }
        
        // MARK: Comparable
        static func == (lhs: VibeManager.Vibe, rhs: VibeManager.Vibe) -> Bool {
            return lhs.details.identifier == rhs.details.identifier
        }
        
        static func < (lhs: VibeManager.Vibe, rhs: VibeManager.Vibe) -> Bool {
            return lhs.details.startDate ?? Date() < rhs.details.startDate ?? Date()
        }
    }
    
    
    // MARK: Fetch Methods
    
    // MARK: Update Methods
    public func setupVibe(from content: [Music.Content]) {
        if self.currentVibeSetup == nil {
            self.currentVibeSetup = VibeSetup()
        }
        
        self.currentVibeSetup?.addContent(content)
        updateMiniPlayerView()
    }
    
    public func createVibe(from details: Vibe.Details? = nil, content: [Music.Content]? = nil, users: [Firebase.UserProfile]? = nil, completion: ((Result<Vibe, VibeError>) -> Void)? = nil) {
        var vibe: Vibe? {
            if content == nil && users == nil && details == nil {
                guard let setup = self.currentVibeSetup else { return nil }
                return Vibe(from: setup)
            } else {
                guard let content = content, let details = details else { return nil }
                return Vibe(details: details, content: content)
            }
        }
        
        guard let newVibe = vibe else { completion?(.failure(.couldNotInitialise)); return }
        
        // Create a new vibe in the vibe collection in firestore, including the content to play
        self.startVibe(newVibe) { (success) in
            
        }
        
        
        // Add the vibe identifier to the users vibeHistory and set the currentVibe as a reference to the new vibe
        
        // Send a request to firebase functions to send a push notification to the users specified to invite or notify that a vibe from this user has started
        
        // Apply an events notification handler to update when document changes
        
        // Once complete, perform completion handler
        completion?(.failure(.failedToStart))
        updateMiniPlayerView()
    }
    
    public func startVibe(_ vibeToStart: Vibe, completion: @escaping(Bool) -> Void) {
        Firebase.shared.startVibe(vibeToStart) { (success) in
            if success {
                self.currentVibe = vibeToStart
                self.start()
                
                updateMiniPlayerView()
            }
            
            completion(success)
        }
    }
    
    private func start() {
        updateMiniPlayerView()
    }
    
    private func pause() {
        updateMiniPlayerView()
    }
    
    private func cancel() {
        self.currentVibe = nil
        updateMiniPlayerView()
    }
    
    
    // MARK: Errors
    enum VibeError: Error {
        case noConnection
        case failedToStart
        case couldNotInitialise
    }
    
}

fileprivate func updateMiniPlayerView() {
    NotificationCenter.default.post(Notification(name: .requestMiniPlayerUpdate))
}
