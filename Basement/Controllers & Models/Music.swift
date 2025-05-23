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
        let platform: StreamingPlatform.Platforms
        var identifier: String
        let artworkURL: URL?

        init(platform: StreamingPlatform.Platforms, identifier: String, artworkURL: URL?) {
            self.platform = platform
            self.identifier = identifier
            self.artworkURL = artworkURL
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

            self.platform = try container.decode(StreamingPlatform.Platforms.self, forKey: .platform)
            
            if let artworkURLString = try container.decodeIfPresent(String.self, forKey: .artworkURL),
               !artworkURLString.isEmpty,
               let artworkURL = URL(string: artworkURLString) {
                self.artworkURL = artworkURL
            } else {
                self.artworkURL = nil
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(self.identifier, forKey: .identifier)
            try container.encode(self.platform, forKey: .platform)
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
                StreamingPlatform.appleMusic.amber?.getCatalogPlaylist(identifier: streamingInformation.identifier, include: [.tracks], completion: { (result) in
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
            }
        }
    }

    class Album: ContentContainer {
        let artist: String

        init(name: String, artist: String, songs: [Song] = [], streamingInformation: StreamingInfo) {
            self.artist = artist

            super.init(name: name, songs: songs, streamingInformation: streamingInformation)
        }

        init(amber: AlbumAttributes?, songs: [Song] = []) {
            let name = amber?.name ?? ""
            let artistName = amber?.artistName ?? ""
            let albumIdentifier = amber?.playParams?.globalId ?? amber?.playParams?.id ?? ""
            let artworkURLString = amber?.artwork?.url
                .replacingOccurrences(of: "{w}", with: "\(amber?.artwork?.width ?? 1000)")
                .replacingOccurrences(of: "{h}", with: "\(amber?.artwork?.height ?? 1000)") ?? ""
            let artworkURL = URL(string: artworkURLString)

            let streamingInfo = Music.StreamingInfo(platform: .appleMusic, identifier: albumIdentifier, artworkURL: artworkURL)

            self.artist = artistName
            super.init(name: name, songs: songs, streamingInformation: streamingInfo)
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
                StreamingPlatform.appleMusic.amber?.getCatalogAlbum(identifier: streamingInformation.identifier, include: [.tracks], completion: { (result) in
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

}

