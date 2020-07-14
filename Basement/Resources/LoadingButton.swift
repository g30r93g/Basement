//
//  LoadingButton.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

@IBDesignable
class LoadingButton: RoundButton {
    
    // MARK: IBInspectables
    @IBInspectable var activityIndicatorColor: UIColor = .white
    
    // MARK: Properties
    var originalButtonText: String?
    var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Public Methods
    func startLoading() {
        self.originalButtonText = self.titleLabel?.text
        self.setTitle("", for: .normal)
        
        if (self.activityIndicator == nil) {
            self.activityIndicator = self.createActivityIndicator()
        }
        
        self.showSpinning()
    }
    
    func stopLoading() {
        self.setTitle(self.originalButtonText, for: .normal)
        self.activityIndicator.stopAnimating()
    }
    
    // MARK: Private Methods
    private func createActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView()
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = self.activityIndicatorColor
        
        return activityIndicator
    }
    
    private func showSpinning() {
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.activityIndicator)
        self.centerActivityIndicatorInButton()
        self.activityIndicator.startAnimating()
    }
    
    private func centerActivityIndicatorInButton() {
        let xCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: self.activityIndicator, attribute: .centerX, multiplier: 1, constant: 0)
        self.addConstraint(xCenterConstraint)
        
        let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: self.activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
        self.addConstraint(yCenterConstraint)
    }
    
}
