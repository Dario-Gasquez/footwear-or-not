//
//  MainCoordinator.swift
//  CoordinatorSample
//
//  Created by Dario on 7/9/19.
//  Copyright © 2019 Dario Gasquez. All rights reserved.
//

import UIKit

final class MainCoordinator: Coordinator {
    var children = [Coordinator]()
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }


    func start() {
        let viewController = ViewController.instantiate()
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: true)
    }
}
