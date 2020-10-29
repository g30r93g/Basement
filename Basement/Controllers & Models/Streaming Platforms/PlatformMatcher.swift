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
    
    // MARK: Enums
    enum MatchingError: Error {
        case undefined
    }
    
    // MARK: Methods
    public func matchTrackList(_ trackList: [Music.Song],
                               source: StreamingPlatform.Platforms,
                               completion: @escaping(Result<([[Music.Song]], [Music.Song]), PlatformMatcher.MatchingError>) -> Void) {
        let matchDispatchGroup = DispatchGroup()
        
        var matches: [[Music.Song]] = []
        var failedMatches: [Music.Song] = []
        
        for track in trackList {
            matchDispatchGroup.enter()
            
            var destination: StreamingPlatform.Platforms {
                return source == .appleMusic ? .spotify : .appleMusic
            }
            
            guard !track.streamingInformation.contains(where: {$0.platform == destination}) else { matches.append([track]); completion(.success((matches, failedMatches))); return }
            
            PlatformMatcher().matchSong(track, destination: destination) { (result) in
                switch result {
                case .success(let songs):
                    matches.append(songs)
                case .failure(_):
                    failedMatches.append(track)
                }
            }
        }
        
        matchDispatchGroup.notify(queue: .global(qos: .userInitiated)) {
            guard matches.count + failedMatches.count == trackList.count else { return }
            
            completion(.success((matches, failedMatches)))
        }
    }
    
    public func matchSong(_ song: Music.Song,
                          destination: StreamingPlatform.Platforms,
                          completion: @escaping(Result<[Music.Song], MatchingError>) -> Void) {
        let searchText = "\(self.stripParentheses(from: song.name)) \(song.artist)"
        
        switch destination {
        case .appleMusic:
            StreamingPlatform.appleMusic.search(text: searchText) { (results) in
                guard let results = results else { completion(.failure(.undefined)); return }
                let tracks = results.compactMap({ $0 as? Music.Song })
                guard !tracks.isEmpty,
                      let bestMatchingTrack = tracks.sorted(by: {
                          searchText.levenshteinDistanceScore(to: "\($0.name) \($0.artist)") > searchText.levenshteinDistanceScore(to: "\($1.name) \($1.artist)")
                      }).first
                else { completion(.failure(.undefined)); return }
                
                completion(.success([song, bestMatchingTrack]))
            }
        case .spotify:
            fatalError("Not Implemented")
        }
    }
    
    private func stripParentheses(from title: String) -> String {
        // Ensure that if the track title actually begins with '(' it is not incorrectly stripped
        guard title.first != "(" else { return title }
        
        // Determine index of first '('. If no occurence, return title
        guard let firstOccuringIndex = title.firstIndex(of: "(") else { return title }
        
        // Range between startIndex and firstIndex of '('
        // Return string
        return String(title[title.startIndex..<firstOccuringIndex])
    }
    
}
