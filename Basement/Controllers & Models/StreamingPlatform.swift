//
//  MusicService.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class StreamingPlatform: Codable {
    
    // Static Instances
    static private(set) var appleMusic = StreamingPlatform(platform: .appleMusic)
    static private(set) var spotify = StreamingPlatform(platform: .spotify)
    
    // MARK: Properties
    let platform: Platform
    let name: String
    let primaryColor: UIColor
    var logo: UIImage
    var isLinked: Bool
    
    // MARK: Initialiser
    init(platform: Platform) {
        self.platform = platform
        self.name = platform.rawValue
        
        switch platform {
        case .appleMusic:
            self.primaryColor = .appleMusic
            self.logo = .appleMusic
            self.isLinked = false
        case .spotify:
            self.primaryColor = .spotify
            self.logo = .spotify
            self.isLinked = false
        }
    }
    
    // MARK: Enums
    enum Platform: String, Codable {
        case appleMusic = "Apple Music"
        case spotify = "Spotify"
    }
    
    enum MusicServiceError: Error {
        case noSuchMusicService
        case linkingFailed(platform: Platform)
    }
    
    // MARK: Methods
    public func updateLinkStatus(to status: Bool) {
        self.isLinked = status
    }
    
    static public func performLink(for platform: StreamingPlatform, completion: @escaping(Result<String, MusicServiceError>) -> Void) {
        print("[MusicService] Performing auth for \(platform.name)")
        switch platform {
        case .appleMusic:
            AppleMusicAPI.currentSession.performAuth { (result) in
                switch result {
                case .success(let token):
                    if !token.isEmpty {
                        completion(.success(token))
                    } else {
                        completion(.failure(.linkingFailed(platform: platform.platform)))
                    }
                case .failure(_):
                    completion(.failure(.linkingFailed(platform: platform.platform)))
                }
            }
        case .spotify:
            break
//            SpotifyAuth.currentSession.performAuth()
//                { (result) in
//                switch result {
//                case .success(let isAuthed):
//                    print("[MusicService] Spotify is \(isAuthed ? "" : "not") authed!")
//                    self.spotify.updateLinkStatus(to: isAuthed)
//                    completion(.success(isAuthed))
//                case .failure(let error):
//                    print("[MusicService] Failed to auth Spotify")
//                    self.spotify.updateLinkStatus(to: false)
//                    completion(.failure(error))
//                }
//            }
        default:
            completion(.failure(.linkingFailed(platform: platform.platform)))
        }
    }
    
    // MARK: Codable
    enum CodingKeys: String, CodingKey {
        case name
    }
    
    // MARK: Decodable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let platform = try container.decode(StreamingPlatform.Platform.self, forKey: .name)
        
        switch platform {
        case .appleMusic:
            self.platform = .appleMusic
            self.name = StreamingPlatform.appleMusic.name
            self.primaryColor = .appleMusic
            self.logo = .appleMusic
            self.isLinked = false
        case .spotify:
            self.platform = .spotify
            self.name = StreamingPlatform.spotify.name
            self.primaryColor = .spotify
            self.logo = .spotify
            self.isLinked = false
        }
    }
    
    // MARK: Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.name, forKey: .name)
    }
    
}

extension StreamingPlatform: Equatable {
    
    static func == (lhs: StreamingPlatform, rhs: StreamingPlatform) -> Bool {
        return lhs.name == rhs.name
    }
    
}
