import UIKit
import MapKit
import CoreLocation

protocol MapViewViewInput: PopoverDisplayer {
    var mapView: MKMapView! { get }
    
    func endEditing()
    func type(for searchBar: UISearchBar) -> SearchBarType
    
    func addOrUpdateAnnotation(for container: Container<CLLocationCoordinate2D>, decoratorBlock: @escaping (_ annotation: MapAnnotation) -> Void)
    func removeAnnotation(for container: Container<CLLocationCoordinate2D>)
    func clearAllPins()
    
    func updateViews(for state: MapAction, animated: Bool)
    func updateActions(with items: [MapActionDisplayable])
    func updateUserHeading(_ heading: CLHeading)
    
    func showAllAnnotations()
    
    func showActivityIndicator()
    func hideActivityIndicator()
}

protocol MapViewViewOutput: AnyObject, UISearchBarDelegate {
    func viewDidLoad()
    
    func handleGoAction()
    func handleLocationAction()
    func handleActionSelection(at index: Int)
    
    func handleDragAction(for container: Container<CLLocationCoordinate2D>)
    func handleLongPressAction(for location: CLLocationCoordinate2D)
    
    func handleAnnotationTap(for container: Container<CLLocationCoordinate2D>, isSelected: Bool)
    
    func color(for overlay: MKOverlay) -> UIColor
}

class MapViewController: UIViewController, View {
    typealias Presenter = MapViewViewOutput
    
    static var storyboardName: String { return "MapView" }
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var visualEffectTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var visualEffectViewContainer: UIVisualEffectView!
    @IBOutlet weak var stackViewContainer: UIStackView!
    
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    @IBOutlet weak var firstContainerView: UIView!
    @IBOutlet weak var firstSearchBar: UISearchBar!
    
    @IBOutlet weak var secondContainerView: UIView!
    @IBOutlet weak var secondSearchBar: UISearchBar!
    
    @IBOutlet weak var actionsCollectionView: UICollectionView!
    
    weak var headingImageView: UIImageView!
    
    var actions: [MapActionDisplayable] = []
    
    weak var output: MapViewViewOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViews()
        output.viewDidLoad()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(press:)))
        mapView.addGestureRecognizer(longPress)
        (mapView.gestureRecognizers ?? []).forEach { (gesture) in
            gesture.require(toFail: longPress)
        }
    }
    
    func configureViews() {
        configureTextFields()
        configureCollectionView()
        configureMapView()
    }
    
    func configureTextFields() {
        firstSearchBar.delegate = output
        secondSearchBar.delegate = output
    }
    
    func configureCollectionView() {
        actionsCollectionView.backgroundColor = .clear
        actionsCollectionView.register(MapActionCollectionViewCell.self)
    }
    
    func configureMapView() {
        mapView.delegate = self
        
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsUserLocation = true
        mapView.showsPointsOfInterest = true
        mapView.userTrackingMode = .follow
    }
    
    @objc func handleLongPress(press: UILongPressGestureRecognizer) {
        switch press.state {
        case .ended:
            let endLocation = press.location(in: mapView)
            let coordinate = mapView.convert(endLocation, toCoordinateFrom: view)
            output.handleLongPressAction(for: coordinate)
        default: break
        }
    }
    
    @IBAction func goButtonTouched(_ sender: UIButton) {
        output.handleGoAction()
    }
    
    @IBAction func locationButtonTouched(_ sender: UIButton) {
        output.handleLocationAction()
    }
    
    func addHeadingArrow(to view: MKAnnotationView) {
        guard headingImageView == nil else { return }
        let bounds = view.bounds
        
        let arrow = #imageLiteral(resourceName: "icon_heading_arrow").withRenderingMode(.alwaysTemplate)
        let arrowSize: CGFloat = 15
        
        let imageView = UIImageView()
        imageView.tintColor = .darkGray
        imageView.contentMode = .scaleAspectFit
        imageView.image = arrow
        
        imageView.frame = CGRect(x: (bounds.size.width - arrowSize) / 2,
                                 y: (bounds.size.height - arrowSize) / 2,
                                 width: arrowSize,
                                 height: arrowSize)
        
        view.addSubview(imageView)
        headingImageView = imageView
    }
}

enum SearchBarType {
    case source
    case destination
    case unknown
}

extension MapViewController: MapViewViewInput {
    
    func endEditing() {
        view.endEditing(true)
    }
    
    func type(for searchBar: UISearchBar) -> SearchBarType {
        if searchBar == firstSearchBar {
            return .source
        }
        
        if searchBar == secondSearchBar {
            return .destination
        }
        
        return .unknown
    }
    
    func clearAllPins() {
        mapView.removeAnnotations(mapView.annotations)
    }
    
    func updateViews(for state: MapAction, animated: Bool) {
        visualEffectTopConstraint.constant = state.shouldDisplaySearchPanel
            ? 0
            : -BottomSlideContainer.topViewHeight
        
        secondContainerView.isHidden = !state.bothTextFieldsAreDisplayed
        
        firstSearchBar.text = ""
        firstSearchBar.placeholder = state.firstPlaceholder
        
        secondSearchBar.text = ""
        secondSearchBar.placeholder = state.secondPlaceholder
        
        if animated {
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options:[.curveEaseInOut, .beginFromCurrentState],
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    func addOrUpdateAnnotation(for container: Container<CLLocationCoordinate2D>, decoratorBlock: @escaping (_ annotation: MapAnnotation) -> Void) {
        removeAnnotation(for: container)
        let newAnnotation = MapAnnotation(container: container)
        decoratorBlock(newAnnotation)
        mapView.addAnnotation(newAnnotation)
    }
    
    func removeAnnotation(for container: Container<CLLocationCoordinate2D>) {
        guard let removing = mapView.annotations.first(where: { (annotation) -> Bool in
            guard let mapAnnotation = annotation as? MapAnnotation else { return false }
            return mapAnnotation.locationContainer.id == container.id
        }) else { return }
        
        mapView.removeAnnotation(removing)
    }
    
    func updateActions(with items: [MapActionDisplayable]) {
        actions = items
        actionsCollectionView.reloadData()
    }
    
    
    func updateUserHeading(_ heading: CLHeading) {
        guard let headingImageView = headingImageView else { return }
        guard heading.headingAccuracy >= 0 else { return }
        
        let degreesAngle = heading.trueHeading > 0 ? heading.trueHeading : heading.magneticHeading
        let radAngle = CGFloat(degreesAngle / 180 * .pi)
        
        let rotation = CGAffineTransform(rotationAngle: radAngle)
        
        let x: CGFloat = 0
        let y: CGFloat = -11
        
        let tX = x * cos(radAngle) - y * sin(radAngle)
        let tY = x * sin(radAngle) + y * cos(radAngle)
        
        let translation = CGAffineTransform(translationX: tX, y: tY)
        
        let transform = rotation.concatenating(translation)
        
        headingImageView.transform = transform
    }
    
    func showAllAnnotations() {
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func showActivityIndicator() {
        DispatchQueue.main.async {
            self.activityView.startAnimating()
        }
    }
    
    func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.activityView.stopAnimating()
        }
    }
}

extension MapViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        output.handleActionSelection(at: indexPath.item)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = actions[indexPath.item]
        let width = MapActionCollectionViewCell.estimatedWidth(for: item.stringValue, height: collectionView.bounds.height)
        
        return CGSize(width: width, height: collectionView.bounds.height)
    }
}

extension MapViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: MapActionCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        
        cell.configure(with: actions[indexPath.item])
        
        return cell
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        
    }
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let mapAnnotation = annotation as? MapAnnotation else { return nil }
        
        let annotationView: MKMarkerAnnotationView = mapView.dequeueReusableAnnotationView() ?? MKMarkerAnnotationView(annotation: mapAnnotation)
        
        annotationView.animatesWhenAdded = true
        annotationView.markerTintColor = MKPinAnnotationView.purplePinColor()
        annotationView.isDraggable = true
        
        return annotationView
    }
    
    public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        guard let userLocationAnnotation = views.first(where: { $0.annotation is MKUserLocation }) else { return }
        addHeadingArrow(to: userLocationAnnotation)
    }
    
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? MapAnnotation else { return }
        output?.handleAnnotationTap(for: annotation.locationContainer, isSelected: true)
    }
    
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
    
    public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let annotation = view.annotation as? MapAnnotation else { return }
        output?.handleAnnotationTap(for: annotation.locationContainer, isSelected: false)
    }
    
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        guard let annotation = view.annotation as? MapAnnotation else { return }
        switch newState {
        case .ending, .canceling:
            annotation.locationContainer.element = annotation.coordinate
            output?.handleDragAction(for: annotation.locationContainer)
        default: break
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = output?.color(for: overlay) ?? .randomPrettyColor
        renderer.lineWidth = 4.0
        renderer.lineDashPattern = [1, 10]
        
        return renderer
    }
}

