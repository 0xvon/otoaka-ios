import UIKit

public final class FollowersSummaryView: UIStackView {
    let followersLabel: UILabel = {
        let label = UILabel()
        label.text = "フォロワー"
        label.font = Brand.font(for: .medium)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    let followersNumberLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = Brand.font(for: .small)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()

    public init() {
        super.init(frame: .zero)
        setup()
    }
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        axis = .vertical
        alignment = .center
        addArrangedSubview(followersLabel)
        addArrangedSubview(followersNumberLabel)
        followersLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    public func updateNumber(_ number: Int) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        followersNumberLabel.text = formatter.string(from: NSNumber(value: number))
    }
}


#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct FollowersSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper(view: FollowersSummaryView())
                .previewLayout(.fixed(width: 100, height: 48))
            ViewWrapper(view: {
                let label = FollowersSummaryView()
                label.updateNumber(10000)
                return label
            }())
                .previewLayout(.fixed(width: 100, height: 48))
            
        }
        .background(Color.black)
    }
}
#endif
