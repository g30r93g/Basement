//
//  Presentable.swift
//  Basement
//
//  Created by George Nick Gorzynski on 05/07/2020.
//

import Foundation

protocol Presentable {
    
    func presentContentVC(_ content: Music.ContentContainer)
    func presentNowPlaying()
    
}

protocol PresentableOptions {
    
    func presentOptions()
    
}
