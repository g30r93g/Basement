//
//  SignInWithAppleButton.swift
//  Basement
//
//  Created by George Nick Gorzynski on 03/07/2020.
//

import UIKit
import AuthenticationServices

@IBDesignable
class SignInWithAppleButton: RoundButton {
    
    private var authorizationButton: ASAuthorizationAppleIDButton!
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Create ASAuthorizationAppleIDButton
        let style: ASAuthorizationAppleIDButton.Style = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        self.authorizationButton = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: style)
        self.authorizationButton.cornerRadius = self.cornerRadius
        
        // Set selector for touch up inside event so that can forward the event to MyAuthorizationAppleIDButton
        self.authorizationButton.addTarget(self, action: #selector(self.authorizationAppleIDButtonTapped(_:)), for: .touchUpInside)
        
        // Show authorizationButton
        self.addSubview(self.authorizationButton)
        
        // Use autolayout to make authorizationButton follow the MyAuthorizationAppleIDButton's dimension
        self.authorizationButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.authorizationButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0),
            self.authorizationButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0.0),
            self.authorizationButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0.0),
            self.authorizationButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0),
        ])
    }
    
    @objc func authorizationAppleIDButtonTapped(_ sender: Any) {
        // Forward the touch up inside event to MyAuthorizationAppleIDButton
        self.sendActions(for: .touchUpInside)
    }
    
}
