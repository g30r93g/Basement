//
//  ImageTextField.swift
//  Basement
//
//  Created by George Nick Gorzynski on 14/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

@IBDesignable
class ImageTextField: UITextField {
    
    var textFieldBorderStyle: UITextField.BorderStyle = .roundedRect
    
    // Provides left padding for image
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += padding
        return textRect
    }
    
    // Provides right padding for image
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.rightViewRect(forBounds: bounds)
        textRect.origin.x -= padding
        return textRect
    }
    
    @IBInspectable var image: UIImage? = nil {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var padding: CGFloat = 0
    @IBInspectable var imageTint: UIColor = .clear {
        didSet {
            updateView()
        }
    }
    
    func updateView() {
        if let image = self.image {
            leftViewMode = .always
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            imageView.image = image
            imageView.tintColor = self.imageTint
            leftView = imageView
        } else {
            leftViewMode = .never
            leftView = nil
        }
    }
    
}
