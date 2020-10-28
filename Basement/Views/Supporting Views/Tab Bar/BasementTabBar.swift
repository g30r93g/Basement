////
////  BasementTabBar.swift
////  Basement
////
////  Created by George Nick Gorzynski on 13/06/2020.
////  Copyright © 2020 George Nick Gorzynski. All rights reserved.
////
//
//import UIKit
//
//class BasementTabBarController: UITabBarController { }
//
//class BasementTabBar: UITabBar {
//
//    // MARK: Properties
//    var miniPlayer: MiniPlayerView!
//
//    // MARK: Methods
//    override func awakeFromNib() {
//        super.awakeFromNib()
//
//        self.addMiniPlayer()
//    }
//
//    private func addMiniPlayer() {
//        self.frame = CGRect(x: self.frame.minX, y: self.frame.minY - 140, width: self.frame.width, height: self.frame.height + 140)
//
//        self.miniPlayer = MiniPlayerView.fromNib(named: "MiniPlayerView")
//        self.addSubview(self.miniPlayer)
//
//        self.miniPlayer.translatesAutoresizingMaskIntoConstraints = false
//        self.miniPlayer.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
//
//        self.miniPlayer.playPauseButton.addTarget(self, action: #selector(playbackControlTouched), for: .touchUpInside)
//    }
//
//    @objc private func playbackControlTouched() { }
//
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        if self.isHidden {
//            return super.hitTest(point, with: event)
//        }
//
//        let convertedButtonPoint = self.convert(point, to: self.miniPlayer.playPauseButton)
//        let isInButton = (convertedButtonPoint.x >= 0 && convertedButtonPoint.x <= 50) && (convertedButtonPoint.y >= 0 && convertedButtonPoint.y <= 50)
//
//        let convertedPlayerPoint = self.convert(point, to: self.miniPlayer.nowPlayingButton)
//        let isInPlayer = (convertedPlayerPoint.x >= 20 && convertedPlayerPoint.x <= self.frame.width - 20) && (convertedPlayerPoint.y >= 0 && convertedPlayerPoint.y <= 80)
//
//        if isInButton {
//            return self.miniPlayer.playPauseButton
//        } else if isInPlayer {
//            return self.miniPlayer.nowPlayingButton
//        } else {
//            return super.hitTest(point, with: event)
//        }
//    }
//
//}
