//
//  Model.swift
//  SecondWeather
//
//  Created by 이수한 on 2018. 3. 3..
//  Copyright © 2018년 이수한. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Forecast {
    let date: Date
    let skyName: String
    let skyCode: String
    let temperature: Double
}

struct WeatherSummary {
    let skyName: String
    let skyCode: String
    
    let tempCurrent: Double
    let tempMax: Double
    let tempMin: Double
    
    init?(json: JSON) {
        print(json)
        
        guard let info = json["weather"].dictionary?["minutely"]?.array?.first else { fatalError() }
        
        guard let sky = info["sky"].dictionary else { fatalError() }
        
        guard let name = sky["name"]?.string else { fatalError() }
        skyName = name
        
        guard let code = sky["code"]?.string else { fatalError() }
        skyCode = code
        
        guard let temperature = info["temperature"].dictionary else { fatalError() }
        
        guard let current = temperature["tc"]?.string else { fatalError() }
        tempCurrent = Double(current) ?? 0.0
        
        guard let max = temperature["tmax"]?.string else { fatalError() }
        tempMax = Double(max) ?? 0.0
        
        guard let min  = temperature["tmin"]?.string else { fatalError() }
        tempMin = Double(min) ?? 0.0
    }
}
