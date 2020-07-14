//
//  Integer.swift
//  Basement
//
//  Created by George Nick Gorzynski on 08/07/2020.
//

import Foundation

extension Int {
    
    func twoDigits() -> Int {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
        
        let number = NSNumber(value: self)
        
        return Int(formatter.string(from: number) ?? "0") ?? 0
    }
    
}
