//
//  AnimalInfoController.swift
//  Monash Companion App
//
//  Created by Decheng Ma on 10/8/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit

class AnimalInfoController: UIViewController {
    
    @IBOutlet weak var animalName: UILabel!
    @IBOutlet weak var animalImage: UIImageView!
    @IBOutlet weak var animalDesc: UITextView!
    @IBOutlet weak var animalLocation: UILabel!
    
    var name = ""
    var desc = ""
    var location = ""
    var image:UIImage? = nil
    
    @IBAction func backBtn(_ sender: Any) {
        //self.navigationController!.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        animalName.text = name
        animalDesc.text = desc
        animalLocation.text = location
        animalImage.image = image
    }

}
