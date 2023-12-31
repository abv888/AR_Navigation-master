import MapKit
import CoreLocation

protocol NavigationManagerDelegate: AnyObject {
    func navigationManager(_ manager: NavigationManager, didUpdateLocations locations: [CLLocation])
    func navigationManager(_ manager: NavigationManager, didUpdateHeading newHeading: CLHeading)
    func navigationManager(_ manager: NavigationManager, didFailWithError error: Error)
    func navigationManager(_ manager: NavigationManager, didReceiveNoAuthorization state: CLAuthorizationStatus)
}

extension NavigationManagerDelegate {
    func navigationManager(_ manager: NavigationManager, didUpdateLocations locations: [CLLocation]) { }
    func navigationManager(_ manager: NavigationManager, didUpdateHeading newHeading: CLHeading) { }
    func navigationManager(_ manager: NavigationManager, didFailWithError error: Error) { }
    func navigationManager(_ manager: NavigationManager, didReceiveNoAuthorization state: CLAuthorizationStatus) { }
}

class NavigationManager: NSObject {
    lazy var locationManager = CLLocationManager()
    
    weak var delegate: NavigationManagerDelegate?
    fileprivate var currentSearch: MKLocalSearch?
    fileprivate var queue = DispatchQueue(label: "navigation-manager-queue", qos: .default, attributes: .concurrent)
    
    var coordinateRequestCache: [CLLocationCoordinate2D: CLPlacemark] = [:]
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func launchUpdating() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingHeading()
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            delegate?.navigationManager(self, didReceiveNoAuthorization: CLLocationManager.authorizationStatus())
        }
    }
}

extension NavigationManager {
    func requestDirections(from source: CLLocationCoordinate2D,
                           to destination: CLLocationCoordinate2D,
                           type: MKDirectionsTransportType,
                           completion: @escaping (_ route: MKRoute?, _ error: Error?) -> Void) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: source.placemark)
        request.destination = MKMapItem(placemark: destination.placemark)
        request.transportType = type
        
        let directions = MKDirections(request: request)
        queue.async {
            directions.calculate { (response, error) in
                completion(response?.routes.first, error)
            }
        }
    }
    
    func requestPlaces(for coordinates: CLLocationCoordinate2D, callback: @escaping (_ mark: CLPlacemark?, _ error: Error?) -> Void) {
        if let cachedValue = coordinateRequestCache[coordinates] {
            callback(cachedValue, nil); return
        }
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        queue.async {
            geocoder.reverseGeocodeLocation(location) { (placeMarks, error) in
                if let placemark = placeMarks?.first {
                    self.coordinateRequestCache[coordinates] = placemark
                }
                
                callback(placeMarks?.first, error)
            }
        }
    }
    
    func requestPlaces(for text: String, from location: CLLocation?, callback: @escaping (_ region: MKCoordinateRegion, _ items: [MKMapItem]) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        
        if let location = location {
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            request.region = MKCoordinateRegion(center: location.coordinate, span: span)
        }
        
        currentSearch?.cancel()
        let search = MKLocalSearch(request: request)
        currentSearch = search
        
        queue.async { [weak self] in
            guard let wSelf = self else { return }
            search.start { (response, error) in
                guard let response = response else {
                    debugPrint(error?.localizedDescription ?? "")
                    return
                }
                
                callback(response.boundingRegion, response.mapItems)
                wSelf.currentSearch = nil
            }
        }
    }
}

extension NavigationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.navigationManager(self, didUpdateLocations: locations)
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        
        delegate?.navigationManager(self, didUpdateHeading: newHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingHeading()
            locationManager.startUpdatingLocation()
        default:
            locationManager.stopUpdatingHeading()
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.navigationManager(self, didFailWithError: error)
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        guard let error = error else { return }
        delegate?.navigationManager(self, didFailWithError: error)
    }
}

