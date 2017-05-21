//
//  StoreV1NodeIdMapping.swift
//  SuperLachaiseRealmLoader
//
//  Created by Maxime Le Moine on 22/05/2017.
//
//

import Foundation
import RealmSwift

final class StoreV1NodeIdMapping: Object {
    
    dynamic var id: Int64 = 0
    dynamic var wikidataEntry: WikidataEntry?
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}
