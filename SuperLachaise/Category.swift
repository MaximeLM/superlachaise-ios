//
//  Category.swift
//  SuperLachaiseRealmLoader
//
//  Created by Maxime Le Moine on 21/05/2017.
//
//

import Foundation
import RealmSwift

final class Category: Object {
    
    dynamic var id = ""
    
    let localizations = LinkingObjects(fromType: LocalizedCategory.self, property: "category")
    
    let members = LinkingObjects(fromType: WikidataEntry.self, property: "categories")
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}
