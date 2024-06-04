//
//  Filter.swift
//  HumaneSociety
//
//  Created by Jared Jones on 6/4/24.
//

import SwiftUI

struct FilterCondition: Identifiable {
    let id = UUID()
    var field: String = "location"
    var condition: String = "equals"
    var value: String = ""
    var groupWithPrevious: Bool = false
    var conjunction: String = "AND"
}
