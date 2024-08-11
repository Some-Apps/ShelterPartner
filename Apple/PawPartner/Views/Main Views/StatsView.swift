import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel = AnimalViewModel.shared

    var body: some View {
        Form {
            Text("Animals in Shelter: \(viewModel.cats.count + viewModel.dogs.count)")
            Text("Animals Availble to Take Out: \(viewModel.sortedCats.count + viewModel.sortedDogs.count)")
        }
    }
}
