//
//  StarsStore+MigrateFromV1.swift
//  SuperLachaise
//
//  Created by Maxime Le Moine on 03/06/2017.
//
//

import Foundation
import RxSwift

extension StarsStore {

    enum MigrateFromV1State {
        case notMigrated
        case migrating
        case migrated
        case migrationFailed(error: Error)

        init(didMigrate: Bool) {
            self = didMigrate ? .migrated : .notMigrated
        }

        var didMigrate: Bool {
            switch self {
            case .migrated:
                return true
            default:
                return false
            }
        }
    }

    enum MigrateFromV1Action {
        case startedMigration
        case noMigrationNeeded
        case migrationSucceeded(ids: [String])
        case migrationFailed(error: Error)
    }

    static func reduceMigrateFromV1(action: MigrateFromV1Action, state: MigrateFromV1State) -> MigrateFromV1State {
        switch action {
        case .startedMigration:
            return .migrating
        case .noMigrationNeeded, .migrationSucceeded:
            return .migrated
        case let .migrationFailed(error):
            return .migrationFailed(error: error)
        }
    }

}
