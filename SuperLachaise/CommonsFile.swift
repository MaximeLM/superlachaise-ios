//
//  CommonsFile.swift
//  SuperLachaiseRealmLoader
//
//  Created by Maxime Le Moine on 21/05/2017.
//
//

import Foundation
import RealmSwift

final class CommonsFile: Object {
    
    dynamic var id = ""
    
    dynamic var width = 0
    dynamic var height = 0
    
    dynamic var author: String?
    dynamic var license: String?
    
    dynamic var rawImageURL = ""
    dynamic var thumbnailURLTemplate = ""
    
    let commonsCategories = LinkingObjects(fromType: CommonsCategory.self, property: "commonsFiles")
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}
