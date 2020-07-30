//
//  TimeInterval.swift
//  Basement
//
//  Created by George Nick Gorzynski on 15/07/2020.
//

import Foundation

extension TimeInterval {
    
    var milliseconds: Int {
        return Int(self * 1000)
    }
    
    var seconds: Int {
        return Int(self) % 60
    }
    
    var minutes: Int {
        return (Int(self) / 60 ) % 60
    }
    
    var hours: Int {
        return Int(self) / 3600
    }
    
}
