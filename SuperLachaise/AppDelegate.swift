//
//  AppDelegate.swift
//  SuperLachaise
//
//  Created by Maxime Le Moine on 21/05/2017.
//
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Realm
        if let realmFileURL = Bundle.main.url(forResource: "SuperLachaise", withExtension: "realm") {
            Realm.Configuration.defaultConfiguration = Realm.Configuration(fileURL: realmFileURL, readOnly: true)
            do {
                _ = try Realm()
            } catch {
                assertionFailure("\(error)")
            }
        } else {
            assertionFailure()
        }

        return true
    }

}
