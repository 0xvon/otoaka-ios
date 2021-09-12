import UIKit

public final class CountSummaryView: UIStackView {
    public typealias Input = (
        title: String,
        count: Int
    )
    let followersLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = Brand.font(for: .xsmall)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    let followersNumberLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = Brand.font(for: .smallStrong)
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

    public func update(input: Input) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        followersLabel.text = input.title
        followersNumberLabel.text = formatter.string(from: NSNumber(value: input.count))
    }
}


#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct FollowersSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreviewWrapper(view: CountSummaryView())
                .previewLayout(.fixed(width: 100, height: 48))
            PreviewWrapper(view: {
                let label = CountSummaryView()
                label.update(input: (title: "フォロワー", count: 100))
                return label
            }())
                .previewLayout(.fixed(width: 100, height: 48))
            
        }
        .background(Color.black)
    }
}
#endif
