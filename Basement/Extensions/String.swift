//
//  String.swift
//  Vibe
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
    
}
