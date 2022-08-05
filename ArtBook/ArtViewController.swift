//
//  ArtViewController.swift
//  ArtBook
//
//  Created by Ranjan Akarsh on 05/08/22.
//

import UIKit
import PhotosUI
import CoreData

class ArtViewController: UIViewController, PHPickerViewControllerDelegate {
    @IBOutlet weak var artistLabel: UITextField!
    
    @IBOutlet weak var yearLabel: UITextField!
    @IBOutlet weak var paintingLabel: UITextField!
    @IBOutlet weak var artImageView: UIImageView!
    @IBOutlet weak var saveButton: UIButton!

    var artToShow: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.prepareForUser()
    }

    @IBAction func saveButton(_ sender: UIButton) {
        if self.validateFields() {
            self.saveToDatabase()
            self.navigationController?.popViewController(animated: true)
            // notify of the new data
            NotificationCenter.default.post(name: Notification.Name("newData"), object: nil)
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        self.dismiss(animated: true)
        
        results.first?.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { uiImage, error in
            guard let image = uiImage as? UIImage, error == nil else {
                return
            }
            DispatchQueue.main.async {
                self.artImageView.image = image
            }
        })
    }
    
    private func prepareForUser() {
        if artToShow != nil {
            self.yearLabel.isUserInteractionEnabled = false
            self.paintingLabel.isUserInteractionEnabled = false
            self.artistLabel.isUserInteractionEnabled = false
            self.artImageView.isUserInteractionEnabled = false
            self.saveButton.isHidden = true
            
            self.fetchFromDatabae(id: self.artToShow!)
        } else {
            self.yearLabel.isUserInteractionEnabled = true
            self.artistLabel.isUserInteractionEnabled = true
            self.paintingLabel.isUserInteractionEnabled = true
            self.artImageView.isUserInteractionEnabled = true
            self.saveButton.isHidden = false
            
            self.artImageView.image = UIImage(named: "choose_image")
            let pickGesture = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
            self.artImageView.addGestureRecognizer(pickGesture)
        }
    }
    
    @objc func openImagePicker() {
        print("tapped")
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .images
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = self
        self.present(controller, animated: true)
    }
    
    private func saveToDatabase() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let wrappedContext = delegate.persistentContainer.viewContext
        
        // saving
        let art = NSEntityDescription.insertNewObject(forEntityName: "Art", into: wrappedContext)
        art.setValue(UUID(), forKey: "id")
        art.setValue(self.artistLabel.text!, forKey: "artist_name")
        art.setValue(self.paintingLabel.text!, forKey: "painting_name")
        if let validatedYear = Int(self.yearLabel.text!) {
            art.setValue(validatedYear, forKey: "year")
        }
        
        let compressedImage = self.artImageView.image?.jpegData(compressionQuality: 0.5)
        art.setValue(compressedImage, forKey: "image")
        
        do {
            try wrappedContext.save()
        } catch {
            print("caught error - \(error)")
        }
    }
    
    private func fetchFromDatabae(id: UUID) {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let wrappedContext = delegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Art")
        fetchRequest.predicate = NSPredicate(format: "id = %@", self.artToShow!.uuidString)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try wrappedContext.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let artistName = result.value(forKey: "artist_name") as? String {
                        self.artistLabel.text = artistName
                    }
                    
                    if let paintingName = result.value(forKey: "painting_name") as? String {
                        self.paintingLabel.text = paintingName
                    }
                    
                    if let year = result.value(forKey: "year") as? Int {
                        self.yearLabel.text = String(year)
                    }
                    
                    if let image = result.value(forKey: "image") as? Data {
                        self.artImageView.image = UIImage(data: image)
                    }
                    
                }
            }
        } catch {
            print("error occcurred while fetching results = \(error)")
        }
    }
    
    private func validateFields() -> Bool {
        var message: String?
        if self.artistLabel.text!.isEmpty {
            message = "artist name cannot be empty"
        } else if self.paintingLabel.text!.isEmpty {
            message = "painting name cannot be empty"
        } else if self.yearLabel.text!.isEmpty {
            message = "year cannot be empty"
        }
        
        if let containsMesasge = message {
            let alert = UIAlertController(title: "error", message: containsMesasge, preferredStyle: .alert)
            let done = UIAlertAction(title: "done", style: .default)
            alert.addAction(done)
            self.present(alert, animated: true)
            return false
        }
        return true
    }
}
