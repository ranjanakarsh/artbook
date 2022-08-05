//
//  ViewController.swift
//  ArtBook
//
//  Created by Ranjan Akarsh on 05/08/22.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var arrayOfPaints = [String]()
    var arrayOfIds = [UUID]()
    
    let cellIdentifier = "artist_cell"
    
    var wantsToEdit: Bool = false
    var idToShow: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.fetchFromDatabase()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.idToShow = nil
        NotificationCenter.default.addObserver(self, selector: #selector(fetchFromDatabase), name: Notification.Name("newData"), object: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrayOfPaints.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = self.arrayOfPaints[indexPath.row]
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.wantsToEdit = false
        self.idToShow = self.arrayOfIds[indexPath.row]
        self.performSegue(withIdentifier: "toArtView", sender: nil)
    }

    @IBAction func plusButton(_ sender: UIBarButtonItem) {
        self.wantsToEdit = true
        self.performSegue(withIdentifier: "toArtView", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toArtView" {
            let destination = segue.destination as! ArtViewController
            if self.idToShow != nil {                
                destination.artToShow = self.idToShow!
            }
        }
    }
    
    @objc func fetchFromDatabase() {
        self.arrayOfPaints.removeAll(keepingCapacity: false)
        self.arrayOfIds.removeAll(keepingCapacity: false)
        
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = delegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Art")
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let name = result.value(forKey: "painting_name") as? String {
                        self.arrayOfPaints.append(name)
                    }
                    
                    if let id = result.value(forKey: "id") as? UUID {
                        self.arrayOfIds.append(id)
                    }
                }
                
                self.tableView.reloadData()
            }
        } catch {
            print("error occurred - \(error)")
        }
    }
}

