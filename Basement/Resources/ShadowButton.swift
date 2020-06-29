//
//  ShadowButton.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 24/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

@IBDesignable
class ShadowButton: LoadingButton {
    
    // MARK: IBInspectables
    @IBInspectable var shadowColor: UIColor = .clear {
        didSet {
            self.updateShadow()
        }
    }
    
    @IBInspectable var xAxisOffset: CGFloat = 0.0 {
        didSet {
            self.updateShadow()
        }
    }
    
    @IBInspectable var yAxisOffset: CGFloat = 0.0 {
        didSet {
            self.updateShadow()
        }
    }
    
    @IBInspectable var shadowOpacity: Float = 1.0 {
        didSet {
            self.updateShadow()
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat = 0.0 {
        didSet {
            self.updateShadow()
        }
    }
    
    // MARK: Methods
    private func updateShadow() {
        self.layer.masksToBounds = false
        self.layer.shadowColor = self.shadowColor.cgColor
        self.layer.shadowOffset = CGSize(width: self.xAxisOffset, height: self.yAxisOffset)
        self.layer.shadowRadius = self.shadowRadius
        self.layer.shadowOpacity = self.shadowOpacity
    }
    
}
