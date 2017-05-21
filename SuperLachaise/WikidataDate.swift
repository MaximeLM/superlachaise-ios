//
//  WikidataDate.swift
//  SuperLachaiseRealmLoader
//
//  Created by Maxime Le Moine on 21/05/2017.
//
//

import Foundation
import RealmSwift

final class WikidataDate: Object {
    
    dynamic var id = ""
    
    dynamic var rawPrecision = ""
    let year = RealmOptional<Int>()
    let month = RealmOptional<Int>()
    let day = RealmOptional<Int>()
    
    let birthOf = LinkingObjects(fromType: WikidataEntry.self, property: "dateOfBirth")
    let deathOf = LinkingObjects(fromType: WikidataEntry.self, property: "dateOfDeath")
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}

extension WikidataDate {
    
    enum Precision: String {
        case day
        case month
        case year
    }
    
    var precision: Precision? {
        get {
            return Precision(rawValue: rawPrecision)
        }
    }
    
}
