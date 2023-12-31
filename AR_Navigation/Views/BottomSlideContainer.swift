import UIKit
class BottomSlideContainer: UIView {
    static var topViewHeight: CGFloat = 40
    
    var topViewHeight: CGFloat
    
    weak var containerView: UIView!
    weak var topView: UIView!
    weak var embededViewController: UIViewController?

    init(topViewHeight: CGFloat) {
        self.topViewHeight = topViewHeight
        super.init(frame: .zero)
        backgroundColor = .clear
        initialLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        topViewHeight = BottomSlideContainer.topViewHeight
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        initialLayout()
    }
    
    func embed(viewController: UIViewController, caller: UIViewController?) {
        embededViewController?.willMove(toParent: nil)
        embededViewController?.view.removeFromSuperview()
        embededViewController?.removeFromParent()
        
        guard let embedingView = viewController.view else { return }
        
        caller?.addChild(viewController)
        containerView.embed(other: embedingView)
        containerView.layoutIfNeeded()
        viewController.didMove(toParent: caller)
    }
}

extension BottomSlideContainer {
    fileprivate func initialLayout() {
        let topView = UIView()
        topView.backgroundColor = .clear
        topView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topView)
        self.topView = topView
        
        [topView.leadingAnchor.constraint(equalTo: leadingAnchor),
         topView.trailingAnchor.constraint(equalTo: trailingAnchor),
         topView.topAnchor.constraint(equalTo: topAnchor),
         topView.heightAnchor.constraint(equalToConstant: topViewHeight)].forEach { $0.isActive = true }
        
        let accessoryView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        accessoryView.layer.cornerRadius = 3
        accessoryView.clipsToBounds = true
        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(accessoryView)
        
        [accessoryView.centerXAnchor.constraint(equalTo: topView.centerXAnchor),
         accessoryView.centerYAnchor.constraint(equalTo: topView.centerYAnchor),
         accessoryView.heightAnchor.constraint(equalToConstant: 6),
         accessoryView.widthAnchor.constraint(equalToConstant: BottomSlideContainer.topViewHeight)].forEach { $0.isActive = true }
        
        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        container.clipsToBounds = true
        addSubview(container)
        
        [container.leadingAnchor.constraint(equalTo: leadingAnchor),
         container.trailingAnchor.constraint(equalTo: trailingAnchor),
         container.topAnchor.constraint(equalTo: topView.bottomAnchor),
         container.bottomAnchor.constraint(equalTo: bottomAnchor)].forEach { $0.isActive = true }
        
        containerView = container
    }
}

