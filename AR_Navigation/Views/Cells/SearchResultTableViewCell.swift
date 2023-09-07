import UIKit

protocol SearchResultDisplayable {
    var mainInfo: String { get }
    var subInfo: String { get }
}

class SearchResultTableViewCell: UITableViewCell, Reusable {

    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var subLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
    }
    
    func configure(with item: SearchResultDisplayable) {
        mainLabel.text = item.mainInfo
        subLabel.text = item.subInfo
    }
}
