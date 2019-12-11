//
//  Coordinator.swift
//  CoordinatorSample
//
//  Created by Dario on 7/9/19.
//  Copyright © 2019 Dario Gasquez. All rights reserved.
//

import UIKit

protocol Coordinator {
    var children: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }

    func start()
}
