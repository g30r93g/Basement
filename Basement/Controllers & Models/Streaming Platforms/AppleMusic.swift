//
//  AppleMusic.swift
//  Basement
//
//  Created by George Nick Gorzynski on 22/10/2020.
//

import Foundation
import Amber
import StoreKit

class AppleMusic {
    
    // MARK: Initialiser
    init() {
        self.setup() { (success) in
            print("[AppleMusic] Apple Music is\(success ? " " : " not") set up.")
        }
    }
    
    public func setup(completion: @escaping(Bool) -> Void) {
        self.fetchDeveloperToken { (token) in
            if let token = token {
                self.amber = Amber(developerToken: token)
                self.amber?.player.playbackUpdateDelegate = self
                print("Developer Token: \(token)")
            }
            
            completion(token != nil)
        }
    }
    
    // MARK: Properties
    private(set) var amber: Amber?
    
    // MARK: Auth Methods
    public func authorizeUser(completion: @escaping(String?) -> Void) {
        self.fetchUserToken(completion: completion)
    }
    
    private func fetchDeveloperToken(completion: @escaping(String?) -> Void) {
        completion("eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IkZRUThZRExEWFEifQ.eyJpc3MiOiIzVjkzQTNBQ1Y5IiwiZXhwIjoxNjAzOTM3MzUzLCJpYXQiOjE2MDM4MDc3NTN9.th61iVtW4kaIjX8WDkjeiPmA-o8nZMDXKjnDupCW3yATBu3xRwMxJNAbIJ3FE4-j1RZPxoDEeQB-MtcVNNupxQ")
    }
    
    private func fetchUserToken(completion: @escaping(String?) -> Void) {
        if self.amber == nil {
            self.setup() { (success) in
                if success {
                    self.fetchUserToken(completion: completion)
                } else {
                    completion(nil)
                }
            }
        } else {
            self.amber?.fetchUserToken(completion: { (result) in
                switch result {
                case .success(let token):
                    print("[AppleMusic] User token fetched: \(token)")
                    completion(token)
                case .failure(_):
                    completion(nil)
                }
            })
        }
    }
    
    // MARK: Specialised Content Methods
    public func fetchUserLibrary(completion: @escaping(Result<Music.Library, AmberError>) -> Void) {
            var playlists: [Music.Playlist] = []
            var recentlyPlayed: [Music.Content] = []
            
            let userLibraryFetchGroup = DispatchGroup()
            userLibraryFetchGroup.enter()
            
            // Fetch all user playlists
            self.amber?.getAllLibraryPlaylists(limit: 100) { (result) in
                switch result {
                case .success(let fetchedPlaylists):
                    print("[AppleMusic] \(fetchedPlaylists.count) playlists fetched. - \(fetchedPlaylists.map({$0.attributes?.name ?? "---"})))")
                    
                    for playlist in fetchedPlaylists {
                        let name = playlist.attributes?.name ?? ""
                        let playlistIdentifier = playlist.attributes?.playParams?.id ?? ""
                        let artworkURLString = playlist.attributes?.artwork?.url
                            .replacingOccurrences(of: "{w}", with: "\(playlist.attributes?.artwork?.width ?? 1000)")
                            .replacingOccurrences(of: "{h}", with: "\(playlist.attributes?.artwork?.height ?? 1000)") ?? ""
                        let artworkURL = URL(string: artworkURLString)
                        
                        let streamingInfo = Music.StreamingInfo(platform: .appleMusic, identifier: playlistIdentifier)
                        
                        playlists.append(Music.Playlist(name: name, artworkURL: artworkURL, contentCreator: .me, streamingInformation: [streamingInfo]))
                    }
                case .failure(let error):
                    print("[AppleMusic] Failed to fetch playlists - \(error.localizedDescription)")
                    completion(.failure(error))
                }
                
                userLibraryFetchGroup.leave()
            }
            
            // Fetch 10 most recent plays (playlists, songs, albums)
            userLibraryFetchGroup.enter()
            self.amber?.getRecentlyPlayedResources(limit: 10) { (result) in
                switch result {
                case .success(let fetchedRecentPlays):
                    print("[AppleMusic] \(fetchedRecentPlays.count) recently played resources fetched.")
                    
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
                completion(.success(library))
            }
        }
    
    // MARK: Content Methods
    func search(text: String, completion: @escaping([Music.Content]?) -> Void) {
        guard let amber = self.amber else { completion(nil); return }
        
        amber.searchCatalogResources(searchTerm: text, limit: 20, completion: { (result) in
            switch result {
            case .success(let results):
                let matchingSongs = results.songs?.data?.compactMap({ Music.Song(amber: $0.attributes) })
                
                completion(matchingSongs)
            case .failure(_):
                completion(nil)
            }
        })
    }
    
    func fetchSong(identifier: String, completion: @escaping(Music.Song?) -> Void) {
        guard let amber = self.amber else { completion(nil); return }
        
        amber.getCatalogSong(identifier: identifier) { (result) in
            switch result {
            case .success(let matchedSong):
                let song = Music.Song(amber: matchedSong.attributes)
                completion(song)
            case .failure(_):
                completion(nil)
            }
        }
    }
    
    // MARK: Playback Methods
    func updatePlaybackState(state: PlaybackManager.PlaybackCommand, completion: @escaping(PlaybackManager.PlaybackCommand?) -> Void) {
        guard let player = self.amber?.player else { completion(nil); return }
        
        switch state {
        case .awaitStart:
            break
        case .start, .play:
            player.play { (error) in
                error == nil ? completion(state) : completion(nil)
                return
            }
        case .pause:
            player.pause()
        case .end:
            player.stop()
        case .skip(delta: let delta):
            player.skip(by: delta)
        case .next:
            player.next()
        case .previous:
            player.previous()
        }
        
        completion(state)
    }
    
    // FIXME: Implement Synchronisation
    func synchronisePlayback(completion: (Bool) -> Void) {
        completion(true)
    }
    
    // MARK: Queue Methods
    func updateQueue(with tracks: [SessionManager.Track], completion: (Bool) -> Void) {
        guard let player = self.amber?.player else { completion(false); return }
        let tracks = tracks.map({$0.content}).flatMap({$0.streamingInformation.filter({$0.platform == .appleMusic})})
        
        player.updateQueue(tracks.map({$0.identifier}))
        
        completion(true)
    }
    
}

extension AppleMusic: AmberPlayerUpdateDelegate {
    
    func nowPlayingItemChanged() {
        // Do something
    }
    
    func playbackStateChanged() {
        // Do somethings
    }
    
}
