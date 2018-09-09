//
//  ViewController.swift
//  Monash Companion App
//
//  Created by Decheng Ma on 10/8/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
import UserNotifications

//The main view of the app, Map View
class ViewController: UIViewController , CLLocationManagerDelegate,MKMapViewDelegate,UNUserNotificationCenterDelegate,AddAnimalProtocol,EditAnimalProtocol{
    let locationManager:CLLocationManager = CLLocationManager()
    @IBOutlet weak var myMapView: MKMapView!
    let userNotificationManager = UNUserNotificationCenter.current()
    var animalList:[AnimalCore] = []
    private var managedObjectContext:NSManagedObjectContext
    
    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = (appDelegate?.persistentContainer.viewContext)!
        super.init(coder: aDecoder)
    }

    //Set up the map function when the view loaded, fetch data from core data
    override func viewDidLoad() {
        super.viewDidLoad()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AnimalCore")
        do{
            animalList = try managedObjectContext.fetch(fetchRequest) as! [AnimalCore]
            if animalList.count == 0 {
                addAnimalData()
                animalList = try managedObjectContext.fetch(fetchRequest) as! [AnimalCore]
            }
            addAnno(animalList: animalList)
        }catch{
            fatalError("Failed to fetch animal:\(error)")
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        }
        let monashCaulfield = CLLocationCoordinate2D(latitude: CLLocationDegrees(-37.8770097), longitude: CLLocationDegrees(145.0420786))
        let viewRegion = MKCoordinateRegionMakeWithDistance(monashCaulfield, 600, 600)
        self.myMapView.setRegion(viewRegion, animated: true)
    }
    
    //When click on the list, change the camera of the mapview and put an circle
    func changeCamera(coordinate: CLLocationCoordinate2D) {
        let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 800, 800)
        self.myMapView.setRegion(viewRegion, animated: true)
        let circle = MKCircle(center:coordinate, radius: 150)
        self.myMapView.removeOverlays(myMapView.overlays)
        self.myMapView.add(circle)
    }
    
    func editAnimal(result: Bool) {
        viewDidLoad()
    }
    
    func addAnimal(result: Bool)  {
        viewDidLoad()
    }
    
    //https://stackoverflow.com/questions/33293075/how-to-create-mkcircle-in-swift
    //Make a circle when click
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay)
            circleRenderer.strokeColor = UIColor.blue
            circleRenderer.lineWidth = 1.0
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    //Add annotation of the animal on the map
    func addAnno(animalList:[AnimalCore]) {
        let allAnnotations = self.myMapView.annotations
        self.myMapView.removeAnnotations(allAnnotations)
        for an in animalList {
            let animalAnnotation = MKPointAnnotation()
            animalAnnotation.title = an.name
            animalAnnotation.subtitle = an.desc
            animalAnnotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(an.latitude), longitude: CLLocationDegrees(an.longitude))
            myMapView.addAnnotation(animalAnnotation)
        }
    }
    
    //Set up notification(alert)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation = locations.last
        let viewRegion = MKCoordinateRegionMakeWithDistance((userLocation?.coordinate)!, 600, 600)
        var animalName = ""
        var animalNear = false
        for animal in animalList{
            let location = CLLocation(latitude: CLLocationDegrees(animal.latitude), longitude: CLLocationDegrees(animal.longitude))
            let distance = userLocation?.distance(from: location)
            let withinDis:Double = 300
            if  distance! < withinDis{
                animalNear = true
                animalName = animalName +  "\(animal.name!.description),"
            }
        }
        animalName = String(animalName.dropLast(1))
        if(animalNear == true){
            let alert = UIAlertController(title: "Your are 300m near:\(animalName)", message: "Animals are nearby", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Cencel", style: .default, handler: {_ in }))
            self.present(alert,animated:true,completion:nil)
        }
        
        self.myMapView.setRegion(viewRegion, animated: true)
    }
    
    //Set up backgorund notification
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways  {
            for animal in animalList{
                let region = CLCircularRegion(center:CLLocationCoordinate2D(latitude: CLLocationDegrees(animal.latitude), longitude: CLLocationDegrees(animal.longitude)),
                                              radius: 300, identifier: animal.name!)
                region.notifyOnEntry = true
                region.notifyOnExit = false
                let trigger = UNLocationNotificationTrigger(region: region, repeats:true)
                let content = UNMutableNotificationContent()
                content.title = "You are near \(animal.name!) !"
                content.body = "Come and say hello to it!"
                content.sound = UNNotificationSound.default()

                let request = UNNotificationRequest(identifier: animal.name!, content: content, trigger: trigger)
                self.userNotificationManager.add(request) {(error) in
                    if let error = error {
                        print("Uh oh! We had an error: \(error)")
                    }
                }
            }
        }
    }
    
    //https://github.com/thecodepro/map-kit-tutorial-2/blob/master/map-kit-tutorial-2/ViewController.swift
    //Set up annotation view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "AnnotationView")
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationView")
        }
        for an in animalList{
            if let title = annotation.title, title == an.name{
                if an.iconName == "defaultMarker1" || an.iconName == "defaultMarker2"{
                    let bgImage = UIImage(named: an.iconName!)!
                    let changedBgImage = imageWithImage(image: bgImage, scaledToSize: CGSize(width: 60, height: 60) )
                    
                    let topImage = imageWithImage(image:loadImageData(fileName: an.infoImage!)!, scaledToSize: CGSize(width: 60, height: 60))
                    
                    let testimage = UIImage.imageByMergingImages(topImage: topImage, bottomImage: changedBgImage,type: an.iconName!)
                    annotationView?.image = testimage
                    
                }else{
                    let markerImage = UIImage(named: an.iconName!)
                    let changedImage = imageWithImage(image: markerImage!, scaledToSize: CGSize(width: 60.0, height: 60.0) )
                    annotationView?.image = changedImage
                }
                var infoImage:UIImage
                if an.iconName == "defaultMarker1" || an.iconName == "defaultMarker2" {
                     infoImage = imageWithImage(image:loadImageData(fileName: an.annoName!)! , scaledToSize: CGSize(width: 60.0, height: 60.0) )
                }else{
                     infoImage = imageWithImage(image:UIImage(named: an.annoName!)! , scaledToSize: CGSize(width: 60.0, height: 60.0) )
                }
                let leftCalloutImageView = UIImageView(image: infoImage)
                annotationView?.leftCalloutAccessoryView = leftCalloutImageView
            }
        }
        annotationView?.canShowCallout = true
        annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
    
        return annotationView
    }
    
    //When the annotation right infomation tap tapped
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let annView = view.annotation
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let animalinfoController = storyBoard.instantiateViewController(withIdentifier: "animalInfoIdentifer") as! AnimalInfoController
        animalinfoController.name = (annView?.title!)!
        animalinfoController.desc = chooseDesc(animalName: animalinfoController.name)
        var changedImage: UIImage? = nil
        for an in animalList{
            if animalinfoController.name == an.name{
                if  an.iconName == "defaultMarker1" || an.iconName == "defaultMarker2"
                {
                    changedImage = imageWithImage(image:loadImageData(fileName: an.infoImage!)!, scaledToSize: CGSize(width: 120.0, height: 90.0))
                }else{
                    changedImage = imageWithImage(image: UIImage(named: an.infoImage!)!, scaledToSize: CGSize(width: 120.0, height: 90.0))
                }
            }
        }
            animalinfoController.image = changedImage
    
        for an in self.animalList{
            if an.name == animalinfoController.name{
                self.geocode(latitude: Double(an.latitude), longitude: Double(an.longitude)) { placemark, error in
                    guard let placemark = placemark, error == nil else { return }
                    let address = "It's address is: \(placemark.subThoroughfare ?? ""),\(placemark.thoroughfare ?? ""),\n                  \(placemark.locality ?? ""),\(placemark.administrativeArea ?? ""),\(placemark.postalCode ?? "")"
                     animalinfoController.location = address
                }
            }
        }
        if animalinfoController.location == ""{
            DispatchQueue.global().async {
                sleep(1)
                DispatchQueue.main.async {
                    self.showController(animalinfoController: animalinfoController)
                }
            }
        }else{
            showController(animalinfoController: animalinfoController)
        }
    }
    
    //get into the animal information page
    func showController(animalinfoController: AnimalInfoController)  {
        self.present(animalinfoController, animated: true, completion: nil)
    }
    
    //generate the location based on coordinates
    func chooseLoc(animalName: String) -> String {
        var address = ""
        for an in self.animalList{
            if an.name == animalName{
                        self.geocode(latitude: Double(an.latitude), longitude: Double(an.longitude)) { placemark, error in
                            guard let placemark = placemark, error == nil else { return }
                                address = "\(placemark.subThoroughfare ?? ""),\(placemark.thoroughfare ?? ""),\n\(placemark.locality ?? ""),\(placemark.administrativeArea ?? ""),\(placemark.postalCode ?? "")"
                    }
                }
        }
        return address
    }
    
    //fetch the description for the animal
    func chooseDesc(animalName: String) -> String {
        var desc = ""
        for an in animalList{
            if an.name == animalName{
                desc =  an.infoDesc!
            }
        }
        return desc
    }
    
    //Resize the icon of marker https://stackoverflow.com/questions/39719139/change-the-size-of-marker-in-googlemap-using-swift
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // fetch image from database URL
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
    
    //reverse coordinate to address https://stackoverflow.com/questions/46869394/reverse-geocoding-in-swift-4
    func geocode(latitude: Double, longitude: Double, completionHandler: @escaping (CLPlacemark?, Error?) -> ())  {
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { completionHandler($0?.first, $1) }
        
    }
    
    //Set up segue
    //Changed at 10:45PM
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addAnimalSegue"{
            let controller : AddAnimalController = segue.destination as! AddAnimalController
            controller.addAnimalDelegate = self
        }else if segue.identifier == "listAnimalSegue"{
            let controller : AnimalListController = segue.destination as! AnimalListController
            controller.editAnimalDelegate = self
        }
    }
    
    func addAnimalData()  {
        var animal = NSEntityDescription.insertNewObject(forEntityName: "AnimalCore", into: managedObjectContext) as! AnimalCore
        animal.name = "Koala"
        animal.desc = "Baby Koala"
        animal.latitude = -37.8755972
        animal.longitude = 145.0415585
        animal.iconName = "koalaMarker"
        animal.annoName = "koalaAnnoInfo"
        animal.infoImage = "koalaInfo"
        animal.infoDesc = "The koala (Phascolarctos cinereus, or, inaccurately, koala bear[a]) is an arboreal herbivorous marsupial native to Australia. It is the only extant representative of the family Phascolarctidae and its closest living relatives are the wombats. The koala is found in coastal areas of the mainland's eastern and southern regions, inhabiting Queensland, New South Wales, Victoria, and South Australia. It is easily recognisable by its stout, tailless body and large head with round, fluffy ears and large, spoon-shaped nose. The koala has a body length of 60–85 cm (24–33 in) and weighs 4–15 kg (9–33 lb). Pelage colour ranges from silver grey to chocolate brown. Koalas from the northern populations are typically smaller and lighter in colour than their counterparts further south. These populations possibly are separate subspecies, but this is disputed."
        
        animal = NSEntityDescription.insertNewObject(forEntityName: "AnimalCore", into: managedObjectContext) as! AnimalCore
        animal.name = "Tiger"
        animal.desc = "Aussie baby tiger"
        animal.latitude = -37.8768764
        animal.longitude = 145.0435682
        animal.iconName = "tigerMarker"
        animal.annoName = "tigerAnnoInfo"
        animal.infoImage = "tigerInfo"
        animal.infoDesc = "The tiger (Panthera tigris) is the largest cat species, most recognizable for its pattern of dark vertical stripes on reddish-orange fur with a lighter underside. The species is classified in the genus Panthera with the lion, leopard, jaguar and snow leopard. It is an apex predator, primarily preying on ungulates such as deer and bovids. It is territorial and generally a solitary but social predator, often requiring large contiguous areas of habitat that support its prey requirements. This, coupled with the fact that it is indigenous to some of the more densely populated places on Earth, has caused significant conflicts with humans."
        
        animal = NSEntityDescription.insertNewObject(forEntityName: "AnimalCore", into: managedObjectContext) as! AnimalCore
        animal.name = "Panda"
        animal.desc = "Baby panda"
        animal.latitude = -37.8786757
        animal.longitude = 145.0440588
        animal.iconName = "pandaMarker"
        animal.annoName = "pandaAnnoInfo"
        animal.infoImage = "pandaInfo"
        animal.infoDesc = "The giant panda (Ailuropoda melanoleuca, literally black and white cat-foot; Chinese: 大熊猫; pinyin: dà xióng māo, literally big bear cat), also known as panda bear or simply panda, is a bear native to south central China.It is easily recognized by the large, distinctive black patches around its eyes, over the ears, and across its round body. The name giant panda is sometimes used to distinguish it from the unrelated red panda. Though it belongs to the order Carnivora, the giant panda's diet is over 99% bamboo. Giant pandas in the wild will occasionally eat other grasses, wild tubers, or even meat in the form of birds, rodents, or carrion. In captivity, they may receive honey, eggs, fish, yams, shrub leaves, oranges, or bananas along with specially prepared food."
        
        animal = NSEntityDescription.insertNewObject(forEntityName: "AnimalCore", into: managedObjectContext) as! AnimalCore
        animal.name = "Alpaca"
        animal.desc = "Melboure alpaca"
        animal.latitude = -37.8777521
        animal.longitude = 145.0406747
        animal.iconName = "alpacaMarker"
        animal.annoName = "alpacaAnnoInfo"
        animal.infoImage = "alpacaInfo"
        animal.infoDesc = "The Alpaca (Vicugna pacos) is a species of South American camelid, similar to, and often confused with the llama. However, alpacas are often noticeably smaller than llamas. The two animals are closely related, and can successfully cross-breed. Alpacas and llamas are also closely related to the Vicuña, which is believed to be the alpaca's wild ancestor, and to the Guanaco. There are two breeds of Alpaca: the Suri alpaca (es) and the Huacaya alpaca."
        
        animal = NSEntityDescription.insertNewObject(forEntityName: "AnimalCore", into: managedObjectContext) as! AnimalCore
        animal.name = "Kangaroo"
        animal.desc = "Caulfield kangaroo"
        animal.latitude = -37.8748659
        animal.longitude = 145.0421865
        animal.iconName = "kangarooMarker"
        animal.annoName = "kangarooAnnoInfo"
        animal.infoImage = "kangarooInfo"
        animal.infoDesc = "The kangaroo is a marsupial from the family Macropodidae (macropods, meaning \"large foot\"). In common use the term is used to describe the largest species from this family, especially those of the genus Macropus: the red kangaroo, antilopine kangaroo, eastern grey kangaroo, and western grey kangaroo. Kangaroos are indigenous to Australia. The Australian government estimates that 34.3 million kangaroos lived within the commercial harvest areas of Australia in 2011, up from 25.1 million one year earlier."
        
        do{
            try managedObjectContext.save()
        }catch let error{
            print("Could not save Core Data:\(error)")
        }
    }
    
}

// Set up the overlay of the image(when selected, put the image on the marker frame)
extension UIImage {
    static func imageByMergingImages(topImage: UIImage, bottomImage: UIImage,type:String, scaleForTop: CGFloat = 1.0) -> UIImage {
        let size = bottomImage.size
        let container = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        UIGraphicsGetCurrentContext()!.interpolationQuality = .high
        if(type == "defaultMarker2"){
             bottomImage.draw(in: container)
             topImage.draw(in: CGRect(x: 13, y: 8, width: 35, height: 25), blendMode: .normal, alpha: 1.0)
        }else{
            topImage.draw(in: CGRect(x: 16, y: 9, width: 25, height: 20), blendMode: .normal, alpha: 1.0)
            bottomImage.draw(in: CGRect(x: 0, y: 0, width: 60, height: 60), blendMode: .normal, alpha: 1.0)
        }
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}

