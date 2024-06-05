import Firebase
import FirebaseFirestore
import SwiftUI

class FilterViewModel: ObservableObject {
//    @Published var filters: [FilterCondition] = []
    @Published var canPlayFilter: [FilterCondition] = []
    
    @AppStorage("societyID") var shelterID = ""

    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?

    init() {
        fetchFilters()
    }

    deinit {
        listenerRegistration?.remove()
    }
    
    func fetchFilters() {
            listenerRegistration = db.collection("Societies").document(shelterID).addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                
                if let data = document.data(), let filtersArray = data["canPlayFilter"] as? [[String: Any]] {
                    self.canPlayFilter = filtersArray.compactMap { dict -> FilterCondition? in
                        guard let field = dict["field"] as? String,
                              let condition = dict["condition"] as? String,
                              let value = dict["value"] as? String,
                              let groupWithPrevious = dict["groupWithPrevious"] as? Bool,
                              let conjunction = dict["conjunction"] as? String else { return nil }
                        return FilterCondition(field: field, condition: condition, value: value, groupWithPrevious: groupWithPrevious, conjunction: conjunction)
                    }
                }
            }
        }
    
    func saveFiltersToFirebase() {
        let filtersArray = canPlayFilter.map { filter in
            [
                "field": filter.field,
                "condition": filter.condition,
                "value": filter.value,
                "groupWithPrevious": filter.groupWithPrevious,
                "conjunction": filter.conjunction
            ] as [String: Any]
        }
        
        db.collection("Societies").document(shelterID).setData(["canPlayFilter": filtersArray]) { error in
            if let error = error {
                print("Error saving document: \(error)")
            } else {
                print("Document successfully saved!")
            }
        }
    }
    
    struct ColoredText: Identifiable {
        let id = UUID()
        let text: Text
    }
    
    var filterFormula: [ColoredText] {
        var formula: [ColoredText] = []
        var openParentheses = false
        
        for (index, filter) in canPlayFilter.enumerated() {
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
            
            if openParentheses && (index == canPlayFilter.count - 1 || !canPlayFilter[index + 1].groupWithPrevious) {
                let currentIndex = formula.count - 1
                formula[currentIndex] = ColoredText(text: formula[currentIndex].text + Text(")"))
                openParentheses = false
            }
        }
        
        return formula
    }
    
    func addFilter(conjunction: String) {
        let newFilter = FilterCondition(conjunction: conjunction)
        canPlayFilter.append(newFilter)
    }
    
    func deleteFilter(at offsets: IndexSet) {
        canPlayFilter.remove(atOffsets: offsets)
    }
}
