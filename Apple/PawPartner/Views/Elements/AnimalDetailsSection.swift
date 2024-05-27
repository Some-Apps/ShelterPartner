import SwiftUI

struct AnimalDetailsSection: View {
    let animal: Animal

    let columns = [
        GridItem(.adaptive(minimum: 150))
    ]

    var body: some View {
        if animal.sex != nil || animal.age != nil || animal.breed != nil {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 20) {
                        if let sex = animal.sex {
                            DetailCard(title: "Sex", detail: sex)
                        }
                        
                        if let breed = animal.breed {
                            DetailCard(title: "Breed", detail: breed)
                        }
                        
                        if let age = animal.age {
                            DetailCard(title: "Age", detail: age)
                        }
                    }
                    .padding()
                }
                
                if let animalDescription = animal.description, animalDescription.count > 0 {
                    Divider()
                    Text(animalDescription)
                        .font(.title3)
                        .padding()
                        .transition(.opacity)
                }
            }
        }
    }
}

struct DetailCard: View {
    let title: String
    let detail: String

    var body: some View {
        VStack {
            Text(title)
                .underline()
                .foregroundStyle(.secondary)
                .padding(.bottom, 1)
            Text(detail)
                .font(.title3)
                .lineLimit(1)
                .bold()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
                .shadow(radius: 3)
        )
        .multilineTextAlignment(.center)
    }
}
