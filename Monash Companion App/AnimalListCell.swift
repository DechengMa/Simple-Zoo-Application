//
//  AnimalListCell.swift
//  Monash Companion App
//
//  Created by Decheng Ma on 12/8/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit

class AnimalListCell: UITableViewCell {
    
    @IBOutlet weak var cellName: UILabel!
    @IBOutlet weak var cellDesc: UILabel!
    @IBOutlet weak var cellImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
