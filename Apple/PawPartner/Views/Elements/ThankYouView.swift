import SwiftUI
import Kingfisher

struct ThankYouView: View {
    @ObservedObject var viewModel = AnimalViewModel.shared
    
    @State private var showAddNote = false
    @State private var toastAddNote = false
    @State private var imageLoaded = false
    @State private var isImageLoaded = false
    @AppStorage("customFormURL") var customFormURL = ""
    @AppStorage("isCustomFormOn") var isCustomFormOn = false
    @AppStorage("linkType") var linkType = "QR Code"
    @AppStorage("appendAnimalData") var appendAnimalData = false


    let animal: Animal
    
    @AppStorage("lastSync") var lastSync: String = ""
    
    @State private var showCustomQR = false
    @State private var showCustomLink = false
    
    var body: some View {
        ZStack {
            VStack {
                if let url = animal.photos.first?.url {
                    KFImage(URL(string: url))
                        .placeholder {
                            Image(systemName: "photo.circle.fill")
                                .resizable()
                                .foregroundStyle(.secondary)
                                .frame(width: 200, height: 200)
                        }
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200)))
                        .scaleFactor(UIScreen.main.scale)
                        .onSuccess { result in
                            print("Task done for: \(result.source.url?.absoluteString ?? "")")
                        }
                        .onFailure { error in
                            print("Job failed: \(error.localizedDescription)")
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                        .transition(.opacity)
                }
                Text("Thank You!")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .padding()
                VStack {
                    HStack {
                        Spacer()
                        Button("Close") {
                            viewModel.showLogCreated.toggle()
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                        .font(.title)
                        .italic()
                        Spacer()
                        Button {
                            viewModel.showLogCreated.toggle()
                            showAddNote.toggle()
                        } label: {
                            Label("Add Note", systemImage: "square.and.pencil")
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                        .font(.title)
                        .bold()
                        Spacer()
                    }
                    if isCustomFormOn {
                            Button {
                                if linkType == "QR Code" {
                                    showCustomQR.toggle()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                        showCustomQR = false
                                    }
                                } else {
                                    showCustomLink.toggle()
                                }
                                
                            } label: {
                                Label("Custom Form", systemImage: linkType == "QR Code" ? "qrcode" : "book.pages")
                            }
                            
                            .buttonStyle(.bordered)
                            .tint(.green)
                            .font(.title)
                            .bold()
                    }
                }
            }
            .padding()
            .frame(maxWidth: 350)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(radius: 8)
            )
            .sheet(isPresented: $showAddNote) {
                AddNoteView(animal: viewModel.animal)
            }
            .sheet(isPresented: $showCustomQR) {
                CustomQRCodeView(url: appendAnimalData ? "\(customFormURL)?animalID=\(animal.id)&animalName=\(animal.name)&logStart=\(animal.startTime)&logEnd=\(Date().timeIntervalSince1970)&logType=\(String(describing: animal.lastLetOutType))&logPerson=\(String(describing: animal.lastVolunteer))" : customFormURL)
            }
            .sheet(isPresented: $showCustomLink) {
                WebView(url: URL(string: appendAnimalData ? "\(customFormURL)?animalID=\(animal.id)&animalName=\(animal.name)&logStart=\(animal.startTime)&logEnd=\(Date().timeIntervalSince1970)&logType=\(String(describing: animal.lastLetOutType))&logPerson=\(String(describing: animal.lastVolunteer))" : customFormURL) ?? URL(string: "https://shelterpartner.org")!)
            }
        }
    }
    
    func loadImage(completion: @escaping (Bool) -> Void) {
        guard let urlString = animal.photos.first?.url else {
            completion(false)
            return
        }
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                completion(data != nil)
            }
        }
        task.resume()
    }

}

#Preview {
    ThankYouView(animal: Animal.dummyAnimal)
}
