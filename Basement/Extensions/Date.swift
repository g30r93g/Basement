//
//  Date.swift
//  Basement
//
//  Created by George Nick Gorzynski on 22/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import Foundation

public extension Date {
    
    func timeDeltaInMillis(to nextDate: Date) -> Double {
        return nextDate.timeIntervalSince(self).magnitude
    }
    
}
