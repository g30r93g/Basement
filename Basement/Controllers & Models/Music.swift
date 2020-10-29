//
//  Music.swift
//  Basement
//
//  Created by George Nick Gorzynski on 21/10/2020.
//

import Foundation
import Amber

class Music {

    // MARK: Shared Instance
    static let session = Music()
    
    // MARK: Enums
    enum ContentTypes {
        case song
        case album
        case playlist
    }

    // MARK: Classes
    class Content: Equatable, Codable {
        let name: String
        let artwork: URL?
        let streamingInformation: [StreamingInfo]

        init(name: String, artworkURL: URL?, streamingInformation: [StreamingInfo]) {
            self.name = name
            self.artwork = artworkURL
            self.streamingInformation = streamingInformation
        }

        // MARK: Equatable
        static func == (lhs: Music.Content, rhs: Music.Content) -> Bool {
            return lhs.streamingInformation == rhs.streamingInformation
        }
        
        // MARK: Codable
        private enum CodingKeys: String, CodingKey {
            case name, streamingInfo
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.name = try container.decode(String.self, forKey: .name)
            self.streamingInformation = try container.decode([StreamingInfo].self, forKey: .streamingInfo)
            self.artwork = nil
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(self.name, forKey: .name)
            try container.encode(self.streamingInformation, forKey: .streamingInfo)
        }
    }

    struct ContentCreator: Equatable {
        static let me = ContentCreator(name: "Me", isLibrary: true)

        let name: String
        let isLibrary: Bool
    }

    class ContentContainer: Content {
        var songs: [Song]

        init(name: String, songs: [Song], artworkURL: URL?, streamingInformation: [StreamingInfo]) {
            self.songs = songs
            super.init(name: name, artworkURL: artworkURL, streamingInformation: streamingInformation)
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
        let platform: StreamingPlatform.Platforms
        var identifier: String

        init(platform: StreamingPlatform.Platforms, identifier: String) {
            self.platform = platform
            self.identifier = identifier
        }

        static func == (lhs: Music.StreamingInfo, rhs: Music.StreamingInfo) -> Bool {
            return lhs.identifier == rhs.identifier
        }

        enum CodingKeys: String, CodingKey {
            case platform, identifier
        }

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.identifier = try container.decode(String.self, forKey: .identifier)

            self.platform = try container.decode(StreamingPlatform.Platforms.self, forKey: .platform)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(self.identifier, forKey: .identifier)
            try container.encode(self.platform, forKey: .platform)
        }
    }

    class Playlist: ContentContainer {
        let contentCreator: ContentCreator

        init(name: String, songs: [Song] = [], artworkURL: URL?, contentCreator: ContentCreator, streamingInformation: [StreamingInfo]) {
            self.contentCreator = contentCreator
            super.init(name: name, songs: songs, artworkURL: artworkURL, streamingInformation: streamingInformation)
        }

        init(amber: PlaylistAttributes?, contentCreator: ContentCreator = .me) {
            let name = amber?.name ?? ""
            let playlistIdentifier = amber?.playParams?.id ?? ""
            let artworkURLString = amber?.artwork?.url
                .replacingOccurrences(of: "{w}", with: "\(amber?.artwork?.width ?? 1000)")
                .replacingOccurrences(of: "{h}", with: "\(amber?.artwork?.height ?? 1000)") ?? ""
            let artworkURL = URL(string: artworkURLString)

            let streamingInfo = Music.StreamingInfo(platform: .appleMusic, identifier: playlistIdentifier)
            let isContentCreator = amber?.playlistType == "user-shared"
            let curatorName = amber?.curatorName ?? ""
            let contentCreator: Music.ContentCreator = isContentCreator ? .me : Music.ContentCreator(name: curatorName, isLibrary: false)

            self.contentCreator = contentCreator
            super.init(name: name, songs: [], artworkURL: artworkURL, streamingInformation: [streamingInfo])
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
            guard let streamingInfo = self.streamingInformation.first else { completion?(nil); return }
            
            switch streamingInfo.platform {
            case .appleMusic:
                StreamingPlatform.appleMusic.amber?.getCatalogPlaylist(identifier: streamingInfo.identifier, include: [.tracks], completion: { (result) in
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
                fatalError("Not Implemented")
            }
        }
    }

    class Album: ContentContainer {
        let artist: String

        init(name: String, artist: String, artworkURL: URL?, songs: [Song] = [], streamingInformation: [StreamingInfo]) {
            self.artist = artist

            super.init(name: name, songs: songs, artworkURL: artworkURL, streamingInformation: streamingInformation)
        }

        init(amber: AlbumAttributes?, songs: [Song] = []) {
            let name = amber?.name ?? ""
            let artistName = amber?.artistName ?? ""
            let albumIdentifier = amber?.playParams?.globalId ?? amber?.playParams?.id ?? ""
            let artworkURLString = amber?.artwork?.url
                .replacingOccurrences(of: "{w}", with: "\(amber?.artwork?.width ?? 1000)")
                .replacingOccurrences(of: "{h}", with: "\(amber?.artwork?.height ?? 1000)") ?? ""
            let artworkURL = URL(string: artworkURLString)

            let streamingInfo = Music.StreamingInfo(platform: .appleMusic, identifier: albumIdentifier)

            self.artist = artistName
            super.init(name: name, songs: songs, artworkURL: artworkURL, streamingInformation: [streamingInfo])
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

        /// Updates the songs in the album
        func updateSongs(completion: (([Song]?) -> Void)? = nil) {
            guard let streamingInfo = self.streamingInformation.first else { completion?(nil); return }
            
            switch streamingInfo.platform {
            case .appleMusic:
                StreamingPlatform.appleMusic.amber?.getCatalogAlbum(identifier: streamingInfo.identifier, include: [.tracks], completion: { (result) in
                    switch result {
                    case .success(let playlist):
                        var songs: [Song] = []

                        if let playlistSongs = playlist.relationships?.tracks.flatMap({$0.data}) {
                            playlistSongs.forEach({songs.append(Song(amber: $0.attributes))})
                        }

                        self.songs = songs
                        completion?(songs)
                    case .failure(_):
                        completion?(nil)
                    }
                })
            case .spotify:
                fatalError("Not Implemented")
            }
        }
    }

    class Song: Content {
        let artist: String
        let album: String
        let runtime: Int // In miliseconds

        init(name: String, artist: String, album: String, runtime: Int, artworkURL: URL?, streamingInformation: [StreamingInfo]) {
            self.artist = artist
            self.album = album
            self.runtime = runtime

            super.init(name: name, artworkURL: artworkURL, streamingInformation: streamingInformation)
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

            let streamingInfo = StreamingInfo(platform: .appleMusic, identifier: identifier)

            self.artist = artist
            self.album = album
            self.runtime = runtime

            super.init(name: name, artworkURL: artworkURL, streamingInformation: [streamingInfo])
        }

        required init(from decoder: Decoder) throws {
            fatalError("init(from:) has not been implemented")
        }
    }

}

