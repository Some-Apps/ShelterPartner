import SwiftUI

class FilterViewModel: ObservableObject {
    @Published var filters: [FilterCondition] = [FilterCondition()]
    
    struct ColoredText: Identifiable {
        let id = UUID()
        let text: Text
    }
    
    var filterFormula: [ColoredText] {
        var formula: [ColoredText] = []
        var openParentheses = false
        
        for (index, filter) in filters.enumerated() {
            if filter.groupWithPrevious && !openParentheses {
                let previousIndex = formula.count - 1
                if previousIndex >= 0 {
                    formula[previousIndex] = ColoredText(text: Text("(") + formula[previousIndex].text)
                }
                openParentheses = true
            }
            
            if index > 0 {
                let conjunction = "\(filter.conjunction)"
                formula.append(ColoredText(text: Text(conjunction).foregroundColor(.gray)))
            }
            
            
            
            let line = Text(filter.field).foregroundColor(.green) +
                Text(" \(filter.condition) ").foregroundColor(.red) +
                Text("\"\(filter.value)\"").foregroundColor(.blue)
            
            formula.append(ColoredText(text: line))
            
            if openParentheses && (index == filters.count - 1 || !filters[index + 1].groupWithPrevious) {
                let currentIndex = formula.count - 1
                formula[currentIndex] = ColoredText(text: formula[currentIndex].text + Text(")"))
                openParentheses = false
            }
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
