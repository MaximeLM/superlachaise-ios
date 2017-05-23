//
//  StarsController.swift
//  SuperLachaise
//
//  Created by Maxime Le Moine on 21/05/2017.
//
//

import Foundation
import RxSwift

class StarsController {

    // Wikidata IDs for primary wikidata entries (more stable than OpenStreetMap IDs)
    let starredIDs: Variable<Set<String>>

    let disposeBag = DisposeBag()

    init() {
        // Load from user defaults

        starredIDs = Variable([])

        migrateFromStoreV1IfNeeded()
    }

}
