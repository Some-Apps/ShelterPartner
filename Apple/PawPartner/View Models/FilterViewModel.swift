import SwiftUI

class FilterViewModel: ObservableObject {
    @Published var filters: [FilterCondition] = [FilterCondition()]
    
    var filterFormula: String {
        var formula = ""
        
        for (index, filter) in filters.enumerated() {

            
            if index > 0 {
                formula += " \(filter.conjunction) "
            }
            
            formula += "\(filter.field) \(filter.condition) \(filter.value)"
        }
        
        return formula
    }
    
    func addFilter(conjunction: String) {
        let newFilter = FilterCondition(conjunction: conjunction)
        filters.append(newFilter)
    }
    
    func deleteFilter(at offsets: IndexSet) {
        filters.remove(atOffsets: offsets)
    }
}
