//
//  ForecastTableViewCell.swift
//  SecondWeather
//
//  Created by 이수한 on 2018. 3. 3..
//  Copyright © 2018년 이수한. All rights reserved.
//

import UIKit

class ForecastTableViewCell: UITableViewCell {
    static let identifier = "ForecastTableViewCell"

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        backgroundColor = UIColor.clear
        
        statusLabel.textColor = UIColor.white
        dateLabel.textColor = statusLabel.textColor
        timeLabel.textColor = statusLabel.textColor
        temperatureLabel.textColor = statusLabel.textColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
