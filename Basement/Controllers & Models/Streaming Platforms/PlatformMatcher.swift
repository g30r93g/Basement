//
//  PlatformMatcher.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/10/2020.
//

import Foundation

class PlatformMatcher {
    
    // MARK: Initialiser
    init() { }
    
    // MARK: Structs
    typealias MatchedItem = Music.Content
    
    struct SourceDetails {
        let platform: StreamingPlatform.Platforms
    }
    
    // MARK: Methods
    public func matchSong(_ song: Music.Content,
                          source: StreamingPlatform.Platforms,
                          destination: StreamingPlatform.Platforms,
                          completion: @escaping([MatchedItem]) -> Void) {
        
    }
    
}
