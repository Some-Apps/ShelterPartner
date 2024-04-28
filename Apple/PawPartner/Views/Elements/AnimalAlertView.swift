//
//  AnimalAlertView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 12/2/23.
//

import SwiftUI

struct AnimalAlertView: View {
    @ObservedObject var viewModel = AnimalViewModel.shared
    @ObservedObject var cardViewModel = CardViewModel()
    let animal: Animal

    
    var body: some View {
        VStack {
            HStack {
//                Image(systemName: "exclamationmark.triangle.fill")
//                    .foregroundColor(.red)
                Text("Alert For \(animal.name)")
                    .multilineTextAlignment(.center)
//                Image(systemName: "exclamationmark.triangle.fill")
//                    .foregroundColor(.red)
            }
            .fontWeight(.bold)
            .font(.largeTitle)
            .padding()
            Divider()
            Text(animal.alert)
                .font(.title)
//                .bold()
                .padding()
            Divider()
            HStack {
                Spacer()
                Button("Cancel") {
                    viewModel.showAnimalAlert = false
                }
                .padding(.top)
                .buttonStyle(.bordered)
                .tint(.accentColor)
                .font(.title2)
                .italic()
                Spacer()
                Button("I Understand") {
                    viewModel.showAnimalAlert = false
                    cardViewModel.takeOut(animal: animal)
                }
                .padding(.top)
                .buttonStyle(.bordered)
                .tint(.green)
                .font(.title2)
                .bold()
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: 350)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(radius: 10)
        )
    }
}

//#Preview {
//    AnimalAlertView(viewModel: AnimalViewModel(), cardViewModel: CardViewModel())
//}
