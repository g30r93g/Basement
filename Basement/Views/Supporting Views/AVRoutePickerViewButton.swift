//
//  AVRoutePickerViewButton.swift
//  Basement
//
//  Created by George Nick Gorzynski on 07/07/2020.
//

import AVKit
import UIKit

@IBDesignable
class AVRoutePickerViewButton: RoundButton {
    
    private lazy var routePickerView: AVRoutePickerView = {
            let routePickerView = AVRoutePickerView(frame: .zero)
        
            routePickerView.isHidden = true
            self.addSubview(routePickerView)
        
            return routePickerView
        }()
    
    func presentRoutePicker() {
        self.routePickerView.present()
    }
    
}
