//
//  ViewController.swift
//  SecondWeather
//
//  Created by 이수한 on 2018. 3. 3..
//  Copyright © 2018년 이수한. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    @IBOutlet weak var locationLabel: UILabel!
    
    var whiteMode = false
    
    lazy var locationManager: CLLocationManager = {
        let m = CLLocationManager()
        m.delegate = self
        
        return m
    }()
    
    lazy var df = DateFormatter()
    
    @IBOutlet weak var listTableView: UITableView!
    
    var summary: WeatherSummary?
    var forecast = [Forecast]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        listTableView.backgroundColor = UIColor.clear
        listTableView.separatorStyle = .none
        listTableView.estimatedRowHeight = 100
        listTableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        locationLabel.text = "업데이트 중..."
        
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                updateCurrentLocation()
            case .denied, .restricted:
                show(message: "위치 서비스 사용 불가")
            }
        } else {
            show(message: "위치 서비스 사용 불가")
        }
    }
    
    func fetchSummaryData(coordinate: CLLocationCoordinate2D) {
        let urlStr = "https://api2.sktelecom.com/weather/current/minutely?version=1&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appKey=\(appKey)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        guard let url = URL(string: urlStr) else { fatalError() }
        
        Alamofire.request(url, method: .get).responseJSON { [weak self] (response) in
            guard response.result.isSuccess else {
                return
            }
            
            guard let data = response.result.value as? [String: Any] else {
                return
            }
            
            let json = JSON(data)
            
            guard let summary = WeatherSummary(json: json) else {
                return
            }
            
            self?.summary = summary
            
            DispatchQueue.main.async {
                self?.listTableView.reloadData()
            }
        }
    }
    
    func fetchForecast(coordinate: CLLocationCoordinate2D) {
        let urlStr = "https://api2.sktelecom.com/weather/forecast/3days?version=1&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appKey=\(appKey)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        print(urlStr)
        
        guard let url = URL(string: urlStr) else { fatalError() }
        
        Alamofire.request(url, method: .get).responseJSON { [weak self] (response) in
            guard response.result.isSuccess else {
                return
            }
            
            guard let data = response.result.value as? [String: Any] else {
                return
            }
            
            let json = JSON(data)
            
            self?.forecast.removeAll()
            
            let comps = Calendar.current.dateComponents([.month, .day, .hour], from: Date())
            
            guard let now = Calendar.current.date(from: comps) else {
                return
            }
            
            if let forecastDict = json["weather"]["forecast3days"][0]["fcst3hour"].dictionary {
                var hour = 4
                
                while hour <= 67 {
                    defer {
                        hour += 3
                    }
                    guard let skyName = forecastDict["sky"]?["name\(hour)hour"].string, skyName.count > 0 else { continue }
                    
                    guard let skyCode = forecastDict["sky"]?["code\(hour)hour"].string, skyCode.count > 0 else { continue }
                    
                    guard let temperature = forecastDict["temperature"]?["temp\(hour)hour"].string, temperature.count > 0 else { continue }
                    
                    let dbl = Double(temperature) ?? 0.0
                    
                    let dt = now.addingTimeInterval(TimeInterval(hour * 3600))
                    
                    let newData = Forecast(date: dt, skyName: skyName, skyCode: skyCode, temperature: dbl)
                    
                    self?.forecast.append(newData)
                }
            }
            DispatchQueue.main.async {
                self?.listTableView.reloadData()
            }
        }
    }
    
    var topInset: CGFloat = 0.0
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if topInset == 0.0 {
            let first = IndexPath(row: 0, section: 0)
            
            if let cell = listTableView.cellForRow(at: first) {
                topInset = listTableView.frame.height - cell.frame.height
                listTableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0)
            }
        }
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return forecast.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: SummaryTableViewCell.identifier) as! SummaryTableViewCell
            
            if let data = summary {
                cell.weatherImageView.image = UIImage(named: data.skyCode)
                cell.statusLabel.text = data.skyName
                cell.minMaxLabel.text = "최대 \(data.tempMax)°  최소 \(data.tempMin)°"
                cell.currentTemperatureLabel.text = "\(data.tempCurrent)°"
                
                cell.indicator.isHidden = true
            } else {
                cell.indicator.isHidden = false
            }
            
            cell.weatherImageView.isHidden = !cell.indicator.isHidden
            cell.statusLabel.isHidden = !cell.indicator.isHidden
            cell.minMaxLabel.isHidden = !cell.indicator.isHidden
            cell.currentTemperatureLabel.isHidden = !cell.indicator.isHidden
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ForecastTableViewCell.identifier) as! ForecastTableViewCell
        
        let target = forecast[indexPath.row]
        
        df.dateFormat = "M.d (E)"
        cell.dateLabel.text = df.string(for: target.date)
        
        df.dateFormat = "HH:mm"
        cell.timeLabel.text = df.string(for: target.date)
        
        cell.weatherImageView.image = UIImage(named: target.skyCode)
        
        cell.statusLabel.text = target.skyName
        
        cell.temperatureLabel.text = "\(target.temperature)°"
        
        return cell
    }
}

extension ViewController {
    func show(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "확인", style: .default, handler: nil)
        alert.addAction(ok)
        
        present(alert, animated: true, completion: nil)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func updateCurrentLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            updateCurrentLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.first {
            let decoder = CLGeocoder()
            decoder.reverseGeocodeLocation(loc, completionHandler: { (placemarks, error) in
                if let place = placemarks?.first {
                    if let gu = place.locality, let dong = place.subLocality {
                        self.locationLabel.text = "\(gu) \(dong)"
                    } else {
                        self.locationLabel.text = place.name
                    }
                }
            })
            fetchSummaryData(coordinate: loc.coordinate)
            fetchForecast(coordinate: loc.coordinate)
        }
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y
        
        if y <= -30 {
            if !whiteMode {
                whiteMode = true
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.locationLabel.alpha = 1.0
                })
            }
        } else {
            if whiteMode {
                whiteMode = false
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.locationLabel.alpha = 0.0
                })
            }
        }
    }
}
