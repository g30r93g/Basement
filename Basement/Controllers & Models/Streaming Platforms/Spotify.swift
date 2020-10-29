//
//  Spotify.swift
//  Basement
//
//  Created by George Nick Gorzynski on 29/10/2020.
//

import UIKit
import Alamofire

class Spotify: NSObject {
    
    // MARK: Initialisers
    public func setup() { }
    
    // MARK: Properties
    let clientID = "f7a62c1ccd0441fc8ed469499cd36669"
    let redirectURL = URL(string: "basement://spotifyAuthCompletion")!
    
    var accessToken: String? = nil
    
    lazy private(set) var configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
    lazy private(set) var sessionManager: SPTSessionManager = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()
    lazy private(set) var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        return appRemote
    }()
    
    // MARK: Remote Methods
    
    
    // MARK: Auth Methods
    func updateAccessToken(_ token: String) {
        self.accessToken = token
        self.appRemote.connectionParameters.accessToken = accessToken
    }
    
    func requestAccessAuthorization(scopes: SPTScope) {
        self.sessionManager.initiateSession(with: scopes, options: .default)
    }
    
    func requestUserAuthorization(completion: @escaping(Bool) -> Void) {
        self.appRemote.authorizeAndPlayURI("")
    }
    
    // MARK: Specialised Content Methods
    
    
    // MARK: Content Methods
    
    
    // MARK: Playback Methods
    
    
    // MARK: Queue Methods
    
}

extension Spotify: SPTSessionManagerDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("Spotify Player Session Initiated")
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("Spotify Player Session Initiation Failed")
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Failed to make connection with Spotify Player")
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Failed to disconnect from Spotify Player")
    }
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("Successfully made connection with Spotify Player")
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("Spotify Player State Changed")
    }
    
}
