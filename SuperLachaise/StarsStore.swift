//
//  StarsStore.swift
//  SuperLachaise
//
//  Created by Maxime Le Moine on 03/06/2017.
//
//

import Foundation

struct StarsStoreState {
    // Wikidata IDs for primary wikidata entries (more stable than OpenStreetMap IDs)
    var starsIDs: Set<String>
    var migrateFromV1State: StarsStore.MigrateFromV1State
}

enum StarsStoreAction {
    case addStar(id: String)
    case removeStar(id: String)
    case migrateFromV1Action(action: StarsStore.MigrateFromV1Action)
}

class StarsStore: Store<StarsStoreState, StarsStoreAction> {

    static let shared = StarsStore()

    init() {
        let migrateFromV1State = MigrateFromV1State(didMigrate: StarsStore.didMigrateFromV1)
        let initialState = StarsStoreState(starsIDs: Set(StarsStore.starsIDs),
                                           migrateFromV1State: migrateFromV1State)
        super.init(initialState: initialState,
                   reducer: StarsStore.reduce)

    #if DEBUG
        state.asObservable()
            .debug("StarsStore.state")
            .subscribe()
            .disposed(by: disposeBag)
        actions
            .debug("StarsStore.actions")
            .subscribe()
            .disposed(by: disposeBag)
    #endif

        // Save state to user defaults
        state.asObservable()
            .subscribe(onNext: { state in
                StarsStore.didMigrateFromV1 = state.migrateFromV1State.didMigrate
                StarsStore.starsIDs = Array(state.starsIDs)
            })
            .disposed(by: disposeBag)

        // Migrate from V1 if needed
        if !migrateFromV1State.didMigrate {
            migrateFromV1()
        }
    }

}

// MARK: Reducer

fileprivate extension StarsStore {

    static func reduce(action: StarsStoreAction, state: StarsStoreState) -> StarsStoreState {
        var state = state
        switch action {
        case let .addStar(id):
            state.starsIDs.insert(id)
        case let .removeStar(id):
            state.starsIDs.remove(id)
        case let .migrateFromV1Action(action):
            switch action {
            case let .migrationSucceeded(ids):
                state.starsIDs.formUnion(ids)
            default:
                break
            }
            state.migrateFromV1State = reduceMigrateFromV1(action: action, state: state.migrateFromV1State)
        }
        return state
    }

}

// MARK: User defaults

fileprivate extension StarsStore {

    private static let didMigrateFromV1Key = "superlachaise.starsStore.didMigrateFromV1"
    static var didMigrateFromV1: Bool {
        get {
            return UserDefaults.standard.bool(forKey: didMigrateFromV1Key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: didMigrateFromV1Key)
        #if DEBUG
            UserDefaults.standard.synchronize()
        #endif
        }
    }

    private static let starsIDsKey = "superlachaise.starsStore.starsIDs"
    static var starsIDs: [String] {
        get {
            if let starsIDs = UserDefaults.standard.array(forKey: starsIDsKey) as? [String] {
                return starsIDs
            }
            return []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: starsIDsKey)
        #if DEBUG
            UserDefaults.standard.synchronize()
        #endif
        }
    }

}
