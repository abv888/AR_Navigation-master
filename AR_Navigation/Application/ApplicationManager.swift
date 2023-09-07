import Foundation
import UIKit

@UIApplicationMain
class ApplicationManager: NSObject {
    static var shared = ApplicationManager()
    
    var window: UIWindow?
    
    @IBOutlet weak var initialViewController: UIViewController! {
        didSet { configure() }
    }
    
    var initialModule: ModuleInput!
    
    func configure() {
        do {
            initialModule = try ARViewRouter.moduleInput(with: initialViewController)
        } catch {
            debugPrint(error)
        }
    }
    
    override public func awakeAfter(using aDecoder: NSCoder) -> Any? {
        return ApplicationManager.shared
    }
}

extension ApplicationManager: UIApplicationDelegate {
    
}

