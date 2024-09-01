//
//  Enums.swift
//  HumaneSociety
//
//  Created by Jared Jones on 12/2/23.
//

import Foundation

enum AnimalType: String, CaseIterable, Codable {
    case Cat = "Cat"
    case Dog = "Dog"
}

enum SortBy: String, CaseIterable, Codable {
    case lastLetOut = "Last Let Out"
    case playtime24Hours = "Playtime (Past 24 Hours)"
    case playtime7Days = "Playtime (Past 7 Days)"
    case playtime30Days = "Playtime (Past 30 Days)"
    case playtime90Days = "Playtime (Past 90 Days)"
    case alphabetical = "Alphabetical"
}
