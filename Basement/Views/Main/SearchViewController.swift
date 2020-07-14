//
//  SearchViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 18/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit
import KeyboardLayoutGuide

class SearchViewController: UIViewController {
    
    // MARK: Properties
    var contentResults: [Music.Content] = []
    var userResults: [Firebase.UserProfile] = []
    
    // MARK: IBOutlets
    @IBOutlet weak private var searchField: UITextField!
    @IBOutlet weak private var searchResultsLoadIndicator: UIActivityIndicatorView!
    @IBOutlet weak private var searchResultsTable: UITableView!
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchResultsTable.bottomAnchor.constraint(equalTo: self.view.keyboardLayoutGuide.topAnchor).isActive = true
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView), name: .imageDidLoad, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.addTextFieldEvents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.searchField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.removeTextFieldEvents()
    }
    
    // MARK: Methods
    private func addTextFieldEvents() {
        self.searchField.addTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
    }
    
    private func removeTextFieldEvents() {
        self.searchField.removeTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
    }
    
    @objc private func textFieldDidEdit(textField: UITextField) {
        
        self.search()
    }
    
    @objc private func reloadTableView() {
        DispatchQueue.main.async {
            self.searchResultsTable.reloadData()
        }
    }
    
    private func search() {
        // TODO: Use CrossPlatform.Search() to search for content
        let searchTerm = self.searchField.text ?? ""
        if searchTerm.isEmpty {
            self.contentResults.removeAll()
            self.userResults.removeAll()
            self.reloadTableView()
            return
        }
        
        // Search for users
        Firebase.shared.searchUsers(by: searchTerm, limit: 5) { (result) in
            switch result {
            case .success(let matchingUsers):
                DispatchQueue.main.async {
                    guard searchTerm == self.searchField.text else { self.userResults.removeAll(); return }
                    
                    self.userResults = matchingUsers.sorted(by: {$0.information.username.levenshteinDistanceScore(to: searchTerm) > $1.information.username.levenshteinDistanceScore(to: searchTerm)})
                    self.reloadTableView()
                }
            case .failure(let error):
                print("[SearchVC] Failed to search for users with username \(searchTerm) - \(error)")
            }
        }
        
        // Search Apple Music
        AppleMusicAPI.currentSession.amber?.searchCatalogResources(searchTerm: searchTerm, limit: 15) { (result) in
            switch result {
            case .success(let results):
                DispatchQueue.main.async {
                    guard searchTerm == self.searchField.text else { return }
                    
                    DispatchQueue.global(qos: .userInteractive).async {
                        self.contentResults.removeAll()
                        
                        if let songs = results.songs?.data {
                            songs.forEach({self.contentResults.append(Music.Song(amber: $0.attributes))})
                        }
                        
                        if let albums = results.albums?.data {
                            albums.forEach({self.contentResults.append(Music.Album(amber: $0.attributes))})
                        }
                        
                        if let playlists = results.playlists?.data {
                            playlists.forEach({self.contentResults.append(Music.Playlist(amber: $0.attributes))})
                        }
                        
                        self.contentResults.sort(by: {$0.name.levenshteinDistanceScore(to: searchTerm) > $1.name.levenshteinDistanceScore(to: searchTerm)})
                        
                        self.reloadTableView()
                    }
                }
            case .failure(let error):
                print("[SearchVC] Content search on Apple Music failed - \(error)")
            }
        }
    }
    
    // MARK: IBActions
    
}

extension SearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchField.resignFirstResponder()
        return true
    }
    
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userResults.count + self.contentResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: Display Best Match
        if indexPath.row == 0 {
            // Display best match
            let cell = tableView.dequeueReusableCell(withIdentifier: "Best Match", for: indexPath) as! BestMatchCell
            
            guard let searchTerm = self.searchField.text else { return cell }
            
            if let topContentMatch = self.contentResults.first, let topUserMatch = self.userResults.first {
                let contentMatchRating = topContentMatch.name.levenshteinDistanceScore(to: searchTerm)
                let friendMatchRating = topUserMatch.information.username.levenshteinDistanceScore(to: searchTerm)
                
                if contentMatchRating > friendMatchRating {
                    cell.setupCell(from: topContentMatch)
                } else {
                    cell.setupCell(from: topUserMatch)
                }
            } else if let topContentMatch = self.contentResults.first {
                cell.setupCell(from: topContentMatch)
            } else if let topUserMatch = self.userResults.first {
                cell.setupCell(from: topUserMatch)
            }
            
            return cell
        } else if indexPath.row > self.userResults.count {
            // Display content results
            let cell = tableView.dequeueReusableCell(withIdentifier: "Content", for: indexPath) as! ContentCell
            guard let data = self.contentResults.retrieve(index: indexPath.row) else { return UITableViewCell() }
            
            cell.setupCell(from: data)
            
            return cell
        } else {
            // Display user
            let cell = tableView.dequeueReusableCell(withIdentifier: "User", for: indexPath) as! FriendCell
            let data = self.userResults[indexPath.row]
            
            cell.setupCell(from: data)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 330
        } else if indexPath.row >= self.userResults.count {
            return 70
        } else {
            return 80
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.row == 0 {
            // Best Match
            guard let cell = cell as? BestMatchCell else { return }
            
            if let musicContent = cell.musicContent {
                guard let contentVC = storyboard?.instantiateViewController(identifier: "ContentVC") as? ContentViewController else { return }
                self.navigationController?.pushViewController(contentVC, animated: true)
                
                if let contentContainer = musicContent as? Music.ContentContainer {
                    contentVC.content = contentContainer
                } else if let songToFetch = musicContent as? Music.Song {
                    contentVC.loadAlbumForSong(songToFetch)
                }
            } else if let userProfile = cell.userProfile {
                guard let profileVC = storyboard?.instantiateViewController(identifier: "ProfileVC") as? ProfileViewController else { return }
                self.navigationController?.pushViewController(profileVC, animated: true)
                
                if let topVC = self.navigationController?.topViewController as? ProfileViewController {
                    topVC.user = userProfile
                }
            }
        } else if indexPath.row > self.userResults.count {
            // Content
            guard let cell = cell as? ContentCell,
                  let content = cell.musicContent
            else { return }
            
            guard let contentVC = storyboard?.instantiateViewController(identifier: "ContentVC") as? ContentViewController else { return }
            self.navigationController?.pushViewController(contentVC, animated: true)
            
            if let topVC = self.navigationController?.topViewController as? ContentViewController {
                // Content already fetched
                if let contentContainer = content as? Music.ContentContainer {
                    topVC.content = contentContainer
                } else if let songToFetch = content as? Music.Song {
                    topVC.loadAlbumForSong(songToFetch)
                }
            }
        } else {
            // User
            guard let cell = cell as? FriendCell else { return }
            
            if let userProfile = cell.userProfile {
                guard let profileVC = storyboard?.instantiateViewController(identifier: "ProfileVC") as? ProfileViewController else { return }
                self.navigationController?.pushViewController(profileVC, animated: true)
                
                if let topVC = self.navigationController?.topViewController as? ProfileViewController {
                    topVC.user = userProfile
                }
            }
        }
    }
    
}
