//
//  ChooseLocationController.swift
//  Monash Companion App
//
//  Created by Decheng Ma on 19/8/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import MapKit

protocol ChooseLocationDelegate {
    func chooseLocation(coordinate:CLLocationCoordinate2D)
}

//This controller is in charge of the choosing location function for adding animal
class ChooseLocationController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {
    var count = 0
    var location:CLLocationCoordinate2D? = nil
    var delegate:ChooseLocationDelegate?
    let locationManager:CLLocationManager = CLLocationManager()
    
    @IBOutlet weak var myMapView: MKMapView!
    @IBAction func finishSelect(_ sender: Any) {
        handleChoose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        let monashCaulfield = CLLocationCoordinate2D(latitude: CLLocationDegrees(-37.8770097), longitude: CLLocationDegrees(145.0420786))
        let viewRegion = MKCoordinateRegionMakeWithDistance(monashCaulfield, 600, 600)
        self.myMapView.setRegion(viewRegion, animated: true)
        
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(ChooseLocationController.handleLongPress(_:)))
        longPressRecogniser.minimumPressDuration = 1.0
        myMapView.addGestureRecognizer(longPressRecogniser)
    }
    
    // set the default view of the map when choosing location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
         let monashCaulfield = CLLocationCoordinate2D(latitude: CLLocationDegrees(-37.8770097), longitude: CLLocationDegrees(145.0420786))
        let viewRegion = MKCoordinateRegionMakeWithDistance(monashCaulfield, 600, 600)
        self.myMapView.setRegion(viewRegion, animated: true)
    }
    
    //https://stackoverflow.com/questions/3959994/how-to-add-a-push-pin-to-a-mkmapviewios-when-touching
    //long press to choose pin on the map
    @objc func handleLongPress(_ gestureRecognizer : UIGestureRecognizer)  {
        if count >= 1 {
            print("Only one is ok")
        }else{
            let choosedPin = MKPointAnnotation()
            if gestureRecognizer.state != .began{return}
            let touchPoint = gestureRecognizer.location(in: myMapView)
            let touMapCoordinate = myMapView.convert(touchPoint, toCoordinateFrom: myMapView)
            location = touMapCoordinate
            choosedPin.coordinate = touMapCoordinate
            myMapView.addAnnotation(choosedPin)
            count += 1
        }
    }
    
    //Set up the rules for choosing location
    func handleChoose(){
        if self.location != nil {
            
        }else{
            let alert1 = UIAlertController(title: "You must choose a location", message: "Long press to choose a location", preferredStyle: UIAlertControllerStyle.alert)
            alert1.addAction(UIAlertAction(title: "Cencel", style: UIAlertActionStyle.default,handler:{action in
            }))
            self.present(alert1, animated: true, completion: nil)
        }
        
        let alert = UIAlertController(title: "Location Selected?", message: "Do you want to select this location for the new animal?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cencel", style: UIAlertActionStyle.default, handler: {action in
            self.myMapView.removeAnnotations(self.myMapView.annotations)
            self.count  = 0
            self.location = nil
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            if self.location != nil{
                self.delegate?.chooseLocation(coordinate: self.location!)
            }else{
                
            }
            self.navigationController?.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }

}
