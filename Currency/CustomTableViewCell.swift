//
//  CustomTableViewCell.swift
//  Currency
//
//  Created by admin on 14/03/2018.
//  Copyright © 2018 WIT. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var currencySymbol: UILabel!
    @IBOutlet weak var currencyValue: UILabel!
    @IBOutlet weak var currencyFlag: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
