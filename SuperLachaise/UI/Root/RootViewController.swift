//
//  RootViewController.swift
//  SuperLachaise
//
//  Created by Maxime Le Moine on 10/06/2017.
//
//

import UIKit

class RootViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [MapViewController()]
    }

}
