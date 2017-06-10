//
//  UIState.swift
//  SuperLachaise
//
//  Created by Maxime Le Moine on 10/06/2017.
//
//

import Foundation
import RealmSwift

struct UIState {
    var navigationState = NavigationState()
    var mapState = MapState()
    var detailState = DetailState()
    var searchState = SearchState()
    var galleryState = GalleryState()
}

enum UIAction {

}

class UIStore: Store<UIState, UIAction> {

    static let shared = StarsStore()

    init() {
        super.init(initialState: UIState(),
                   reducer: UIStore.reduce)
    }

    static func reduce(action: UIAction, state: UIState) -> UIState {
        return state
    }

}

// MARK: - Navigation

enum NavigationScreen {
    case map
    case detail
    case search
    case settings
    case fullScreenGallery
}

struct NavigationState {
    var screen: NavigationScreen = .map
}

// MARK: - Map

struct MapState {
    var selectedOpenStreetMapElementID: String?

    var selectedOpenStreetMapElement: OpenStreetMapElement? {
        get {
            do {
                return try Realm().object(ofType: OpenStreetMapElement.self,
                                          forPrimaryKey: selectedOpenStreetMapElementID)
            } catch {
                assertionFailure("\(error)")
                return nil
            }
        }
        set {
            selectedOpenStreetMapElementID = newValue?.id
        }
    }
}

// MARK: - Detail

struct DetailState {
    var wikidataEntryIds: [String] = [] // Stack

    var wikidataEntries: [WikidataEntry] {
        get {
            do {
                let predicate = NSPredicate(format: "id IN %@", wikidataEntryIds)
                return Array(try Realm().objects(WikidataEntry.self).filter(predicate))
            } catch {
                assertionFailure("\(error)")
                return []
            }
        }
        set {
            wikidataEntryIds = newValue.map { $0.id }
        }
    }
}

// MARK: - Search

struct SearchState {
    var searchText = ""
    var categoryID: String?

    var category: Category? {
        get {
            do {
                return try Realm().object(ofType: Category.self,
                                          forPrimaryKey: categoryID)
            } catch {
                assertionFailure("\(error)")
                return nil
            }
        }
        set {
            categoryID = newValue?.id
        }
    }
}

// MARK: - Gallery

struct GalleryState {
    var commonsCategoryId: String?
    var currentCommonsFileIndex: Int = 0

    var commonsCategory: CommonsCategory? {
        get {
            do {
                return try Realm().object(ofType: CommonsCategory.self,
                                          forPrimaryKey: commonsCategoryId)
            } catch {
                assertionFailure("\(error)")
                return nil
            }
        }
        set {
            commonsCategoryId = newValue?.id
            currentCommonsFileIndex = 0
        }
    }

    var currentCommonsFile: CommonsFile? {
        get {
            guard let commonsCategory = commonsCategory,
                currentCommonsFileIndex < commonsCategory.commonsFiles.count else {
                return nil
            }
            return commonsCategory.commonsFiles[currentCommonsFileIndex]
        }
        set {
            guard let newValue = newValue, let commonsCategory = commonsCategory else {
                return
            }
            currentCommonsFileIndex = commonsCategory.commonsFiles.index(of: newValue) ?? 0
        }
    }
}
