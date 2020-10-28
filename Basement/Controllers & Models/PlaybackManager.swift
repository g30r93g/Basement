//
//  PlaybackManager.swift
//  Basement
//
//  Created by George Nick Gorzynski on 21/10/2020.
//

import Foundation

class PlaybackManager {
    
    // MARK: Static Instance
    static let current = PlaybackManager()
    
    // MARK: Initialiser
    init() { }
    
    // MARK: Properties
    var streamingPlatform = StreamingPlatform()
    var hasStarted: Bool {
        guard let activeSession = SessionManager.current.activeSession else { return false }
        
        return activeSession.playback.contains(where: {$0.command == .start})
    }
    var isPlaying: Bool {
        guard let activeSession = SessionManager.current.activeSession,
              let lastPlayPauseCommand = activeSession.playback.filter({$0.command == .play || $0.command == .pause || $0.command == .awaitStart || $0.command == .start || $0.command == .end}).last
        else { return false }
        
        switch lastPlayPauseCommand.command {
        case .start, .play:
            return true
        case .pause, .end, .awaitStart:
            return false
        default:
            return false
        }
    }
    var playbackPosition: Int {
        let playbackPosition = self.streamingPlatform.currentPlaybackPosition()
        
        switch playbackPosition {
        case .success(let value):
            return value
        case .failure(_):
            return -1
        }
    }
    var lastPlaybackCommand: Playback? {
        guard let activeSession = SessionManager.current.activeSession,
              let lastReceivedPlaybackCommand = activeSession.playback.last else { return nil }
        
        return lastReceivedPlaybackCommand
    }
    var nowPlaying: SessionManager.Track? {
        let nowPlaying = self.streamingPlatform.nowPlaying()
        
        switch nowPlaying {
        case .success(let trackID):
            guard let tracks = SessionManager.current.activeSession?.tracks,
                  let matchingTrack = tracks.first(where: {$0.streamInformation.streamingInformation.identifier == trackID})
            else { return nil }
            
            return matchingTrack
        case .failure(_):
            return nil
        }
    }
    var queue: [SessionManager.Track]? {
        let nowPlaying = self.streamingPlatform.queue()
        
        switch nowPlaying {
        case .success(let trackIDs):
            guard let tracks = SessionManager.current.activeSession?.tracks else { return nil }
            let matchingTracks = tracks.filter({trackIDs.contains($0.streamInformation.streamingInformation.identifier)})
            
            return matchingTracks
        case .failure(_):
            return nil
        }
    }
    
    // MARK: Structs
    struct Playback: Codable, Comparable {
        let details: PlaybackDetails
        let command: PlaybackCommand
        let issuedAt: Date
        
        // MARK: Comparable
        static func == (lhs: PlaybackManager.Playback, rhs: PlaybackManager.Playback) -> Bool {
            return lhs.details == rhs.details
        }
        
        
        static func < (lhs: PlaybackManager.Playback, rhs: PlaybackManager.Playback) -> Bool {
            return lhs.issuedAt < rhs.issuedAt
        }
    }
    
    struct PlaybackDetails: Codable, Equatable {
        let trackIndex: Int
        let time: Int // In milliseconds (ms)
    }
    
    // MARK: Enums
    enum PlaybackCommand: Codable, Equatable {
        case awaitStart
        case start
        case end
        
        case play
        case pause
        case next
        case previous
        case skip(delta: Int)
        
        // MARK: Codable
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let command = try container.decode(String.self)
            
            switch command {
            case "awaitStart":
                self = .awaitStart
            case "start":
                self = .start
            case "play":
                self = .play
            case "pause":
                self = .pause
            case "end":
                self = .end
            case "next":
                self = .next
            case "previous":
                self = .previous
            default:
                if command.starts(with: "skip_") {
                    guard let skipDelta = Int(command.replacingOccurrences(of: "skip_", with: "")) else { fatalError() }
                    
                    self = .skip(delta: skipDelta)
                } else {
                    fatalError("Command Not Found")
                }
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
            case .awaitStart:
                try container.encode("awaitStart")
            case .start:
                try container.encode("start")
            case .play:
                try container.encode("play")
            case .pause:
                try container.encode("pause")
            case .skip(delta: let delta):
                try container.encode("skip_\(delta)")
            case .end:
                try container.encode("end")
            case .next:
                try container.encode("next")
            case .previous:
                try container.encode("previous")
            }
        }
    }
    
    enum PlaybackError: Error {
        case undefined
    }
    
    // MARK: Methods
    public func updateQueue(with tracks: [SessionManager.Track], completion: @escaping(Result<[SessionManager.Track], PlaybackError>) -> Void) {
        self.streamingPlatform.updateQueue(tracks: tracks) { (result) in
            switch result {
            case .success(let tracks):
                completion(.success(tracks))
            case .failure(_):
                completion(.failure(.undefined))
            }
        }
    }
    
    public func updatePlaybackState(to playback: Playback,
                                    completion: @escaping(Bool) -> Void) {
        // Pass instruction to Streaming Platform
        self.streamingPlatform.updatePlaybackState(from: playback) { (result) in
            switch result {
            case .success(_):
                completion(true)
            case .failure(_):
                completion(false)
            }
        }
    }
    
    public func synchronisePlayback(completion: @escaping(Bool) -> Void) {
        self.streamingPlatform.synchronisePlayback { (result) in
            switch result {
            case .success(_):
                completion(true)
            case .failure(_):
                completion(false)
            }
        }
    }
    
}
