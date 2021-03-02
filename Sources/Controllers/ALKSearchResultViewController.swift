//
//  SearchResultViewController.swift
//  Kommunicate Chat
//
//  Created by Shivam Pokhriyal on 17/06/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import ApplozicCore
import UIKit

public class ALKSearchResultViewController: ALKBaseViewController {
    fileprivate let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)

    let viewModel = SearchResultViewModel()
    lazy var viewController = ALKConversationListTableViewController(
        viewModel: self.viewModel,
        dbService: ALMessageDBService(),
        configuration: self.configuration,
        showSearch: false
    )

    var conversationViewController: ALKConversationViewController?

    public required init(configuration: ALKConfiguration) {
        super.init(configuration: configuration)
        viewController.delegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    public func search(key: String) {
        activityIndicator.startAnimating()
        clear()
        viewController.replaceViewModel(viewModel)
        viewModel.searchMessage(with: key) { result in
            self.activityIndicator.stopAnimating()
            if result {
                self.viewController.replaceViewModel(self.viewModel)
            }
        }
    }

    public func clear() {
        viewModel.clear()
    }

    public func clearAndReload() {
        clear()
        viewController.tableView.reloadData()
    }

    public func setUpSearchViewController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: self)
        searchController.searchBar.autocapitalizationType = .none
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.alpha = 0
        searchController.searchBar.showsCancelButton = true
        if #available(iOS 13.0, *) {
            searchController.automaticallyShowsCancelButton = true
        } else {
            searchController.searchBar.showsCancelButton = true
        }
        return searchController
    }

    private func setupView() {
        // Add TableViewController
        add(viewController)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.view.translatesAutoresizingMaskIntoConstraints = true

        // Add Activity Indicator
        activityIndicator.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
        activityIndicator.color = UIColor.gray
        view.addSubview(activityIndicator)
        view.bringSubviewToFront(activityIndicator)
    }
}

extension ALKSearchResultViewController: ALKConversationListTableViewDelegate {
    public func muteNotification(conversation _: ALMessage, isMuted _: Bool) {}

    public func userBlockNotification(userId _: String, isBlocked _: Bool) {}

    public func tapped(_ chat: ALKChatViewModelProtocol, at _: Int) {
        let convViewModel = viewModel.conversationViewModelFrom(
            contactId: chat.contactId,
            channelId: chat.channelKey,
            conversationId: chat.conversationId,
            localizationFileName: configuration.localizedStringFileName
        )
        convViewModel.isSearch = true

        let viewController = conversationViewController ?? ALKConversationViewController(configuration: configuration, individualLaunch: false)
        viewController.viewModel = convViewModel
        viewController.individualLaunch = false
        conversationViewController = viewController
        presentingViewController?.navigationController?.pushViewController(viewController, animated: true)
    }

    public func emptyChatCellTapped() {}

    public func scrolledToBottom() {}
}
