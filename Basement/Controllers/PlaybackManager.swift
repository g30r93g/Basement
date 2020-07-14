//
//  PlaybackManager.swift
//  Basement
//
//  Created by George Nick Gorzynski on 06/07/2020.
//

import Foundation

class PlaybackManager {
    
    // MARK: Static Instance
    static let current = PlaybackManager()
    
    // MARK: Properties
    private(set) var playback = CurrentPlayback()
    var miniPlayerDelegate: MiniPlayerDelegate? = nil
    
    // MARK: Initialisers
    init() { }
    
    // MARK: Enums
    enum State: String, Codable {
        case notPlaying, paused, playing
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
        var content: [Music.Song] = []
        var currentSong: Music.Song? {
            get {
                guard state != .notPlaying,
                      !self.content.isEmpty
                else { return nil }
                
                return self.content.retrieve(index: self.currentSongIndex)
            }
        }
        private var currentSongIndex: Array<Music.Song>.Index = -1
        var currentPlaybackRuntime: Int {
            get {
                guard let playbackEvents = SessionManager.current.session?.playback.events else { return 0 }
                let lastSongChangeIndex = playbackEvents.lastIndex(where: {$0.state == .next || $0.state == .previous || $0.state == .restart}) ?? 0
                
                let timestamps = playbackEvents[lastSongChangeIndex...].map({$0.date})
                var previousDate: Date? = nil
                var currentRuntime: Int = 0
                
                for (index, timestamp) in timestamps.enumerated() {
                    if index == 0 { previousDate = timestamp; continue }
                    guard let previousTimestamp = previousDate else { continue }
                    
                    currentRuntime += Int(timestamp.timeIntervalSince(previousTimestamp) * 1000)
                    
                    previousDate = timestamp
                }
                
                return currentRuntime
            }
        }
        
        // MARK: Initialisers
        init(state: PlaybackManager.State = .notPlaying) {
            self.state = state
        }
        
        // MARK: Methods
        public func history() -> [Music.Song] {
            if self.currentSongIndex < 0 { return [] }
            return Array(self.content[0..<currentSongIndex])
        }
        
        public func playingNext() -> [Music.Song] {
            if self.currentSongIndex < 0 { return self.content }
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
    }
    
    // MARK: Update Methods
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
            self.playback.updateState(to: .notPlaying)
            self.miniPlayerDelegate?.playbackStateUpdated(to: .notPlaying)
        default:
            break
        }
    }
    
    // MARK: Playback Methods
    public func performPlaybackCommand(_ command: PlaybackCommand) {
        SessionManager.current.updateSessionPlaybackState(to: command)
        
        switch command {
        case .stop:
            break
            // Terminate current session.
            
            // This will tell AppleMusicAPI or SpotifyAPI to stop playback and clear the queue.
            // This will tell SessionManager to send a 'STOP' playback event, set session to nil, and delete the 'Users/{userID}/currentSession/{sessionID}' document
        case .pause:
            break
            // Pause playback.
        
            // This will tell AppleMusicAPI or SpotifyAPI to pause playback.
            // This will tell SessionManager to send a 'PAUSE' playback event, which will be broadcasted to all listeners by the document update trigger
        case .play:
            break
            // Play playback.
        
            // This will tell AppleMusicAPI or SpotifyAPI to start playback.
            // This will tell SessionManager to send a 'PLAY' playback event, which will be broadcasted to all listeners by the document update trigger
        case .restart:
            break
            // Restart playback of current track.
        
            // This will tell AppleMusicAPI or SpotifyAPI to restart playback of current track.
            // This will tell SessionManager to send a 'RESTART' playback event, which will be broadcasted to all listeners by the document update trigger
        case .previous:
            break
            // Play previous track in playback queue.
        
            // This will tell AppleMusicAPI or SpotifyAPI to move back a track in the queue, if possible.
            // If a track does exist before, SessionManager will send a 'PREVIOUS' playback event, which will be broadcasted to all listeners by the document update trigger
        case .next:
            break
            // Play next track in playback queue.
        
            // This will tell AppleMusicAPI or SpotifyAPI to move forward a track in the queue, if possible.
            // If a track does exist after, SessionManager will send a 'NEXT' playback event, which will be broadcasted to all listeneres by the document update trigger
        case .skip(let amount):
            break
        }
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

protocol MiniPlayerDelegate {
    func playbackStateUpdated(to state: PlaybackManager.State)
}

protocol PlaybackUpdateRequestDelegate {
    func sendPlaybackCommand(_ command: PlaybackManager.PlaybackCommand)
}
