//
//  StreamingPlatform.swift
//  Basement
//
//  Created by George Nick Gorzynski on 21/08/2020.
//

import Foundation

class StreamingPlatform {
    
    // MARK: Static Instances
    static let current = StreamingPlatform()
    
    // MARK: Initialisers
    init() { }
    
    // MARK: Properties
    public var platformLinked: Platform {
        guard let linkedPlatformString = UserDefaults.standard.string(forKey: "linkedPlatform"),
              let linkedPlatform = Platform(rawValue: linkedPlatformString)
        else { return Platform.none }
        
        return linkedPlatform
    }
    
    // MARK: Structs
    struct LinkDetails: Codable, Equatable {
        let platform: Platform
        let tokens: StreamingPlatformTokens
    }
    
    struct AppleMusicTokens: StreamingPlatformTokens, Codable {
        var userToken: String
        
        let devloperToken: String
    }
    
    struct SpotifyTokens: StreamingPlatformTokens, Codable {
        var userToken: String
        
        let clientID: String
        let clientSecret: String
    }
    
    // MARK: Protocols
    protocol StreamingPlatformTokens {
        var userToken: String
    }
    
    // MARK: Enums
    enum Platform: String, Codable {
        case appleMusic
        case spotify
        case none
    }
    
    enum StreamingPlatformError: Error {
        case platformNotSetUp
        
        case unknownError
        case noLinkedPlatform
        
        case noAccount
        case notFullAccount
    }
    
    // MARK: Methods
    func link(platform: Platform, completion: @escaping(Result<LinkDetails, StreamingPlatformError>) -> Void) {
        switch platform {
        case .appleMusic:
            self.linkAppleMusic(completion: completion)
        case .spotify:
            self.linkSpotify(completion: completion)
        case .none:
            completion(.failure(.platformNotSetUp))
        }
    }
    
    private func linkAppleMusic(completion: @escaping(Result<LinkDetails, StreamingPlatformError>) -> Void) {
        AppleMusicAPI.currentSession.performAuth(shouldSetup: true) { (result)
            switch result {
            case success(let userToken):
                break
            case failure(_):
                completion(.failure(.unknownError))
            }
        }
    }
    
    private func linkSpotify(completion: @escaping(Result<LinkDetails, StreamingPlatformError>) -> Void) {
        completion(.failure(.platformNotSetUp))
    }
    
}
