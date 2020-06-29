//
//  ContentViewController.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 14/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var navigationBlur: UIVisualEffectView!
    @IBOutlet weak private var navigationHeight: NSLayoutConstraint!
    @IBOutlet weak private var navigationBar: UIView!
    @IBOutlet weak private var navigationTitle: UILabel!
    
    @IBOutlet weak private var contentTableView: UITableView!
    
    // MARK: Properties
    var content: Music.ContentContainer?
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    // MARK: Methods
    func setupView() {
        self.navigationHeight.constant = self.view.safeAreaInsets.top
        
        self.contentTableView.reloadData()
        self.contentTableView.contentInset.bottom += 120
        
        self.setupNotifications()
        
        if let playlist = self.content as? Music.Playlist {
            playlist.updateSongs { (_) in
                DispatchQueue.main.async {
                    self.contentTableView.reloadData()
                }
            }
        } else if let album = self.content as? Music.Album {
            album.updateSongs { (_) in
                DispatchQueue.main.async {
                    self.contentTableView.reloadData()
                }
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadView), name: .imageDidLoad, object: nil)
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .imageDidLoad, object: nil)
    }
    
    @objc private func reloadView() {
        self.contentTableView.reloadData()
    }
    
    // MARK: IBActions
    @IBAction private func dismissTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

}

extension ContentViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.content == nil { return 0 }
        
        return (self.content?.songs.count ?? 0) + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Content Overview", for: indexPath) as! ContentOverviewCell
            guard let data = self.content else { return UITableViewCell() }
            
            cell.setupCell(from: data)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Song", for: indexPath) as! SongCell
            
            if let data = self.content?.songs.retrieve(index: indexPath.row - 1) {
                cell.setupCell(from: data)
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 400
        } else {
            return 70
        }
    }
    
}

extension ContentViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        
        if offset < 200 {
            self.navigationHeight.constant = self.view.safeAreaInsets.top
            self.navigationTitle.text = ""
            
            self.navigationBlur.setNeedsLayout()
        } else if offset >= 200 || offset <= 300 {
            self.navigationHeight.constant = self.view.safeAreaInsets.top + (self.navigationBar.frame.height / (offset - 200))
            self.navigationTitle.textColor = UIColor.tertiarySystemBackground.withAlphaComponent((offset - 200) / 100)
            
            self.navigationBlur.setNeedsLayout()
        } else {
            self.navigationHeight.constant = self.view.safeAreaInsets.top + self.navigationBar.bounds.height
            self.navigationTitle.text = self.content?.name
        }
    }
    
}
