//
//  HomeViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var activeFriendsInformation: UILabel!
    @IBOutlet weak private var contentTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.setupView()
    }
    
    // MARK: Methods
    private func setupView() {
        AppleMusicAPI.currentSession.delegate = self
        
        AppleMusicAPI.currentSession.setup { (setupSuccessful) in
            if setupSuccessful {
                AppleMusicAPI.currentSession.performAuth(shouldSetup: true)
            }
        }
        
        // Fetch Current User
        Firebase.shared.currentUser { (result) in
            switch result {
            case .success(let currentUser):
                Firebase.shared.getFriends(for: currentUser.userIdentifier()) { (friendResult) in
                    switch friendResult {
                    case .success(_):
                        self.contentTableView.reloadData()
                        self.triggerUserHistoryFetch(userID: currentUser.userIdentifier())
                        DispatchQueue.main.async {
                            self.activeFriendsInformation.text = "None of your friends are streaming."
                        }
                    case .failure(_):
                        break
                    }
                }
            case .failure(_):
                break
            }
        }
        
        // Add extra scroll
        self.contentTableView.contentInset.top = self.view.safeAreaInsets.top + 50
        self.contentTableView.contentInset.bottom = self.view.safeAreaInsets.bottom + 110
        
        // Add pull to refresh
        self.contentTableView.refreshControl = UIRefreshControl()
        self.contentTableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    private func triggerUserHistoryFetch(userID: String) {
        SessionManager.current.fetchHistory(for: userID) { (result) in
            switch result {
            case .success(_):
                self.contentTableView.reloadData()
            default:
                break
            }
        }
    }
    
    @objc func refresh() {
        AppleMusicAPI.currentSession.fetchUserLibrary { (result) in
            DispatchQueue.main.async {
                self.contentTableView.refreshControl?.endRefreshing()
                
                self.contentTableView.reloadData()
            }
        }
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    // MARK: IBActions
    
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    /* THREE SECTIONS
     SECTION 1 - Friends
     SECTION 2 - Recent Session Activity
     SECTION 3,4,5... - Streaming Service Activity
     */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = 2
        
        if !AppleMusicAPI.currentSession.userLibrary.recentlyPlayed.isEmpty  {
            numberOfRows += 1
        }
        
        if !SpotifyAPI.currentSession.userLibrary.playlists.isEmpty {
            numberOfRows += 1
        }
        
        return numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Music Carousel Cell", for: indexPath) as! MusicCarouselCell
        
        cell.delegate = self
        
        switch indexPath.row {
        case 0:
            cell.setupCellWithFriends(from: [], withHeader: "Your Friend Activity")
        case 1:
            cell.setupCellWithRecents(from: SessionManager.current.sessionHistory, withHeader: "Your Recent Sessions")
        case 2:
            cell.setupCellWithLibraryContent(from: AppleMusicAPI.currentSession.userLibrary.recentlyPlayed, withHeader: "Your \(StreamingPlatform.appleMusic.name) Activity")
        case 3:
            cell.setupCellWithLibraryContent(from: SpotifyAPI.currentSession.userLibrary.content(), withHeader:  "Your \(StreamingPlatform.spotify.name) Activity")
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? MusicCarouselCell {
            cell.removeNotifications()
        }
    }
    
}

extension HomeViewController: AppleMusicAPIDelegate {
    
    func libraryUpdated(library: Music.Library) {
        DispatchQueue.main.async {
            self.contentTableView.reloadData()
        }
    }
    
    func userTokenObtained(userToken: String) { }
    
    func accessToAPIGranted() { }
    
}

extension HomeViewController: Presentable {
    
    func presentContentVC(_ content: Music.ContentContainer) {
        guard let contentVC = storyboard?.instantiateViewController(identifier: "ContentVC") as? ContentViewController else { return }
        self.navigationController?.pushViewController(contentVC, animated: true)
        
        if let topVC = self.navigationController?.topViewController as? ContentViewController {
            topVC.content = content
        }
    }
    
    func presentNowPlaying() {
        guard let nowPlayingVC = UIStoryboard(name: "NowPlaying", bundle: nil).instantiateInitialViewController() as? NowPlayingViewController else { return }
        self.navigationController?.pushViewController(nowPlayingVC, animated: true)
    }
    
}
