//
//  NowPlayingViewController.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 18/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class NowPlayingViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var backgroundImage: UIImageView!
    @IBOutlet weak private var artworkImage: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subtitleLabel: UILabel!
    @IBOutlet weak private var scrubber: UISlider!
    @IBOutlet weak private var rewindButton: UIButton!
    @IBOutlet weak private var playPauseButton: UIButton!
    @IBOutlet weak private var forwardButton: UIButton!
    @IBOutlet weak private var vibers: UIButton!
    
    // MARK: View Controller Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Music.session.playbackDelegate = self
        self.updateView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        Music.session.playbackDelegate = nil
    }
    
    // MARK: Methods
    private func updateView() {
        let nowPlaying = Music.session.nowPlaying
//        let currentVibe = VibeManager.current.currentVibe
        
        if let currentSong = nowPlaying.currentSong {
            self.backgroundImage.image = currentSong.streamingInformation.artwork?.image
            self.artworkImage.image = currentSong.streamingInformation.artwork?.image
            
            self.titleLabel.text = "\(currentSong.name) • \(currentSong.artist)"
            self.subtitleLabel.text = "Playing from \(currentSong.streamingInformation.platform.name)"
        } else {
            self.dismiss(animated: true) {
                if let topVC = UIApplication.getPresentedViewController() {
                    let nowPlayingStoryboard = UIStoryboard(name: "SetupVibe", bundle: nil)
                    guard let nowPlayingVC = nowPlayingStoryboard.instantiateInitialViewController() else { fatalError() }
                    
                    topVC.present(nowPlayingVC, animated: true, completion: nil)
                }
            }
        }
        
        // TODO
//        if let vibe = currentVibe {
//            if vibe.isHost {
//                self.vibers.setTitle("\(vibe.details.numberOfVibers) people vibing with you", for: .normal)
//            } else {
//                self.vibers.setTitle("Vibing with @\(vibe.host.username)", for: .normal)
//            }
//        }
    }
    
    // MARK: IBActions
    @IBAction private func playPauseTapped(_ sender: UIButton) {
        switch Music.session.nowPlaying.currentState {
        case .playing:
            self.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            Music.session.pause()
        case .paused:
            self.playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            Music.session.continuePlaying()
        default:
            break
        }
    }
    
    @IBAction private func rewindTapped(_ sender: UIButton) {
        Music.session.restartTrack()
    }
    
    @IBAction private func forwardTapped(_ sender: UIButton) {
        Music.session.nextTrack()
    }

}

extension NowPlayingViewController: PlaybackDelegate {
    
    func playbackStateChanged(to state: Music.PlaybackState, nowPlaying: Music.NowPlaying?) {
        self.updateView()
    }
    
    func didUpdateContent(nowPlaying: Music.NowPlaying?) {
        self.updateView()
    }
    
}
