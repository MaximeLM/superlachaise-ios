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
                print("Could not migrate stars from store V1: \(error)")
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
    }
    
    static func existingStoreV1URL() -> Maybe<URL> {
        return Maybe<URL>
            .create { observer in
                do {
                    let fm = FileManager.default
                    let documentsDir = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let storeURL = documentsDir.appendingPathComponent("PLData.sqlite")
                    if fm.fileExists(atPath: storeURL.path) {
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
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }
    
    static func fetchStarredV1IDs(context: NSManagedObjectContext) -> Maybe<[Int64]> {
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
    
    static func starredV1IDs(context: NSManagedObjectContext) throws -> [Int64] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PLNodeOSM")
        fetchRequest.predicate = NSPredicate(format: "monument.circuit == 1")
        
        return try context.fetch(fetchRequest)
            .map { nodeOSM in
                guard let id = nodeOSM.value(forKey: "id") as? NSNumber else {
                    throw MigrateStarsFromV1Error.invalidManagedObject
                }
                return id.int64Value
            }
    }
    
    static func fetchStarredV2IDs(starredV1IDs: [Int64]) -> Maybe<[String]> {
        return Maybe.create { observer in
            autoreleasepool {
                do {
                    let realm = try Realm()
                    let stars = try starredV1IDs
                        .flatMap { starredV1ID in
                            return try starredV2IDs(starredV1ID: starredV1ID, realm: realm)
                    }
                    observer(.success(stars))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }
    
    static func starredV2IDs(starredV1ID: Int64, realm: Realm) throws -> String? {
        let predicate = NSPredicate(format: "numericID == %@", starredV1ID)
        let openStreetMapElement = realm.objects(OpenStreetMapElement.self).filter(predicate).first
        return openStreetMapElement?.wikidataEntry?.id
    }
    
}

fileprivate enum MigrateStarsFromV1Error: Error {
    case managedObjectModelNotFound
    case invalidManagedObjectModel
    case invalidManagedObject
}
