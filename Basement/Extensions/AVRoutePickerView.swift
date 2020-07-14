//
//  AVRoutePickerView.swift
//  Basement
//
//  Created by George Nick Gorzynski on 07/07/2020.
//

import AVKit

extension AVRoutePickerView {
    func present() {
        let routePickerButton = subviews.first(where: { $0 is UIButton }) as? UIButton
        routePickerButton?.sendActions(for: .touchUpInside)
    }
}
