//
//  CommonsCategory.swift
//  SuperLachaiseRealmLoader
//
//  Created by Maxime Le Moine on 21/05/2017.
//
//

import Foundation
import RealmSwift

final class CommonsCategory: Object {
    
    dynamic var id = ""
    
    let commonsFiles = List<CommonsFile>()
    let wikidataEntries = LinkingObjects(fromType: WikidataEntry.self, property: "commonsCategory")
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}
