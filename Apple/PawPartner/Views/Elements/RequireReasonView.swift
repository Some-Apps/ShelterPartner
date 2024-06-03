import SwiftUI
import FirebaseFirestore

struct RequireReasonView: View {
    
    @AppStorage("shortReason") var shortReason = ""
    @ObservedObject var cardViewModel = CardViewModel()
    @ObservedObject var viewModel = AnimalViewModel.shared
    @AppStorage("societyID") var storedSocietyID: String = ""
    @FocusState private var focusField: Bool
    let animal: Animal

    var body: some View {
        VStack {
            Text("Please enter the reason you put this animal back before the minimum duration.")
            TextEditor(text: $shortReason)
                .focused($focusField)
                .onChange(of: viewModel.showRequireReason) { show in
                    if show {
                        focusField = true
                    }
                }
                .onDisappear {
                    focusField = false
                }
            HStack {
                Button("Nevermind") {
                    viewModel.showRequireReason = false
                    focusField = false
                    shortReason = ""
                }
                Button("Submit") {
                    cardViewModel.putBack(animal: animal)
                    viewModel.showRequireReason = false
                    focusField = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        shortReason = ""
                    }
                }
                .tint(.green)
                .disabled(shortReason.count < 1)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: 500, maxHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(radius: 8)
        )
        
    }
}

