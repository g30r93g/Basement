//
//  String.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import Foundation

extension String {
    
    func fragment() -> [String] {
        var fragmentedStrings: [String] = []
        
        var previousIteration = ""
        for char in self {
            // Add next char to previous iteration of string
            previousIteration.append(char)
            
            // Add next fragment of string to the array of fragmented strings
            fragmentedStrings.append(previousIteration)
        }
        
        return fragmentedStrings
    }
    
    /// An algorithm that determines the minimum number of single-character edits (insertions, deletions or substitutions) required to change one string into the other
    func levenshteinDistanceScore(to string: String, ignoreCase: Bool = true, trimWhiteSpacesAndNewLines: Bool = true) -> Double {
        
        var firstString = self
        var secondString = string
        
        if ignoreCase {
            firstString = firstString.lowercased()
            secondString = secondString.lowercased()
        }
        if trimWhiteSpacesAndNewLines {
            firstString = firstString.trimmingCharacters(in: .whitespacesAndNewlines)
            secondString = secondString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let empty = [Int](repeating:0, count: secondString.count)
        var last = [Int](0...secondString.count)
        
        for (i, tLett) in firstString.enumerated() {
            var cur = [i + 1] + empty
            for (j, sLett) in secondString.enumerated() {
                cur[j + 1] = tLett == sLett ? last[j] : Swift.min(last[j], last[j + 1], cur[j])+1
            }
            last = cur
        }
        
        // maximum string length between the two
        let lowestScore = max(firstString.count, secondString.count)
        
        if let validDistance = last.last {
            return  1 - (Double(validDistance) / Double(lowestScore))
        }
        
        return 0.0
    }
    
    func randomString(length: Int = 6) -> String {
        
        enum s {
            static let c = Array("abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ12345789")
            static let k = UInt32(c.count)
        }
        
        var result = [Character](repeating: "-", count: length)
        
        for i in 0..<length {
            let r = Int(arc4random_uniform(s.k))
            result[i] = s.c[r]
        }
        
        return String(result)
    }
    
}
