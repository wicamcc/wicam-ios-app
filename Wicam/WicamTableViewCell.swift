//
//  WicamTableViewCell.swift
//  Wicam
//
//  Created by Yunfeng Liu on 2016-06-19.
//  Copyright © 2016 Armstart. All rights reserved.
//

import UIKit

class WicamTableViewCell: UITableViewCell {
    
    // MARK: Property
    
    @IBOutlet weak var ssidLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
