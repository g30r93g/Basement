//
//  AppleMusicAPI.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import Foundation
import Amber
import StoreKit

class AppleMusicAPI {
    
    // MARK: Static Instance
    static public let currentSession = AppleMusicAPI()
    
    // MARK: Amber
    private(set) var amber: Amber? = nil
    var delegate: AppleMusicAPIDelegate? = nil
    
    // MARK: Initialiser
    init() {
//        self.player?.playbackDelegate = PlaybackManager.current
        self.setup { (_) in }
    }
    
    // MARK: Properties
    private var developerToken: String? = nil
    
    private(set) var userLibrary = Music.Library() {
        didSet {
            self.delegate?.libraryUpdated(library: self.userLibrary)
        }
    }
    
    // MARK: Setup Methods
    func setup(completion: @escaping(Bool) -> Void) {
        self.getDeveloperToken { (result) in
            switch result {
            case .success(let token):
                self.amber = Amber(developerToken: token)
                completion(true)
            case .failure(_):
                self.amber = nil
                completion(false)
            }
        }
    }
    
    // MARK: Auth Methods
    private func getDeveloperToken(completion: @escaping(Result<String, AmberError>) -> Void) {
        Firebase.shared.fetchAppleMusicAuthToken { (result) in
            switch result {
            case .success(let token):
                self.developerToken = token
                completion(.success(token))
            case .failure(_):
                completion(.failure(.unknownError))
            }
        }
    }
    
    public func performAuth(shouldSetup: Bool = true, completion: ((Result<String, AmberError>) -> Void)? = nil) {
        if self.amber == nil {
            self.setup { (didSetup) in
                if didSetup { self.performAuth(shouldSetup: shouldSetup, completion: completion) }
                else { completion?(.failure(.unknownError)) }
            }
        } else {
            self.amber?.fetchUserToken(completion: { (result) in
                switch result {
                case .success(let token):
                    print("[AppleMusicAPI] User token fetched: \(token)")
                    self.amber?.updateUserToken(to: token)
                    self.delegate?.userTokenObtained(userToken: token)
                    
                    if shouldSetup {
                        self.fetchUserRelatedContent()
                    }
                case .failure(_):
                    break
                }
                
                completion?(result)
            })
        }
    }
    
    public func isAuthed(completion: ((Bool) -> Void)? = nil) {
        self.performAuth { (result) in
            switch result {
            case .success(_):
                completion?(true)
            case .failure(_):
                completion?(false)
            }
        }
    }
    
    private func fetchUserRelatedContent(completion: (() -> Void)? = nil) {
        self.fetchUserLibrary { (result) in
            switch result {
            case .success(let library):
                self.userLibrary = library
            case .failure(let error):
                print("[AppleMusicAPI] Failure while setting up - \(error.localizedDescription)")
            }
            
            completion?()
        }
    }
    
    public func fetchUserLibrary(completion: @escaping(Result<Music.Library, AmberError>) -> Void) {
        var playlists: [Music.Playlist] = []
        var recentlyPlayed: [Music.Content] = []
        
        let userLibraryFetchGroup = DispatchGroup()
        userLibraryFetchGroup.enter()
        
        // Fetch all user playlists
        self.amber?.getAllLibraryPlaylists(limit: 100) { (result) in
            switch result {
            case .success(let fetchedPlaylists):
                print("[AppleMusicAPI] \(fetchedPlaylists.count) playlists fetched. - \(fetchedPlaylists.map({$0.attributes?.name ?? "---"})))")
                
                for playlist in fetchedPlaylists {
                    let name = playlist.attributes?.name ?? ""
                    let playlistIdentifier = playlist.attributes?.playParams?.id ?? ""
                    let artworkURLString = playlist.attributes?.artwork?.url
                        .replacingOccurrences(of: "{w}", with: "\(playlist.attributes?.artwork?.width ?? 1000)")
                        .replacingOccurrences(of: "{h}", with: "\(playlist.attributes?.artwork?.height ?? 1000)") ?? ""
                    let artworkURL = URL(string: artworkURLString)
                    
                    let streamingInfo = Music.StreamingInfo(platform: .appleMusic, identifier: playlistIdentifier, artworkURL: artworkURL)
                    
                    playlists.append(Music.Playlist(name: name, contentCreator: .me, streamingInformation: streamingInfo))
                }
            case .failure(let error):
                print("[AppleMusicAPI] Failed to fetch playlists - \(error.localizedDescription)")
                completion(.failure(error))
            }
            
            userLibraryFetchGroup.leave()
        }
        
        // Fetch 10 most recent plays (playlists, songs, albums)
        userLibraryFetchGroup.enter()
        self.amber?.getRecentlyPlayedResources(limit: 10) { (result) in
            switch result {
            case .success(let fetchedRecentPlays):
                print("[AppleMusicAPI] \(fetchedRecentPlays.count) recently played resources fetched.")
                
                for resource in fetchedRecentPlays {
                    if let playlistResource = resource.asPlaylist() {
                        let playlist = Music.Playlist(amber: playlistResource.attributes)
                        
                        recentlyPlayed.append(playlist)
                    } else if let albumResource = resource.asAlbum() {
                        let album = Music.Album(amber: albumResource.attributes)
                        
                        recentlyPlayed.append(album)
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
            
            userLibraryFetchGroup.leave()
        }
        
        userLibraryFetchGroup.notify(queue: .main) {
            let library = Music.Library(playlists: playlists, recentlyPlayed: recentlyPlayed)
            self.delegate?.libraryUpdated(library: library)
            completion(.success(library))
        }
    }
    
}

protocol AppleMusicAPIDelegate {
    
    func libraryUpdated(library: Music.Library)
    func userTokenObtained(userToken: String)
    func accessToAPIGranted()
    
}
