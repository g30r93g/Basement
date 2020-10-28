//
//  Integer.swift
//  Basement
//
//  Created by George Nick Gorzynski on 08/07/2020.
//

import Foundation

extension Int {
    
    // Returns seconds from milliseconds
    func seconds() -> Int {
        return Int(self / 1000) % 60
    }
    
    func minutes() -> Int {
        return Int(self / 60000)
    }
    
    func doubleDigitString() -> String {
        return String(format: "%02d", self)
    }
    
}
