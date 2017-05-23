//
//  StarsController+MigrateFromV1.swift
//  SuperLachaise
//
//  Created by Maxime Le Moine on 21/05/2017.
//
//

import Foundation
import CoreData
import RealmSwift
import RxSwift

extension StarsController {

    func migrateFromStoreV1IfNeeded() {
        StarsController.starredIDsFromV1()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { starredIDs in
                self.starredIDs.value.formUnion(starredIDs)
                print("Migrated \(starredIDs.count) stars from store V1")
            }, onError: { error in
                print("Error when migrating stars from store V1: \(error)")
            }, onCompleted: {
                print("No store V1 to migrate")
            })
            .disposed(by: disposeBag)
    }

}

fileprivate extension StarsController {

    static func starredIDsFromV1() -> Maybe<[String]> {
        return existingStoreV1URL()
            .map(loadContext)
            .flatMap(fetchStarredV1IDs)
            .flatMap(fetchStarredV2IDs)
            .do(onNext: { _ in
                try deleteStoreV1()
            })
    }

    static func storeV1URL() throws -> URL {
        let documentsDir = try FileManager.default.url(for: .documentDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: nil, create: false)
        return documentsDir.appendingPathComponent("PLData.sqlite")
    }

    static func existingStoreV1URL() -> Maybe<URL> {
        return Maybe<URL>
            .create { observer in
                do {
                    let storeURL = try self.storeV1URL()
                    if FileManager.default.fileExists(atPath: storeURL.path) {
                        observer(.success(storeURL))
                    } else {
                        observer(.completed)
                    }
                } catch {
                    observer(.error(error))
                }
                return Disposables.create()
            }
    }

    static func loadContext(storeURL: URL) throws -> NSManagedObjectContext {
        guard let modelURL = Bundle.main.url(forResource: "SuperLachaiseV1", withExtension: "momd") else {
            throw MigrateStarsFromV1Error.managedObjectModelNotFound
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw MigrateStarsFromV1Error.invalidManagedObjectModel
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                           configurationName: nil, at: storeURL, options: nil)
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }

    static func fetchStarredV1IDs(context: NSManagedObjectContext) -> Maybe<[NSNumber]> {
        return Maybe.create { observer in
            context.perform {
                do {
                    let starredV1IDs = try self.starredV1IDs(context: context)
                    observer(.success(starredV1IDs))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    static func starredV1IDs(context: NSManagedObjectContext) throws -> [NSNumber] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PLNodeOSM")
        fetchRequest.predicate = NSPredicate(format: "monument.circuit == 1")

        return try context.fetch(fetchRequest)
            .map { nodeOSM in
                guard let id = nodeOSM.value(forKey: "id") as? NSNumber else {
                    throw MigrateStarsFromV1Error.invalidManagedObject
                }
                return id
            }
    }

    static func fetchStarredV2IDs(starredV1IDs: [NSNumber]) -> Maybe<[String]> {
        return Maybe.create { observer in
            autoreleasepool {
                do {
                    let realm = try Realm()
                    let stars = starredV1IDs
                        .flatMap { starredV1ID -> String? in
                            do {
                                return try starredV2IDs(starredV1ID: starredV1ID, realm: realm)
                            } catch {
                                print(error)
                                return nil
                            }
                        }
                    observer(.success(stars))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    static func starredV2IDs(starredV1ID: NSNumber, realm: Realm) throws -> String {
        guard let mapping = realm.object(ofType: StoreV1NodeIdMapping.self, forPrimaryKey: starredV1ID.int64Value),
            let wikidataEntry = mapping.wikidataEntry else {
            throw MigrateStarsFromV1Error.unknownStarredV1ID(starredV1ID: starredV1ID)
        }
        return wikidataEntry.id
    }

    static func deleteStoreV1() throws {
        let storeURL = try self.storeV1URL()
        if FileManager.default.fileExists(atPath: storeURL.path) {
            try FileManager.default.removeItem(at: storeURL)
        }
    }

}

fileprivate enum MigrateStarsFromV1Error: Error, CustomStringConvertible {
    case managedObjectModelNotFound
    case invalidManagedObjectModel
    case invalidManagedObject
    case unknownStarredV1ID(starredV1ID: NSNumber)

    var description: String {
        switch self {
        case .managedObjectModelNotFound:
            return "managed object model not found"
        case .invalidManagedObjectModel:
            return "invalid managed object model"
        case .invalidManagedObject:
            return "invalid managed object"
        case let .unknownStarredV1ID(starredV1ID):
            return "unknown starred V1 ID \(starredV1ID)"
        }
    }
}
