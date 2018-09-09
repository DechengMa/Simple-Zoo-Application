//
//  AnimalListController.swift
//  Monash Companion App
//
//  Created by Decheng Ma on 10/8/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import CoreData
import MapKit

protocol EditAnimalProtocol {
    func editAnimal(result:Bool)
    func changeCamera(coordinate:CLLocationCoordinate2D)
}

//Set up the list view of the animal
class AnimalListController: UITableViewController,UISearchResultsUpdating{
    private var animalList:[AnimalCore] = []
    private var managedObjectContext:NSManagedObjectContext
    private let SECTION_ANIMALS = 0
    private let SECTION_COUNT = 1
    var editAnimalDelegate: EditAnimalProtocol?
    var filtererList = [AnimalCore]()
    let searchController = UISearchController(searchResultsController: nil)
    
    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = (appDelegate?.persistentContainer.viewContext)!
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.splitViewController?.preferredDisplayMode = .allVisible
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AnimalCore")
        do{
            let fetchedAnimal = try managedObjectContext.fetch(fetchRequest) as! [AnimalCore]
            animalList = fetchedAnimal
        }catch{
            fatalError("Failed to fetch animal:\(error)")
        }
        filtererList = animalList
        self.navigationItem.leftItemsSupplementBackButton = true
        searchController.definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Animal"
        navigationItem.searchController = searchController
    }

    // MARK: - Table view data source
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text,searchText.count > 0{
            filtererList = animalList.filter({(animal:AnimalCore) ->Bool in return
                (animal.name?.contains(searchText))!})
            
        }else{
            filtererList = animalList
        }
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        //return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return the number of rows
        switch (section) {
        case 0:
            return  self.filtererList.count
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    //If the mobile is portrait, you can go back to map, else not
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch UIDevice.current.orientation{
            case .portrait:
                return true
            case .portraitUpsideDown:
                return true
            case .landscapeLeft:
                let alert = UIAlertController(title: "Hint", message: "You can't go back to map when your mobile is in a landscape mode!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cencel", style: .default, handler: { _ in
                }))
                self.present(alert,animated: true,completion: nil)
                return false
            case .landscapeRight:
                let alert = UIAlertController(title: "Hint", message: "You can't go back to map when your mobile is in a landscape mode!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cencel", style: .default, handler: { _ in
                }))
                self.present(alert,animated: true,completion: nil)
                return false
            default:
                return true
        }
    }
    
    //Set up the delete function
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == SECTION_ANIMALS{
            return .delete
        }
        return .none
    }
    
     //Set up the delete function
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let alert = UIAlertController(title: "Confirm delete", message: "Sure to delete this animal?", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Cencel", style: UIAlertActionStyle.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: {
                action in
                let deleteAnimal = self.filtererList.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.reloadSections([self.SECTION_COUNT], with: .automatic)
                self.managedObjectContext.delete(deleteAnimal)
                self.saveData()
                self.editAnimalDelegate?.editAnimal(result: true)
                
//                self.navigationController?.popViewController(animated: true)
//                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert,animated: true,completion: nil)
        }
    }

    func saveData()  {
        do{
            try managedObjectContext.save()
        }catch let error{
            print("Could not save Core Data:\(error)")
        }
    }
    
    //Set up the Cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.section == 0){
            let cell = tableView.dequeueReusableCell(withIdentifier: "AnimalCell", for: indexPath) as!AnimalListCell
            self.tableView.rowHeight = 120;
            var changedImage:UIImage
            if  filtererList[indexPath.row].iconName == "defaultMarker1" || filtererList[indexPath.row].iconName == "defaultMarker2"{
                cell.cellName.text = filtererList[indexPath.row].name
                cell.cellDesc.text  = filtererList[indexPath.row].infoDesc
                changedImage = imageWithImage(image: loadImageData(fileName: filtererList[indexPath.row].annoName!)!, scaledToSize: CGSize(width: 120.0, height: 120.0))
            }else{
                changedImage = imageWithImage(image: UIImage(named: filtererList[indexPath.row].annoName!)!, scaledToSize: CGSize(width: 120.0, height: 120.0))
                cell.cellName.text = filtererList[indexPath.row].name
                cell.cellDesc.text = filtererList[indexPath.row].desc
            }
            cell.cellImage.image = changedImage
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "TotalCell", for: indexPath)
            cell.textLabel!.text = "Total Animal \(filtererList.count)"
            return cell
        }
    }
    
    //Resize the image
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    //https://www.youtube.com/watch?v=tQVvRcF7Z7E
    //Sort the list
    @IBAction func sortBtn(_ sender: Any) {
        let alert   = UIAlertController(title: "Sort It", message: "How do you wish to sort it?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "A-Z", style: .default, handler: {_ in
            self.filtererList.sort(by: {$0.name! < $1.name!})
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Z-A", style: .default, handler: {_ in
            self.filtererList.sort(by: {$0.name! > $1.name!})
            self.tableView.reloadData()
        }))
        self.present(alert,animated: true,completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewDidLoad()
        tableView.reloadData()
    }
    
    //Set the delegate, send the data back to map view(There is a judgement here about the orientation of the device)
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch UIDevice.current.orientation{
            case .portrait:
                let alert = UIAlertController(title: "Hint", message: "The camera is relocate, change the mobile to landscape to see the effect (Split view is not suit iPhone well)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cencel", style: .default, handler: { _ in
                }))
                self.present(alert,animated: true,completion: nil)
                break
            case .portraitUpsideDown:
                let alert = UIAlertController(title: "Hint", message: "The camera relocate function need you to change the mobile to landscape to see the effect (Split view is not suit iPhone well)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cencel", style: .default, handler: { _ in
                }))
                self.present(alert,animated: true,completion: nil)
                break
            case .landscapeLeft:
                let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(filtererList[indexPath.row].latitude), longitude: CLLocationDegrees(filtererList[indexPath.row].longitude))
                searchController.isActive = false
                self.editAnimalDelegate?.changeCamera(coordinate: coordinate)
                
                break
            case .landscapeRight:
                let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(filtererList[indexPath.row].latitude), longitude: CLLocationDegrees(filtererList[indexPath.row].longitude))
                searchController.isActive = false
                self.editAnimalDelegate?.changeCamera(coordinate: coordinate)
                break
            default:
                let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(filtererList[indexPath.row].latitude), longitude: CLLocationDegrees(filtererList[indexPath.row].longitude))
                searchController.isActive = false
                self.editAnimalDelegate?.changeCamera(coordinate: coordinate)
                let alert = UIAlertController(title: "Hint", message: "The camera is relocated, change the mobile to landscape to see the effect (Split view is not suit iPhone well)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cencel", style: .default, handler: { _ in
                }))
                self.present(alert,animated: true,completion: nil)
                break
        }
    }
    
    
    // fetch image from firebase URL
    func loadImageData(fileName: String) -> UIImage? {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        var image: UIImage?
        if let pathComponent = url.appendingPathComponent(fileName) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            let fileData = fileManager.contents(atPath: filePath)
            image = UIImage(data: fileData!)
        }
        return image
    }
    
}
