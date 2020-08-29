//
//  PlaybackManager.swift
//  Basement
//
//  Created by George Nick Gorzynski on 24/08/2020.
//

import Foundation

class PlaybackManager {
    
    // MARK: - Shared Instance
    static let current = PlaybackManager()
    
    // MARK: - Public Interfaces
    
    // MARK: Structs
    struct Playback: Codable, Equatable {
        let tracks: [Music.Song]
        let currentTrackIndex: Int
        
    }
    
    // MARK: - Private Interfaces
    
}
