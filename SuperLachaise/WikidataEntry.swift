//
//  WikidataEntry.swift
//  SuperLachaiseRealmLoader
//
//  Created by Maxime Le Moine on 21/05/2017.
//
//

import Foundation
import RealmSwift

final class WikidataEntry: Object {
    
    dynamic var id = ""
    
    dynamic var rawKind = ""
    dynamic var burialPlotReference = ""
    
    dynamic var dateOfBirth: WikidataDate?
    dynamic var dateOfDeath: WikidataDate?
    
    let openStreetMapElements = LinkingObjects(fromType: OpenStreetMapElement.self, property: "wikidataEntry")
    
    let localizations = LinkingObjects(fromType: LocalizedWikidataEntry.self, property: "wikidataEntry")
    
    let categories = List<Category>()
    
    dynamic var commonsCategory: CommonsCategory?
    
    let graveOf = List<WikidataEntry>()
    let grave = LinkingObjects(fromType: WikidataEntry.self, property: "graveOf")
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}

extension WikidataEntry {
    
    enum Kind: String {
        case graveOf
        case grave
        case monument
    }
    
    var kind: Kind? {
        get {
            return Kind(rawValue: rawKind)
        }
    }
    
}
