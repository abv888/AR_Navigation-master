import UIKit

extension UITableView {
    func register(_ cellType: Reusable.Type) {
        let nib = UINib.nib(for: cellType)
        register(nib, forCellReuseIdentifier: cellType.reuseIdentifier)
    }
    
    func registerHeaderFooter(_ viewType: Reusable.Type, suplementaryViewOfKind: String) {
        let nib = UINib.nib(for: viewType)
        register(nib, forHeaderFooterViewReuseIdentifier: viewType.reuseIdentifier)
    }
    
    func registerCellClass(_ cellType: Reusable.Type) {
        register(cellType, forCellReuseIdentifier: cellType.reuseIdentifier)
    }
    
    func dequeueReusableCell(forCell type: Reusable.Type, indexPath: IndexPath) -> Reusable {
        return dequeueReusableCell(withIdentifier: type.reuseIdentifier, for: indexPath) as! Reusable
    }
    
    func dequeueReusableCell<T: Reusable>(for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
}
