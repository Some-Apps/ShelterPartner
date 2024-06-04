import SwiftUI

struct FilterView: View {
    @StateObject private var viewModel = FilterViewModel()
    
    let fields = ["location", "status"]
    let conditions = ["equals", "contains", "greater than", "less than"]
    
    var body: some View {
        VStack {
            Text(viewModel.filterFormula)
                .padding()
            List {
                ForEach(viewModel.filters) { filter in
                    VStack {
                        HStack {
                            Picker("Field", selection: $viewModel.filters[viewModel.filters.firstIndex(where: { $0.id == filter.id })!].field) {
                                ForEach(fields, id: \.self) { field in
                                    Text(field)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .labelsHidden()
                            Picker("Condition", selection: $viewModel.filters[viewModel.filters.firstIndex(where: { $0.id == filter.id })!].condition) {
                                ForEach(conditions, id: \.self) { condition in
                                    Text(condition)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .labelsHidden()
                            TextField("Value", text: $viewModel.filters[viewModel.filters.firstIndex(where: { $0.id == filter.id })!].value)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        if viewModel.filters.firstIndex(where: { $0.id == filter.id })! > 0 {
                            Toggle("Group with previous filter?", isOn: $viewModel.filters[viewModel.filters.firstIndex(where: { $0.id == filter.id })!].groupWithPrevious)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            if let index = viewModel.filters.firstIndex(where: { $0.id == filter.id }) {
                                viewModel.filters.remove(at: index)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteFilter)
            }
            
            HStack {
                Button(action: {
                    viewModel.addFilter(conjunction: "AND")
                }) {
                    Text("AND")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    viewModel.addFilter(conjunction: "OR")
                }) {
                    Text("OR")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .padding()
    }
}
