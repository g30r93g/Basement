//
//  Array.swift
//  Basement
//
//  Created by George Nick Gorzynski on 16/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import Foundation

extension Array {
    
    func retrieve(index: Int) -> Element? {
        if index < self.count {
            return self[index]
        } else {
            return nil
        }
    }
    
    func hasIndex(_ index: Int) -> Bool {
        return index >= self.startIndex && index < self.endIndex
    }
    
}

extension Array where Element: Equatable {
    
    func hasCommonElements(_ array: [Element]) -> Bool {
        var doesContain = false
        
        for element in self {
            if array.contains(element) {
                doesContain = true
                break
            }
        }
        
        return doesContain
    }
    
}
