//
//  StarsStore+MigrateFromV1.swift
//  SuperLachaise
//
//  Created by Maxime Le Moine on 03/06/2017.
//
//

import CoreData
import Foundation
import RealmSwift
import RxSwift

extension StarsStore {

    enum MigrateFromV1State: CustomStringConvertible {
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

        var description: String {
            switch self {
            case .notMigrated:
                return "notMigrated"
            case .migrating:
                return "migrating"
            case .migrated:
                return "migrated"
            case let .migrationFailed(error):
                return "migrationFailed(\(error))"
            }
        }
    }

    enum MigrateFromV1Action: CustomStringConvertible {
        case startedMigration
        case noMigrationNeeded
        case migrationSucceeded(ids: [String])
        case migrationFailed(error: Error)

        var description: String {
            switch self {
            case .startedMigration:
                return "startedMigration"
            case .noMigrationNeeded:
                return "noMigrationNeeded"
            case let .migrationSucceeded(ids):
                return "migrationSucceeded(\(ids))"
            case let .migrationFailed(error):
                return "migrationFailed(\(error))"
            }
        }
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

    func dispatchMigrateFromV1(action: MigrateFromV1Action) {
        dispatch(action: .migrateFromV1Action(action: action))
    }

    func migrateFromV1() {
        StarsStore.migrateFromV1IfNeeded()
            .observeOn(MainScheduler.asyncInstance)
            .debug()
            .do(onSubscribe: { [weak self] in
                self?.dispatchMigrateFromV1(action: .startedMigration)
            })
            .subscribe(onSuccess: { [weak self] ids in
                self?.dispatchMigrateFromV1(action: .migrationSucceeded(ids: ids))
            }, onError: { [weak self] error in
                self?.dispatchMigrateFromV1(action: .migrationFailed(error: error))
            }, onCompleted: { [weak self] in
                self?.dispatchMigrateFromV1(action: .noMigrationNeeded)
            })
            .disposed(by: disposeBag)
    }

}

fileprivate extension StarsStore {

    static func migrateFromV1IfNeeded() -> Maybe<[String]> {
        return Maybe.create { observer in
            let storeV1URL: URL
            do {
                storeV1URL = try StarsStore.storeV1URL()
            } catch {
                observer(.error(error))
                return Disposables.create()
            }
            if !FileManager.default.fileExists(atPath: storeV1URL.path) {
                observer(.completed)
                return Disposables.create()
            } else {
                return doMigrateFromV1(storeV1URL: storeV1URL)
                    .subscribeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "migrateFromV1"))
                    .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "migrateFromV1"))
                    .do(onCompleted: {
                        try deleteStoreV1(storeV1URL: storeV1URL)
                    })
                    .asObservable().asMaybe()
                    .subscribe(observer)
            }
        }
    }

    static func storeV1URL() throws -> URL {
        let documentDirectory = try FileManager.default.url(for: .documentDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil, create: false)
        return documentDirectory
            .appendingPathComponent("PLData.sqlite", isDirectory: false)
    }

    static func doMigrateFromV1(storeV1URL: URL) -> Single<[String]> {
        return Single.create { observer in
            let context: NSManagedObjectContext
            do {
                context = try loadContext(storeV1URL: storeV1URL)
            } catch {
                observer(.error(error))
                return Disposables.create()
            }

            context.perform {
                autoreleasepool {
                    do {
                        let realm = try Realm()
                        let starsIds = try fetchStarsIdsFromV1(context: context)
                            .flatMap { starIdFromV1 -> String? in
                                return starId(for: starIdFromV1, realm: realm)
                            }
                        observer(.success(starsIds))
                    } catch {
                        observer(.error(error))
                    }
                }
            }
            return Disposables.create()
        }

    }

    static func loadContext(storeV1URL: URL) throws -> NSManagedObjectContext {
        guard let modelURL = Bundle.main.url(forResource: "SuperLachaiseV1", withExtension: "momd") else {
            throw MigrateFromV1Error.managedObjectModelNotFound
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw MigrateFromV1Error.invalidManagedObjectModel
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                           configurationName: nil, at: storeV1URL, options: nil)
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }

    static func fetchStarsIdsFromV1(context: NSManagedObjectContext) throws -> [Int64] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PLNodeOSM")
        fetchRequest.predicate = NSPredicate(format: "monument.circuit == 1")
        return try context.fetch(fetchRequest)
            .map { nodeOSM -> Int64 in
                guard let id = nodeOSM.value(forKey: "id") as? NSNumber else {
                    throw MigrateFromV1Error.invalidManagedObject
                }
                return id.int64Value
            }
    }

    static func starId(for starIdFromV1: Int64, realm: Realm) -> String? {
        guard let mapping = realm.object(ofType: StoreV1NodeIdMapping.self, forPrimaryKey: starIdFromV1),
            let wikidataEntry = mapping.wikidataEntry else {
                print("Unknown star Id: \(starIdFromV1)")
                return nil
        }
        return wikidataEntry.id
    }

    static func deleteStoreV1(storeV1URL: URL) throws {
        if FileManager.default.fileExists(atPath: storeV1URL.path) {
            try FileManager.default.removeItem(at: storeV1URL)
        }
    }

    enum MigrateFromV1Error: Error {
        case invalidManagedObject
        case invalidManagedObjectModel
        case managedObjectModelNotFound
    }

}
