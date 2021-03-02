import ApplozicCore
import Foundation

class ALKLinkPreviewBaseCell: ALKMessageCell {
    var url: String?
    let linkView = ALKLinkView()

    override func update(
        viewModel: ALKMessageViewModel,
        messageStyle: Style,
        mentionStyle: Style
    ) {
        super.update(viewModel: viewModel, messageStyle: messageStyle, mentionStyle: mentionStyle)
        linkView.setLocalizedStringFileName(localizedStringFileName)
        url = ALKLinkPreviewManager.extractURLAndAddInCache(from: viewModel.message, identifier: viewModel.identifier)?.absoluteString
    }

    override func setupViews() {
        super.setupViews()
        contentView.addViewsForAutolayout(views:
            [linkView])
        contentView.bringSubviewToFront(linkView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openUrl))
        linkView.frontView.addGestureRecognizer(tapGesture)
    }

    override func setupStyle() {
        super.setupStyle()
    }

    override class func messageHeight(viewModel: ALKMessageViewModel,
                                      width: CGFloat, font: UIFont, mentionStyle: Style,
                                      displayNames: ((Set<String>) -> ([String: String]?))?) -> CGFloat
    {
        return super.messageHeight(viewModel: viewModel, width: width, font: font, mentionStyle: mentionStyle, displayNames: displayNames)
    }

    @objc private func openUrl() {
        guard let stringURL = url, let openURL = URL(string: stringURL) else { return }
        UIApplication.shared.open(openURL)
    }

    func isCellVisible(_ closure: @escaping ((_ identifier: String) -> Bool)) {
        linkView.isViewCellVisible = closure
    }
}
