import SwiftUI
import Kingfisher

struct ViewInfoView: View {
    @ObservedObject var viewModel: ViewInfoViewModel
    
    var numberOfColumns: Int = 2
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
    @AppStorage("lastSync") var lastSync: String = ""
    
    var body: some View {
        ScrollView {
            LazyVStack {
                VStack {
                    Text(viewModel.animal.name + " ")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal)
                    
                    HStack {
                        ForEach(viewModel.topTags(for: viewModel.animal), id: \.self) { tag in
                            HStack {
                                Text(tag)
                                if viewModel.authViewModel.accountType == "admin" && viewModel.adminMode {
                                    Button {
                                        viewModel.tagToDelete = tag
                                        viewModel.confirmDeleteTag = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                            .font(.body)
                                            .opacity(0.5)
                                    }
                                    .confirmationDialog("Are you sure?", isPresented: $viewModel.confirmDeleteTag) {
                                        Button("I'm sure", role: .destructive) {
                                            if let tag = viewModel.tagToDelete {
                                                viewModel.deleteTag(tag: tag)
                                            }
                                            viewModel.tagToDelete = nil // Reset the tag to delete
                                        }
                                        Button("Cancel", role: .cancel) {
                                            viewModel.tagToDelete = nil // Reset the tag to delete
                                        }
                                    } message: {
                                        if let tag = viewModel.tagToDelete {
                                            Text("Are you sure you want to delete the tag \(tag)? This cannot be undone.")
                                        }
                                    }
                                }
                            }
                            .font(.title3)
                            .padding(.horizontal, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.2), radius: 0.5, x: 0.5, y: 1)
                        }
                    }
                }
                TabView(selection: $viewModel.selectedImageIndex) {
                    ForEach(viewModel.photos.indices, id: \.self) { index in
                        if let url = viewModel.dailyCacheBustedURL(for: viewModel.photos[index].url) {
                            ZStack(alignment: .topTrailing) {
                                KFImage(url)
                                    .resizable()
                                    .placeholder {
                                        ProgressView() // Placeholder while the image loads
                                            .scaledToFill()
                                    }
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .onTapGesture {
                                        self.viewModel.selectedImageIndex = index
                                        self.viewModel.isFullScreen = true
                                    }
                                    .tag(index) // Important for selection
                                if viewModel.authViewModel.accountType == "admin" && viewModel.adminMode, let host = url.host, host.contains("storage.googleapis.com") {
                                    Button(action: {
                                        viewModel.confirmDeletePhoto.toggle()
                                    }) {
                                        Image(systemName: "trash")
                                            .padding(10)
                                            .background(Color.white.opacity(0.7))
                                            .clipShape(Circle())
                                            .foregroundStyle(.red)
                                    }
                                    .padding()
                                    .confirmationDialog("Are you sure?", isPresented: $viewModel.confirmDeletePhoto) {
                                        Button("I'm sure", role: .destructive) {
                                            viewModel.deleteImage(urlString: viewModel.photos[viewModel.selectedImageIndex].privateURL)
                                        }
                                    } message: {
                                        Text("Are you sure you want to delete this photo? This cannot be undone.")
                                    }
                                }
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .shadow(radius: 5)
                .frame(height: 400)
                .padding()
                AnimalDetailsSection(animal: viewModel.animal)

                if !viewModel.notes.isEmpty {
                    VStack(alignment: .center) {
                        HStack(alignment: .top, spacing: 20) {
                            ForEach(0..<numberOfColumns, id: \.self) { column in
                                VStack(alignment: .center, spacing: 10) {
                                    ForEach(viewModel.notesForColumn(column).indices, id: \.self) { noteIndex in
                                        if viewModel.notesForColumn(column)[noteIndex].note != "Added animal to the app" {
                                            NoteView(note: Binding(
                                                get: { viewModel.notesForColumn(column)[noteIndex] },
                                                set: { viewModel.notes[noteIndex] = $0 }
                                            ), onDelete: {
                                                viewModel.deleteNote(noteID: viewModel.notesForColumn(column)[noteIndex].id)
                                            }, animal: viewModel.animal)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .padding(.bottom, 50)
                }
                
                
            }
        }
        .fullScreenCover(isPresented: $viewModel.isFullScreen) {
            ZStack(alignment: .bottom) {
                TabView(selection: $viewModel.selectedImageIndex) {
                    ForEach(viewModel.photos.indices, id: \.self) { index in
                        if let url = viewModel.dailyCacheBustedURL(for: viewModel.photos[index].url) {
                            KFImage(url)
                                .resizable()
                                .scaledToFit()
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .background(Color.white)
                
                Button(action: {
                    viewModel.isFullScreen = false // This dismisses the full screen cover
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .padding()
                        .foregroundStyle(.red.opacity(0.8))
                        .background(.regularMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .padding()
                }
//                .padding(.top)
                .padding(.bottom)  // Adjust the padding as needed to fit within the safe area
            }
            .ignoresSafeArea(.all)
        }
    }
}
