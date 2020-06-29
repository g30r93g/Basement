//
//  SpotifyAPI.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit
import SpotifyKit

class SpotifyAPI: NSObject, SPTSessionManagerDelegate, SPTAppRemoteDelegate {
    
    // MARK: Shared Instance
    static public let currentSession = SpotifyAPI()
    
    // MARK: Properties
    private let clientID = "e75ccfc0c1824eada3de38d3a6c80d62"
    private let clientSecret = "06b5ea8e523740b09bb9bb8d19ec4d72"
    public let redirectURL = URL(string: "vibe://spotifyAuthCallback")!
    
    public lazy var configuration = SPTConfiguration(clientID: clientID, redirectURL: self.redirectURL)
    
    lazy var appRemote: SPTAppRemote = {
      let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
      appRemote.delegate = self
      return appRemote
    }()
    
    lazy var spotifyKitManager: SpotifyManager = {
        let manager = SpotifyManager(with: SpotifyManager.SpotifyDeveloperApplication(clientId: clientID, clientSecret: clientSecret, redirectUri: redirectURL.absoluteString))
        
        return manager
    }()
    
    private(set) var userLibrary: Music.Library = Music.Library()
    
    // MARK: Data Methods
    public func fetchUserLibrary() {
    }
    
    // MARK: Playback Methods
    func play(_ resource: String) {
    }
    
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
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
    }

    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        appRemote.connectionParameters.accessToken = session.accessToken
        appRemote.connect()
    }
    
}
