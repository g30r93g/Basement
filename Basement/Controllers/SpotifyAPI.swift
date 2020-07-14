//
//  SpotifyAPI.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit
import SpotifyKit

protocol SpotifyAuthDelegate {
    
    func didAuthenticate(success: Bool)
    
}

class SpotifyAPI: NSObject, SPTSessionManagerDelegate, SPTAppRemoteDelegate {
    
    // MARK: Shared Instance
    static public let currentSession = SpotifyAPI()
    public var authDelegate: SpotifyAuthDelegate? = nil
    
    // MARK: Properties
    private let clientID = "e75ccfc0c1824eada3de38d3a6c80d62"
    private let clientSecret = "06b5ea8e523740b09bb9bb8d19ec4d72"
    static let redirectURI = URL(string: "basement://spotifyAuth")!
    
    public lazy var configuration = SPTConfiguration(clientID: clientID, redirectURL: SpotifyAPI.redirectURI)
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()
    
    lazy var spotifyKitManager: SpotifyManager = {
        let manager = SpotifyManager(with: SpotifyManager.SpotifyDeveloperApplication(clientId: clientID, clientSecret: clientSecret, redirectUri: SpotifyAPI.redirectURI.absoluteString))
        
        return manager
    }()
    
    private(set) var userLibrary: Music.Library = Music.Library()
    
    // MARK: Enums
    public enum SpotifyError: Error {
        case unknownError
        
        case authFailed
        case notAuthed
    }
    
    // MARK: Auth Methods
    public func performAuth(completion: @escaping(Bool) -> Void) {
        self.spotifyKitManager.authorize()
        
        var numberOfRepeats = 0
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { (timer) in
            if numberOfRepeats >= 10 {
                timer.invalidate()
                
                completion(false)
            } else if self.spotifyKitManager.hasToken {
                timer.invalidate()
                
                completion(true)
            } else {
                numberOfRepeats += 1
            }
        }
    }
    
    // MARK: Data Methods
    public func fetchUserLibrary(completion: ((Result<Music.Library, SpotifyError>) -> Void)? = nil) {
        guard self.spotifyKitManager.hasToken else { completion?(.failure(.notAuthed)); return }
        
        
        
        completion?(.success(self.userLibrary))
    }
    
    // MARK: Playback Methods
    
    // MARK: SPTAppRemoteDelegate
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("[SpotifyAPI] Spotify Remote failed to connect - \(String(describing: error))")
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("[SpotifyAPI] Spotify Remote disconnected - \(String(describing: error))")
    }
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("[SpotifyAPI] Spotify Remote established connection.")
        self.fetchUserLibrary()
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("[SpotifyAPI] Spotify session failed: \(String(describing: error))")
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("[SpotifyAPI] Spotify session renewed!")
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        appRemote.connect()
        print("[SpotifyAPI] Spotify session initiated!")
    }
    
}

