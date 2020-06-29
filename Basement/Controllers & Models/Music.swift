//
//  Music.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import MediaPlayer
import FirebaseFirestore
import Amber

class Music: NSObject {
    
    // MARK: Shared Instance
    static let session = Music()
    
    // MARK: Properties
    var playbackDelegate: PlaybackDelegate?
    let musicServices: [StreamingPlatform] = [.appleMusic, .spotify]
    private(set) var nowPlaying: NowPlaying = .nothing {
        didSet {
            self.playbackDelegate?.didUpdateContent(nowPlaying: self.nowPlaying)
        }
    }
    
    // MARK: Enums
    enum PlaybackState: Int, Codable {
        case playing = 2
        case paused = 1
        case notPlaying = 0
    }
    
    // MARK: Classes
    class NowPlaying {
        
        // MARK: Static Instances
        static let nothing = NowPlaying()

        // MARK: Properties
        private(set) var currentState: PlaybackState = .notPlaying
        public var playbackDetails: PlaybackDetails?
        public var queue: [Song]
        // TODO:  public var queue: [Content]
        public var currentSong: Song? {
            get {
                if self.queue.isEmpty { return nil }
                if self.currentSongPointer < 0 || self.currentSongPointer >= self.queue.count { return nil }
                return self.queue[currentSongPointer]
            }
        }
        private var currentSongPointer: Int
        
        
        // MARK: Initialisers
        init() {
            self.playbackDetails = nil
            self.queue = []
            self.currentSongPointer = -1
        }
        
        // MARK: Methods
        public func moveTo(song: Song) -> [Song] {
            self.currentSongPointer = self.queue.firstIndex(of: song) ?? 0
            return Array(self.queue[self.currentSongPointer..<self.queue.endIndex])
        }
    }
    
    struct PlaybackDetails: Codable {
        private(set) var playbackEvents: [PlaybackEvent] = []
        lazy var timeElapsed: Int = {
            // TODO
//            return self.playbackEvents.reduce
            return -1
        }()
        
        struct PlaybackEvent: Codable {
            let state: PlaybackState
            let time: Date
        }
    }
    
    struct Showcase: Codable {
        let playlists: [Music.Playlist]
        let albums: [Music.Album]
    }
    
    // MARK: Classes
    class Content: Equatable, Codable {
        let name: String
        let streamingInformation: StreamingInfo
        
        init(name: String, streamingInformation: StreamingInfo) {
            self.name = name
            self.streamingInformation = streamingInformation
        }
        
        // MARK: Equatable
        static func == (lhs: Music.Content, rhs: Music.Content) -> Bool {
            return lhs.streamingInformation.identifier == rhs.streamingInformation.identifier
        }
    }
    
    struct ContentCreator: Equatable {
        static let me = ContentCreator(name: "Me", isLibrary: true)
        
        let name: String
        let isLibrary: Bool
    }
    
    class ContentContainer: Content {
        var songs: [Song]
        
        init(name: String, songs: [Song], streamingInformation: StreamingInfo) {
            self.songs = songs
            super.init(name: name, streamingInformation: streamingInformation)
        }
        
        required init(from decoder: Decoder) throws {
            fatalError("init(from:) has not been implemented")
        }
    }
    
    class Library: Equatable {
        private(set) var playlists: [Playlist]
        private(set) var recentlyPlayed: [Content]
        
        init(playlists: [Playlist] = [], recentlyPlayed: [Content] = []) {
            self.playlists = playlists
            self.recentlyPlayed = recentlyPlayed
        }
        
        func addPlaylists(_ playlistsToAdd: [Playlist]) {
            playlistsToAdd.forEach({self.playlists.append($0)})
        }
        
        func addRecentContent(_ recentContentToAdd: [Content]) {
            recentContentToAdd.forEach({self.recentlyPlayed.append($0)})
        }
        
        func content() -> [Content] {
            return self.recentlyPlayed + self.playlists // + self.albums + self.songs
        }
        
        // MARK: Equatable
        static func == (lhs: Music.Library, rhs: Music.Library) -> Bool {
            return lhs.playlists == rhs.playlists && lhs.recentlyPlayed == rhs.recentlyPlayed
        }
    }
    
    class StreamingInfo: Equatable, Codable {
        let platform: StreamingPlatform
        var identifier: String
        let artworkURL: URL?
        var artwork: UIImageView?
        
        init(platform: StreamingPlatform, identifier: String, artworkURL: URL?) {
            self.platform = platform
            self.identifier = identifier
            self.artworkURL = artworkURL
            
            if let artworkURL = artworkURL {
                DispatchQueue.main.async {
                    let loadedArtwork = UIImageView(image: nil)
                    loadedArtwork.load(url: artworkURL, shouldNotify: true)
                    
                    self.artwork = loadedArtwork
                }
            }
        }
    
        static func == (lhs: Music.StreamingInfo, rhs: Music.StreamingInfo) -> Bool {
            return lhs.identifier == rhs.identifier
        }
        
        enum CodingKeys: String, CodingKey {
            case platform, identifier, artworkURL
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.identifier = try container.decode(String.self, forKey: .identifier)
            
            let platform = try container.decode(String.self, forKey: .platform)
            switch platform {
            case "Apple Music":
                self.platform = .appleMusic
            case "Spotify":
                self.platform = .spotify
            default:
                throw fatalError("No Platform Assigned")
            }
            
            let artworkURLString = try container.decodeIfPresent(String.self, forKey: .artworkURL)
            
            if let artworkURLString = artworkURLString, let artworkURL = URL(string: artworkURLString) {
                self.artworkURL = artworkURL
                
                self.artwork = UIImageView(image: nil)
                self.artwork?.load(url: artworkURL)
            } else {
                self.artworkURL = nil
                self.artwork = nil
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(self.identifier, forKey: .identifier)
            try container.encode(self.platform.name, forKey: .platform)
            try container.encodeIfPresent(self.artworkURL?.absoluteString, forKey: .artworkURL)
        }
    }
    
    class Playlist: ContentContainer {
        let contentCreator: ContentCreator
        
        init(name: String, songs: [Song] = [], contentCreator: ContentCreator, streamingInformation: StreamingInfo) {
            self.contentCreator = contentCreator
            super.init(name: name, songs: songs, streamingInformation: streamingInformation)
        }
        
        init(amber: PlaylistAttributes?, contentCreator: ContentCreator = .me) {
            let name = amber?.name ?? ""
            let playlistIdentifier = amber?.playParams?.id ?? ""
            let artworkURLString = amber?.artwork?.url
                .replacingOccurrences(of: "{w}", with: "\(amber?.artwork?.width ?? 1000)")
                .replacingOccurrences(of: "{h}", with: "\(amber?.artwork?.height ?? 1000)") ?? ""
            let artworkURL = URL(string: artworkURLString)
            
            let streamingInfo = Music.StreamingInfo(platform: .appleMusic, identifier: playlistIdentifier, artworkURL: artworkURL)
            let isContentCreator = amber?.playlistType == "user-shared"
            let curatorName = amber?.curatorName ?? ""
            let contentCreator: Music.ContentCreator = isContentCreator ? .me : Music.ContentCreator(name: curatorName, isLibrary: false)
            
            self.contentCreator = contentCreator
            super.init(name: name, songs: [], streamingInformation: streamingInfo)
        }
        
        required init(from decoder: Decoder) throws {
            fatalError("init(from:) has not been implemented")
        }
        
        /// Returns the combined runtime in milliseconds
        func combinedRuntime() -> Int {
            return self.songs.reduce(0, {$0 + $1.runtime})
        }
        
        /// Returns the number of songs
        func numberOfSongs() -> Int {
            return self.songs.count
        }
        
        /// Updates the songs in the playlist
        func updateSongs(completion: (([Song]?) -> Void)? = nil) {
            switch self.streamingInformation.platform {
            case .appleMusic:
                AppleMusicAPI.currentSession.amber?.getCatalogPlaylist(identifier: streamingInformation.identifier, include: [.tracks], completion: { (result) in
                    switch result {
                    case .success(let playlist):
                        var songs: [Song] = []
                        
                        if let playlistSongs = playlist.relationships?.tracks.data {
                            playlistSongs.forEach({songs.append(Song(amber: $0.attributes))})
                        }
                        
                        self.songs = songs
                        completion?(songs)
                    case .failure(_):
                        completion?(nil)
                    }
                })
            case .spotify:
                completion?([])
            default:
                completion?(nil)
            }
        }
    }
    
    class Album: ContentContainer {
        let artist: String
    
        init(name: String, artist: String, songs: [Song] = [], streamingInformation: StreamingInfo) {
            self.artist = artist
            
            super.init(name: name, songs: songs, streamingInformation: streamingInformation)
        }
        
        init(amber: AlbumAttributes?) {
            let name = amber?.name ?? ""
            let artistName = amber?.artistName ?? ""
            let albumIdentifier = amber?.playParams?.globalId ?? amber?.playParams?.id ?? ""
            let artworkURLString = amber?.artwork?.url
                .replacingOccurrences(of: "{w}", with: "\(amber?.artwork?.width ?? 1000)")
                .replacingOccurrences(of: "{h}", with: "\(amber?.artwork?.height ?? 1000)") ?? ""
            let artworkURL = URL(string: artworkURLString)
            
            let streamingInfo = Music.StreamingInfo(platform: .appleMusic, identifier: albumIdentifier, artworkURL: artworkURL)
            
            self.artist = artistName
            super.init(name: name, songs: [], streamingInformation: streamingInfo)
        }
        
        required init(from decoder: Decoder) throws {
            fatalError("init(from:) has not been implemented")
        }
        
        /// Returns the combined runtime in milliseconds
        func combinedRuntime() -> Int {
            return self.songs.reduce(0, {$0 + $1.runtime})
        }
        
        /// Returns the number of songs
        func numberOfSongs() -> Int {
            return self.songs.count
        }
        
        /// Updates the songs in  the album
        func updateSongs(completion: (([Song]?) -> Void)? = nil) {
            switch self.streamingInformation.platform {
            case .appleMusic:
                AppleMusicAPI.currentSession.amber?.getCatalogAlbum(identifier: streamingInformation.identifier, include: [.tracks], completion: { (result) in
                    switch result {
                    case .success(let playlist):
                        var songs: [Song] = []
                        
                        if let playlistSongs = playlist.relationships?.tracks.data {
                            playlistSongs.forEach({songs.append(Song(amber: $0.attributes))})
                        }
                        
                        self.songs = songs
                        completion?(songs)
                    case .failure(_):
                        completion?(nil)
                    }
                })
            case .spotify:
                completion?([])
            default:
                completion?(nil)
            }
        }
    }
    
    class Song: Content {
        let artist: String
        let album: String
        let runtime: Int // In miliseconds
        
        init(name: String, artist: String, album: String, runtime: Int, streamingInformation: StreamingInfo) {
            self.artist = artist
            self.album = album
            self.runtime = runtime
            
            super.init(name: name, streamingInformation: streamingInformation)
        }
        
        init(amber: SongAttributes?) {
            let name = amber?.name ?? ""
            let artist = amber?.artistName ?? ""
            let album = amber?.albumName ?? ""
            let runtime = amber?.duration ?? 0
            let identifier = amber?.playParams?.globalId ?? amber?.playParams?.id ?? ""
            let artworkURLString = amber?.artwork.url
                .replacingOccurrences(of: "{w}", with: "1000")
                .replacingOccurrences(of: "{h}", with: "1000") ?? ""
            let artworkURL = URL(string: artworkURLString)
            
            let streamingInfo = StreamingInfo(platform: .appleMusic, identifier: identifier, artworkURL: artworkURL)
            
            self.artist = artist
            self.album = album
            self.runtime = runtime
            super.init(name: name, streamingInformation: streamingInfo)
        }
        
        required init(from decoder: Decoder) throws {
            fatalError("init(from:) has not been implemented")
        }
    }
    
    // MARK: Playback Methods
    func play(from platform: StreamingPlatform, songIdentifier: String) {
        // Update current state
        self.emitPlaybackNotification(named: .musicPlay)
    }
    
    func continuePlaying() {
        // Check if song is paused, and if song is paused, then play
        self.emitPlaybackNotification(named: .musicPlay)
    }
    
    func pause() {
        self.emitPlaybackNotification(named: .musicPause)
    }
    
    func nextTrack() {
        self.emitPlaybackNotification(named: .musicNextTrack)
    }
    
    func previousTrack() {
        self.emitPlaybackNotification(named: .musicPreviousTrack)
    }
    
    func restartTrack() {
        self.emitPlaybackNotification(named: .musicRestartTrack)
    }
    
    private func emitPlaybackNotification(named name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
    
}

extension Notification.Name {
    public static let musicPlay = Notification.Name("Play")
    public static let musicPause = Notification.Name("Pause")
    public static let musicNextTrack = Notification.Name("Next Track")
    public static let musicPreviousTrack = Notification.Name("Previous Track")
    public static let musicRestartTrack = Notification.Name("Restart Track")
}

protocol PlaybackDelegate {
    
    func playbackStateChanged(to state: Music.PlaybackState, nowPlaying: Music.NowPlaying?)
    func didUpdateContent(nowPlaying: Music.NowPlaying?)
    
}
