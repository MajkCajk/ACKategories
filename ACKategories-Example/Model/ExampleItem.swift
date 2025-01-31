//
//  ExampleItem.swift
//  ACKategories-Example
//
//  Created by Jakub Olejník on 12/09/2018.
//  Copyright © 2018 Ackee, s.r.o. All rights reserved.
//

import Foundation

enum ExampleItem {
    case uiControlBlocks
    case viewControllerComposition
    
    static var allCases: [ExampleItem] { return [.uiControlBlocks, .viewControllerComposition] }
    
    var title: String { return data.title }
    var subtitle: String { return data.subtitle }
    
    private var data: (title: String, subtitle: String) {
        switch self {
        case .uiControlBlocks: return ("UIControl blocks", "Use closures instead of target - selector pattern")
        case .viewControllerComposition: return ("View controller composition", "Simply embed view controller into another one")
        }
    }
}
