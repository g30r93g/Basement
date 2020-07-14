//
//  UIApplication.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

extension UIApplication{
    class func getPresentedViewController() -> UIViewController? {
        var presentViewController = UIApplication.shared.keyWindow?.rootViewController
        
        while let presentedVC = presentViewController?.presentedViewController {
            presentViewController = presentedVC
        }
        
        return presentViewController
    }
    
    class func getRootNavigationController() -> UINavigationController? {
        return self.getPresentedViewController() as? UINavigationController
    }
    
}
