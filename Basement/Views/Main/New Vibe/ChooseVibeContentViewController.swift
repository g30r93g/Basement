//
//  ChooseVibeContentViewController.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 21/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

protocol SelectedContentFeedback {
    func contentSelected(_ content: [Music.Content])
}

class ChooseVibeContentViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var contentCollection: UICollectionView!
    
    // MARK: Properties
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if VibeManager.current.currentVibeSetup == nil {
            VibeManager.current.setupVibe(from: [])
            self.contentCollection.reloadData()
        }
    }
    
    // MARK: Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Choose Content" {
            let destVC = segue.destination as! ChooseContentViewController
            
            destVC.feedbackDelegate = self
        }
    }
    
    // MARK: IBActions
    @IBAction private func continueTapped(_ sender: UIButton) {
        if VibeManager.current.currentVibeSetup?.content.isEmpty ?? false { return }
        self.performSegue(withIdentifier: "Vibe Parameter Setup", sender: self)
    }

}

extension ChooseVibeContentViewController: SelectedContentFeedback {
    
    func contentSelected(_ content: [Music.Content]) {
        VibeManager.current.setupVibe(from: content)
        
        DispatchQueue.main.async {
            self.contentCollection.reloadData()
        }
    }
    
}

extension ChooseVibeContentViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = VibeManager.current.currentVibeSetup?.content.count {
            return 1 + count
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == (VibeManager.current.currentVibeSetup?.content.count ?? Int.max) {
            // This will always be the last cell
            return collectionView.dequeueReusableCell(withReuseIdentifier: "Add Content", for: indexPath) as! AddContentCell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Content", for: indexPath) as! ContentSelectionCell
            
            if let data = VibeManager.current.currentVibeSetup?.content.retrieve(index: indexPath.item) {
                cell.setupCell(from: data)
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        if indexPath.item == (VibeManager.current.currentVibeSetup?.content.count ?? Int.max) {
            self.performSegue(withIdentifier: "Choose Content", sender: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == (VibeManager.current.currentVibeSetup?.content.count ?? Int.max) {
            return CGSize(width: self.contentCollection.bounds.width / 1.5, height: 60)
        } else {
            return CGSize(width: self.contentCollection.bounds.width, height: 100)
        }
    }
    
}
