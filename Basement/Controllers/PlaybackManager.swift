//
//  PlaybackManager.swift
//  Basement
//
//  Created by George Nick Gorzynski on 06/07/2020.
//

import Amber
import Foundation
import MediaPlayer

protocol MiniPlayerDelegate {
    func playbackStateUpdated(to state: PlaybackManager.State)
}

protocol PlaybackUpdateRequestDelegate {
    func sendPlaybackCommand(_ command: PlaybackManager.PlaybackCommand)
}

class PlaybackManager {
    
    // MARK: Static Instance
    static let current = PlaybackManager()
    
    // MARK: Properties
    private(set) var playback = CurrentPlayback()
    var miniPlayerDelegate: MiniPlayerDelegate? = nil
    
    // MARK: Initialisers
    init() {
        self.setupNowPlayingRemoteCommands()
    }
    
    // MARK: Error Enums
    public enum PlaybackError: Error {
        case unknownError
        
        case failedToCommunicate
        case failedToIdentifyPlatform
    }
    
    // MARK: Enums
    enum State: String, Codable {
        case notStarted, paused, playing, ended
    }
    
    enum PlaybackCommand: Codable, Equatable {
        case play, pause, stop
        case restart, previous, next
        case skip(Int)
        
        init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer().decode(String.self)
            
            switch value {
            case "play":
                self = .play
            case "pause":
                self = .pause
            case "stop":
                self = .stop
            case "restart":
                self = .restart
            case "previous":
                self = .previous
            case "next":
                self = .next
            default:
                if value.contains("skip-") {
                    guard let valueIndex = value.firstIndex(of: "-"),
                          let value = Int(value[valueIndex..<value.endIndex].replacingOccurrences(of: "-", with: ""))
                    else { throw Firebase.FirebaseError.unknownError }
                    
                    self = .skip(value)
                    return
                }
                
                throw Firebase.FirebaseError.unknownError
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
            case .play:
                try container.encode("play")
            case .pause:
                try container.encode("pause")
            case .stop:
                try container.encode("stop")
            case .restart:
                try container.encode("restart")
            case .previous:
                try container.encode("previous")
            case .next:
                try container.encode("next")
            case .skip(let amount):
                try container.encode("skip-\(amount)")
            }
        }
    }
    
    // MARK: Classes
    class CurrentPlayback {
        // MARK: Properties
        var state: PlaybackManager.State
        var content: [Music.Song] = [] {
            didSet {
                // TODO: ONLY WORKS FOR APPLE MUSIC, UPDATE FOR CROSS PLATFORM AVAILABILITY
//                self.content.forEach({.addToQueue($0.streamingInformation.identifier)})
                AppleMusicAPI.currentSession.amber?.player.setQueue(with: self.content.map({$0.streamingInformation.identifier}))
            }
        }
        var currentSong: Music.Song? {
            get {
                guard !self.content.isEmpty else { return nil }
                
                // Determines which song we're on based on playback events
                let playbackEvents = SessionManager.current.session?.playback.events ?? []
                let numberOfSkipsForward = playbackEvents.reduce(0, {$0 + ($1.state == .next ? 1 : 0)})
                let numberOfSkipsBackward = playbackEvents.reduce(0, {$0 + ($1.state == .previous ? 1 : 0)})
                
                self.currentSongIndex = numberOfSkipsForward - numberOfSkipsBackward
                if self.currentSongIndex < 0 { self.currentSongIndex = 0 }
                
                return self.content.retrieve(index: self.currentSongIndex)
            }
        }
        private var currentSongIndex: Array<Music.Song>.Index = -1
        /// Runtime in milliseconds
        var runtime: Int {
            get {
                guard let currentSong = self.currentSong else { return -1 }
                
                switch currentSong.streamingInformation.platform {
                case .appleMusic:
                    return AppleMusicAPI.currentSession.amber?.player.player.currentPlaybackTime.milliseconds ?? -1
                case .spotify:
//                    SpotifyAPI.currentSession.appRemote.playerAPI?.getPlayerState({ (state, error) in
//                        if error != nil {
//                            return -1
//                        }
//
//                        guard let state = state as? SPTAppRemotePlayerState else { return -1 }
//
//                        return state.playbackPosition
//                    })
                    return -1
                default:
                    return -1
                }
            }
        }
        
        // MARK: Initialisers
        init(state: PlaybackManager.State = .notStarted) {
            self.state = state
        }
        
        // MARK: Methods
        public func history() -> [Music.Song] {
            guard self.currentSongIndex >= 0 && self.currentSongIndex < self.content.endIndex else { return [] }
            return Array(self.content[0..<currentSongIndex])
        }
        
        public func playingNext() -> [Music.Song] {
            guard self.currentSongIndex >= 0 && self.currentSongIndex < self.content.endIndex else { return self.content }
            return Array(self.content[currentSongIndex..<self.content.endIndex])
        }
        
        internal func updateState(to state: PlaybackManager.State) {
            self.state = state
        }
        
        internal func updateQueue(with newQueue: [Music.Song]) {
            if newQueue.isEmpty { self.content.removeAll(); self.currentSongIndex = -1; return }
            if self.content.isEmpty { self.content = newQueue; self.currentSongIndex = 0 }
            
            guard let currentSong = self.currentSong else { return }
            guard let newCurrentSongIndex = newQueue.firstIndex(of: currentSong) else { return }
            
            self.content = newQueue
            self.currentSongIndex = newCurrentSongIndex
        }
        
        @discardableResult
        public func changeSong(to requestedSong: Music.Song) -> Music.Song? {
            // Check song exists in queue
            guard let queue = SessionManager.current.session?.content,
                  queue.contains(requestedSong)
            else { return nil }
                  
            // Fetch first matching index
            guard let firstMatchingIndex = queue.firstIndex(of: requestedSong) else { return nil }
            
            // Update Queued Song
            if let queuedSong = queue.retrieve(index: self.currentSongIndex) as? Music.Song {
                self.currentSongIndex = firstMatchingIndex
                return queuedSong
            } else {
                return nil
            }
        }
        
        @discardableResult
        public func previousTrack() -> [Music.Song] {
            let queue = self.content
            let previousSongIndex = self.currentSongIndex - 1
            
            if queue.hasIndex(previousSongIndex) {
                self.currentSongIndex = previousSongIndex
            } else {
                fatalError("Pointer \(previousSongIndex) is outside bounds of queue")
            }
            
            return self.playingNext()
        }
        
        @discardableResult
        public func nextTrack() -> [Music.Song] {
            let queue = self.content
            let nextSongIndex = self.currentSongIndex + 1
            
            if queue.hasIndex(nextSongIndex) {
                self.currentSongIndex = nextSongIndex
            } else {
                fatalError("Pointer \(nextSongIndex) is outside bounds of queue")
            }
            
            return self.playingNext()
        }
    }
    
    // MARK: Update Methods
    /// This should probably be in SessionManager
    public func sessionUpdated(_ session: SessionManager.MusicSession) {
        guard let newQueue = session.content as? [Music.Song] else { return }
        guard let sessionState = session.playback.events.last?.state else { return }
        
        self.playback.updateQueue(with: newQueue)
        
        // Switch Session
        switch sessionState {
        case .play, .previous, .next, .restart:
            self.playback.updateState(to: .playing)
            self.miniPlayerDelegate?.playbackStateUpdated(to: .playing)
        case .pause:
            self.playback.updateState(to: .paused)
            self.miniPlayerDelegate?.playbackStateUpdated(to: .paused)
        case .stop:
            self.playback.updateState(to: .ended)
            self.miniPlayerDelegate?.playbackStateUpdated(to: .ended)
        default:
            break
        }
    }
    
    // MARK: Playback Methods
    public func performPlaybackCommand(_ command: PlaybackCommand, completion: ((Result<CurrentPlayback, PlaybackError>) -> Void)? = nil) {
        self.updateMediaPlayback(command) { (result) in
            switch result {
            case .success(_):
                print("[PlaybackManager] Successfully performed playback command. Updating session for listeners...")
                SessionManager.current.updateSessionPlaybackState(to: command) { (result) in
                    switch result {
                    case .success(_):
                        print("[PlaybackManager] Listeners have been notified of session update.")
                        completion?(.success(self.playback))
                    case .failure(_):
                        print("[PlaybackManager] Listeners have not been notified of session update.")
                        completion?(.failure(.failedToCommunicate))
                    }
                }
            case .failure(let error):
                print("[PlaybackManager] Failed to perform playback command.")
                completion?(.failure(error))
            }
        }
    }
    
    private func updateMediaPlayback(_ command: PlaybackCommand, completion: @escaping(Result<Bool, PlaybackError>) -> Void) {
        guard let currentSong = self.playback.currentSong else { return }
        let streamingPlatform = currentSong.streamingInformation.platform
        
        switch streamingPlatform {
        case .appleMusic:
            guard let appleMusicPlayer = AppleMusicAPI.currentSession.amber?.player else { fatalError() }
            switch command {
            case .play:
                appleMusicPlayer.play()
                self.playback.updateState(to: .playing)
                completion(.success(true))
            case .pause:
                appleMusicPlayer.pause()
                self.playback.updateState(to: .paused)
                completion(.success(true))
            case .stop:
                appleMusicPlayer.stop()
                self.playback.updateState(to: .ended)
                completion(.success(true))
            case .restart:
                appleMusicPlayer.restart()
                completion(.success(true))
            case .previous:
                appleMusicPlayer.previous()
                self.playback.previousTrack()
                completion(.success(true))
            case .next:
                appleMusicPlayer.next()
                self.playback.nextTrack()
                completion(.success(true))
            case .skip(let time):
                appleMusicPlayer.seek(to: time)
                completion(.success(true))
            }
        case .spotify:
            fatalError("NOT IMPLEMENTED")
            
            switch command {
            case .play:
                SpotifyAPI.currentSession.appRemote.playerAPI?.resume({ (_, error) in
                    guard error == nil else { completion(.failure(.failedToCommunicate)); return }
                    self.playback.updateState(to: .playing)
                    
                    completion(.success(true))
                })
            case .pause:
                SpotifyAPI.currentSession.appRemote.playerAPI?.pause({ (_, error) in
                    guard error == nil else { completion(.failure(.failedToCommunicate)); return }
                    self.playback.updateState(to: .paused)
                    
                    completion(.success(true))
                })
            case .stop:
                SpotifyAPI.currentSession.appRemote.playerAPI?.pause({ (_, error) in
                    guard error == nil else { completion(.failure(.failedToCommunicate)); return }
                    self.playback.updateState(to: .ended)
                    
                    completion(.success(true))
                })
                // TODO: Clear the queue
            case .restart:
                SpotifyAPI.currentSession.appRemote.playerAPI?.seek(toPosition: 0, callback: { (_, error) in
                    guard error == nil else { completion(.failure(.failedToCommunicate)); return }
                    
                    completion(.success(true))
                })
                SpotifyAPI.currentSession.appRemote.playerAPI?.resume({ (_, error) in
                    guard error == nil else { completion(.failure(.failedToCommunicate)); return }
                    
                    completion(.success(true))
                })
            case .previous:
                SpotifyAPI.currentSession.appRemote.playerAPI?.skip(toPrevious: { (_, error) in
                    guard error == nil else { completion(.failure(.failedToCommunicate)); return }
                    
                    completion(.success(true))
                })
            case .next:
                SpotifyAPI.currentSession.appRemote.playerAPI?.skip(toNext: { (_, error) in
                    guard error == nil else { completion(.failure(.failedToCommunicate)); return }
                    
                    completion(.success(true))
                })
            case .skip(let time):
                SpotifyAPI.currentSession.appRemote.playerAPI?.seek(toPosition: time, callback: { (_, error) in
                    guard error == nil else { completion(.failure(.failedToCommunicate)); return }
                    
                    completion(.success(true))
                })
            }
        default:
            break
        }
    }
    
    // MARK: - MediaPlayer
    func setupNowPlayingRemoteCommands() {
        let remoteCommands = MPRemoteCommandCenter.shared()
        
//        remoteCommands.playCommand.addTarget { [unowned self] (event) -> MPRemoteCommandHandlerStatus in
//            self.performPlaybackCommand(<#T##command: PlaybackCommand##PlaybackCommand#>)
//        }
    }
    
}

extension Notification.Name {
    public static let musicPlay = Notification.Name("Play")
    public static let musicPause = Notification.Name("Pause")
    public static let musicNextTrack = Notification.Name("Next Track")
    public static let musicPreviousTrack = Notification.Name("Previous Track")
    public static let musicRestartTrack = Notification.Name("Restart Track")
    
    public static let currentPlaybackStateDidChange = Notification.Name("currentPlaybackStateDidChange")
}
