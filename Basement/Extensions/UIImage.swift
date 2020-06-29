//
//  UIImage.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 16/05/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit

extension UIImage {
	
	/// Apple Music's logo
	static let appleMusic = UIImage(named: "Apple Music")!
	
	/// Spotify's Logo
	static let spotify = UIImage(named: "Spotify")!
	
}

extension UIImageView {
    
    func load(url: URL, shouldNotify: Bool = false) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                        
                        if shouldNotify {
                            NotificationCenter.default.post(Notification(name: .imageDidLoad))
                        }
                    }
                }
            }
        }
    }
    
}

extension Notification.Name {
    static let imageDidLoad = Notification.Name("imageDidLoad")
}
