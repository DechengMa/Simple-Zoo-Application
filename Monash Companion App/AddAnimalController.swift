//
//  AddAnimalController.swift
//  Monash Companion App
//
//  Created by Decheng Ma on 18/8/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import CoreData
import MapKit

protocol AddAnimalProtocol {
//    func addAnimal(animal:AnimalCore) -> Bool
    func addAnimal(result:Bool)
}

class AddAnimalController: UIViewController,ChooseLocationDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    var imagePicker = UIImagePickerController()
    var choosedLocation :CLLocationCoordinate2D?
    var animalList:[AnimalCore] = []
    var addAnimalDelegate :AddAnimalProtocol?
    let locationManager:CLLocationManager = CLLocationManager()
    private var managedObjectContext:NSManagedObjectContext
    var mapicon:String  = ""
    
    @IBOutlet weak var animalName: UITextField!
    @IBOutlet weak var animalDesc: UITextField!
    @IBOutlet weak var mapIcon1: UIImageView!
    @IBOutlet weak var mapIcon2: UIImageView!
    @IBOutlet weak var choosedLatitude: UILabel!
    @IBOutlet weak var choosedPic: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = (appDelegate?.persistentContainer.viewContext)!
        super.init(coder: aDecoder)
    }

    //Set an gesture recongizer for choosing icon, set UI
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        scrollView.contentSize = CGSize(width: 414, height: 736)
        self.animalName.layer.borderColor = UIColor.gray.cgColor
        self.animalName.layer.borderWidth = 1.0
        self.animalDesc.layer.borderColor = UIColor.gray.cgColor
        self.animalDesc.layer.borderWidth = 1.0
        
        let tapGestureRecognizer1 = UITapGestureRecognizer(target: self, action: #selector(AddAnimalController.chooseIcon1(_:)))
        let tapGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(AddAnimalController.chooseIcon2(_:)))
        self.mapIcon1.isUserInteractionEnabled = true
        self.mapIcon1.addGestureRecognizer(tapGestureRecognizer1)
        self.mapIcon2.isUserInteractionEnabled = true
        self.mapIcon2.addGestureRecognizer(tapGestureRecognizer2)
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AnimalCore")
        do{
            animalList = try managedObjectContext.fetch(fetchRequest) as![AnimalCore]
        }catch{
            fatalError("Failed to fetch animals:\(error)")
        }
    }
    
    //Validation implement here, handle the data storing and validation when user click add animal
    @IBAction func addFinish(_ sender: Any){
        for animal in animalList{
            if self.animalName.text == animal.name{
                let alert  = UIAlertController(title: "Sorry, there is already a animal called this name", message: "please change a new name!", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Cencel", style: UIAlertActionStyle.default, handler: { action in
                }))
                self.present(alert, animated: true, completion: nil)
                return
            }
        }
        
        let response = Validation.shared.validate(values: (Validation.ValidationType.stringWithFirstLetterCaps,self.animalName.text!),(Validation.ValidationType.alphabeticString,self.animalDesc.text!))
        switch response {
        case .success:
            break
        case .failure(_, let message):
            let alert  = UIAlertController(title: "Invaild Input", message: message.localized(), preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Cencel", style: UIAlertActionStyle.default, handler: { action in
                }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if mapicon == ""{
            let alert  = UIAlertController(title: "Please select an valid Icon ", message: "Please check agagin", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Cencel", style: UIAlertActionStyle.default, handler: { action in
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if choosedLocation?.latitude == nil{
            let alert  = UIAlertController(title: "Please select an location", message: "Please check agagin", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Cencel", style: UIAlertActionStyle.default, handler: { action in
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        
        guard let image = choosedPic.image else {
            let alert  = UIAlertController(title: "Please select an valid photo", message: "Please check agagin", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Cencel", style: UIAlertActionStyle.default, handler: { action in
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        // if all validation passed
        let date = UInt(Date().timeIntervalSince1970)
        var data = Data()
        data = UIImageJPEGRepresentation(image, 0.8)!
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("\(date)"){
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            fileManager.createFile(atPath: filePath, contents: data, attributes: nil)
            let newAnimal = NSEntityDescription.insertNewObject(forEntityName: "AnimalCore", into: managedObjectContext) as! AnimalCore
            newAnimal.infoImage = "\(date)"
            newAnimal.name = self.animalName.text!
            newAnimal.infoDesc = self.animalDesc.text!
            newAnimal.desc = self.animalDesc.text!
            newAnimal.latitude = Float((choosedLocation?.latitude)!)
            newAnimal.longitude = Float((choosedLocation?.longitude)!)
            newAnimal.iconName = mapicon
            newAnimal.annoName = newAnimal.infoImage
            saveData()
        }
        self.addAnimalDelegate?.addAnimal(result: true)
        _ =  navigationController?.popViewController(animated: true)
        //_ = navigationController?.popToRootViewController(animated: true)
        //dismiss(animated: true, completion: nil)
    }
    
    //If the icon 1 was chosen
    @objc func chooseIcon1(_ sender:AnyObject){
        self.mapIcon2.layer.borderWidth = 0
        self.mapIcon1.layer.borderWidth = 1
        self.mapIcon1.layer.borderColor = UIColor.black.cgColor
        self.mapicon = "defaultMarker1"
    }
    
    //if the icon2 was chosen
    @objc func chooseIcon2(_ sender:AnyObject){
        self.mapIcon1.layer.borderWidth = 0
        self.mapIcon2.layer.borderWidth = 1
        self.mapIcon2.layer.borderColor = UIColor.black.cgColor
        self.mapicon = "defaultMarker2"
    }
    
    //Geofencing, reverse coordinate data to address
    func chooseLocation(coordinate: CLLocationCoordinate2D) {
        choosedLocation = coordinate
        choosedLatitude.text = "Your choosed is:"+(choosedLocation?.latitude.description)!
        geocode(latitude: (choosedLocation?.latitude)!, longitude: (choosedLocation?.longitude)!) { placemark, error in
            guard let placemark = placemark, error == nil else { return }
            DispatchQueue.main.async {
                let address = "\(placemark.subThoroughfare ?? ""),\(placemark.thoroughfare ?? ""),\n\(placemark.locality ?? ""),\(placemark.administrativeArea ?? ""),\(placemark.postalCode ?? "")"
                self.choosedLatitude.text = "Your selected location is: \n"+address
            }
        }
    }
    
    func saveData()  {
        do{
            try managedObjectContext.save()
        }catch let error{
            print("Could not save Core Data:\(error)")
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChooseLocationoSegue" {
            let controller : ChooseLocationController = segue.destination as! ChooseLocationController
            controller.delegate = self
        }
    }
    
    //https://stackoverflow.com/questions/41717115/how-to-uiimagepickercontroller-for-camera-and-photo-library-in-the-same-time-in
    //Choose picture function
    @IBAction func choosePicture(_ sender: Any) {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery()
            }))
        alert.addAction(UIAlertAction(title: "Cancel", style:.default , handler: nil))
        self.present(alert,animated: true,completion: nil)
    }
    
    func openCamera(){
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.camera))
            {
                imagePicker.sourceType = UIImagePickerControllerSourceType.camera
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
            else
            {
                let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    //Open gallery to choose picture for animal
    func openGallery() {
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        self.present(imagePicker,animated: true,completion: nil)
    }
    
    //Pick up the image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            choosedPic.image = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    //https://stackoverflow.com/questions/46869394/reverse-geocoding-in-swift-4
    //Reverse coordinate to readable address
    func geocode(latitude: Double, longitude: Double, completion: @escaping (CLPlacemark?, Error?) -> ())  {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                completion(nil, error)
                return
            }
            completion(placemark, nil)
        }
    }
    
}

extension AddAnimalController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddAnimalController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

