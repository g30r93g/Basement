//
//  StreamingPlatform.swift
//  Basement
//
//  Created by George Nick Gorzynski on 22/10/2020.
//

import Foundation

class StreamingPlatform {
    
    // MARK: Static Instances
    static let appleMusic = AppleMusic()
    //    static let spotify = Spotify()
    
    // MARK: Initialisers
    init() { }
    
    // MARK: Properties
    private var authorizedPlatform: Platforms? = .appleMusic
    private var platformMatcher = PlatformMatcher()
    
    // MARK: Enums
    enum Platforms: String, Codable {
        case appleMusic = "appleMusic"
        //        case spotify
    }
    
    enum PlatformAuthError: Error {
        case undefined
        
        case noSubscription
        case invalidPermissions
    }
    
    enum StreamingError: Error {
        case undefined
    }
    
    // MARK: Authorization Methods
    public func authorize(for platform: Platforms, completion: @escaping(Result<BasementProfile.ConnectedService, PlatformAuthError>) -> Void) {
        switch platform {
        case .appleMusic:
            StreamingPlatform.appleMusic.authorizeUser() { (success) in
                if success != nil {
                    self.authorizedPlatform = .appleMusic
                    completion(.success(BasementProfile.ConnectedService(platform: .appleMusic, username: "")))
                } else {
                    self.authorizedPlatform = nil
                    completion(.failure(.undefined))
                }
            }
        }
    }
    
    // MARK: Playback Methods
    public func currentPlaybackPosition() -> Result<Int, StreamingError> {
        guard let platform = self.authorizedPlatform else { return .failure(.undefined) }
        
        switch platform {
        case .appleMusic:
            guard let player = StreamingPlatform.appleMusic.amber?.player else { return .failure(.undefined) }
            let currentPlaybackPosition = Int(player.controller.currentPlaybackTime)
            
            return .success(currentPlaybackPosition * 1000)
        }
    }
    
    public func nowPlaying() -> Result<String, StreamingError> {
        guard let platform = self.authorizedPlatform else { return .failure(.undefined) }
        
        switch platform {
        case .appleMusic:
            if let currentlyPlayingID = StreamingPlatform.appleMusic.amber?.player.currentlyPlaying {
                return .success(currentlyPlayingID)
            } else {
                return .failure(.undefined)
            }
        }
    }
    
    public func queue() -> Result<[String], StreamingError> {
        guard let platform = self.authorizedPlatform else { return .failure(.undefined) }
        
        switch platform {
        case .appleMusic:
            if let upcomingTrackIDs = StreamingPlatform.appleMusic.amber?.player.upcomingTracks {
                return .success(upcomingTrackIDs)
            } else {
                return .failure(.undefined)
            }
        }
    }
    
    public func updateQueue(tracks: [SessionManager.Track], completion: @escaping(Result<[SessionManager.Track], StreamingError>) -> Void) {
        guard let platform = self.authorizedPlatform else { completion(.failure(.undefined)); return }
        
        switch platform {
        case .appleMusic:
            StreamingPlatform.appleMusic.updateQueue(with: tracks) { (success) in
                if success {
                    completion(.success(tracks))
                } else {
                    completion(.failure(.undefined))
                }
            }
        }
    }
    
    public func updatePlaybackState(from playback: PlaybackManager.Playback, completion: @escaping(Result<PlaybackManager.PlaybackCommand, StreamingError>) -> Void) {
        guard let platform = self.authorizedPlatform else { completion(.failure(.undefined)); return }
        
        // Update player state
        switch platform {
        case .appleMusic:
            // Update Playback State
            StreamingPlatform.appleMusic.updatePlaybackState(state: playback.command) { (command) in
                if let command = command {
                    completion(.success(command))
                } else {
                    completion(.failure(.undefined))
                }
            }
        }
    }
    
    public func synchronisePlayback(completion: @escaping(Result<Bool, StreamingError>) -> Void) {
        guard let platform = self.authorizedPlatform else { completion(.failure(.undefined)); return }
        
        switch platform {
        case .appleMusic:
            StreamingPlatform.appleMusic.synchronisePlayback() { (success) in
                if success {
                    completion(.success(success))
                } else {
                    completion(.failure(.undefined))
                }
            }
        }
    }
    
    // MARK: Content Methods
    public func search(text: String, completion: @escaping(Result<[Music.Content], StreamingError>) -> Void) {
        guard let platform = self.authorizedPlatform else { completion(.failure(.undefined)); return }
        
        switch platform {
        case .appleMusic:
            StreamingPlatform.appleMusic.search(text: text) { (content) in
                if let content = content {
                    completion(.success(content))
                } else {
                    completion(.failure(.undefined))
                }
            }
        }
    }
    
    public func fetchTrack(platform: Platforms, identifier: String, completion: @escaping(Result<Music.Song, StreamingError>) -> Void) {
        switch platform {
        case .appleMusic:
            StreamingPlatform.appleMusic.fetchSong(identifier: identifier) { (song) in
                if let track = song {
                    completion(.success(track))
                } else {
                    completion(.failure(.undefined))
                }
            }
        }
    }
    
}
