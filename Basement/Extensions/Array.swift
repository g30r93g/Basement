//
//  Array.swift
//  Vibe
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
    
}
