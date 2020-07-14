//
//  ChooseSessionContentViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 21/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

protocol SelectedContentFeedback {
    func contentSelected(_ content: [Music.Content])
}

class ChooseSessionContentViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var contentCollection: UICollectionView!
    @IBOutlet weak private var continueButton: UIButton!
    
    // MARK: Properties
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentCollection.alpha = 0
        
        if SessionManager.current.setup == nil {
            SessionManager.current.setupSession(from: [])
            self.contentCollection.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.animate(withDuration: 0.4) {
            self.contentCollection.alpha = 1
            self.continueButton.alpha = (SessionManager.current.setup?.content.isEmpty ?? false) ? 0 : 1
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIView.animate(withDuration: 0.4) {
            self.contentCollection.alpha = 0
            self.continueButton.alpha = 0
        }
    }
    
    func reloadView() {
        DispatchQueue.main.async {
            self.contentCollection.reloadData()
            
            UIView.animate(withDuration: 0.4) {
                self.contentCollection.alpha = 1
                self.continueButton.alpha = (SessionManager.current.setup?.content.isEmpty ?? false) ? 0 : 1
            }
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
        if SessionManager.current.setup?.content.isEmpty ?? false { return }
        self.performSegue(withIdentifier: "Session Parameter Setup", sender: self)
    }

}

extension ChooseSessionContentViewController: SelectedContentFeedback {
    
    func contentSelected(_ content: [Music.Content]) {
        SessionManager.current.setupSession(from: content)
        
        DispatchQueue.main.async {
            self.reloadView()
        }
    }
    
}

extension ChooseSessionContentViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = SessionManager.current.setup?.content.count {
            return 1 + count
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == (SessionManager.current.setup?.content.count ?? Int.max) {
            // This will always be the last cell
            return collectionView.dequeueReusableCell(withReuseIdentifier: "Add Content", for: indexPath) as! AddContentCell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Content", for: indexPath) as! ContentSelectionCell
            
            if let data = SessionManager.current.setup?.content.retrieve(index: indexPath.item) {
                cell.optionsDelegate = self
                cell.setupCell(from: data, index: indexPath.item)
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        if indexPath.item == (SessionManager.current.setup?.content.count ?? Int.max) {
            self.performSegue(withIdentifier: "Choose Content", sender: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == (SessionManager.current.setup?.content.count ?? Int.max) {
            return CGSize(width: self.contentCollection.bounds.width / 1.5, height: 60)
        } else {
            return CGSize(width: self.contentCollection.bounds.width, height: 100)
        }
    }
    
}

extension ChooseSessionContentViewController: ContentOptionsPresenter {
    
    func presentOptions(for content: Music.Content, at index: Int) {
        let sheet = UIAlertController(title: "Options for \(content.name)", message: nil, preferredStyle: .actionSheet)
        
        let remove = UIAlertAction(title: "Remove from Sesion", style: .destructive) { (_) in
            SessionManager.current.setup?.removeIndexOfContent(index)
            self.reloadView()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        sheet.addAction(remove)
        sheet.addAction(cancel)
        
        DispatchQueue.main.async {
            self.present(sheet, animated: true, completion: nil)
        }
    }
    
}
