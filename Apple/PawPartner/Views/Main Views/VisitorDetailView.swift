import SwiftUI
import Kingfisher
import FirebaseStorage
import FirebaseFirestore

struct VisitorDetailView: View {
    let animal: Animal

    var numberOfColumns: Int = 2


    var sortedNotes: [Note] {
        animal.notes
            .filter { !$0.note.isEmpty }
            .sorted(by: { $0.date > $1.date })
    }

    let averageCharactersPerLine: Int = 50

    private func estimateLines(for note: String) -> Int {
        return (note.count + averageCharactersPerLine - 1) / averageCharactersPerLine
    }

    private func notesForColumn(_ column: Int) -> [Note] {
        let totalLines = sortedNotes.map { estimateLines(for: $0.note) }.reduce(0, +)
        let targetLinesPerColumn = totalLines / numberOfColumns
        var currentLines = Array(repeating: 0, count: numberOfColumns)
        var columnNotes = Array(repeating: [Note](), count: numberOfColumns)

        for note in sortedNotes {
            let noteLines = estimateLines(for: note.note)
            if let columnIndex = currentLines.indices.min(by: { currentLines[$0] < currentLines[$1] && currentLines[$0] + noteLines <= targetLinesPerColumn }) {
                columnNotes[columnIndex].append(note)
                currentLines[columnIndex] += noteLines
            } else {
                if let columnIndex = currentLines.indices.min(by: { currentLines[$0] < currentLines[$1] }) {
                    columnNotes[columnIndex].append(note)
                    currentLines[columnIndex] += noteLines
                }
            }
        }

        return columnNotes[column]
    }


    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
//    @AppStorage("societyID") var storedSocietyID: String = ""
    @State private var isFullScreen = false
    @State private var selectedImageIndex = 0


    
    var body: some View {
        ScrollView {
            
            LazyVStack(alignment: .center) {
                VStack {
                    Text(animal.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        ForEach(topTags(for: animal), id: \.self) { tag in
                            Text(tag)
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
                TabView {
                    ForEach(animal.photos.indices, id: \.self) { index in
                        if let url = dailyCacheBustedURL(for: animal.photos[index].url) {
                            ZStack(alignment: .topTrailing) {
                                KFImage(url)
                                    .resizable()
                                    .placeholder { ProgressView().scaledToFill() }
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .onTapGesture {
                                        self.selectedImageIndex = index
                                        self.isFullScreen = true
                                    }
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .shadow(radius: 5)
                .frame(height: 400)
                .padding()

                AnimalDetailsSection(animal: animal)
                if !animal.notes.isEmpty && animal.notes.count > 1 {
                    Section {
                        VStack(alignment: .center) {
                            HStack(alignment: .top, spacing: 20) {
                                ForEach(0..<numberOfColumns, id: \.self) { column in
                                    VStack(alignment: .center, spacing: 10) {
                                        ForEach(notesForColumn(column), id: \.id) { note in
                                            if note.note != "Added animal to the app" {
                                                VisitorNoteView(note: note, animal: animal)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .padding(.bottom, 50)

                    } header: {
                        Text("Volunteer Notes")
                            .bold()
                            .underline()
                            .font(.title2)
                            .padding(.top)
                            .padding(.top)

                    }
                }
            }
            .padding(.horizontal)
            .fullScreenCover(isPresented: $isFullScreen) {
                ZStack(alignment: .topTrailing) {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(animal.photos.indices, id: \.self) { index in
                            if let url = dailyCacheBustedURL(for: animal.photos[index].url) {
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
                        isFullScreen = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.red.opacity(0.8))
                            .background(.regularMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                            
                    }
                }
                .ignoresSafeArea(.all)

            }
            .padding(.top, 20)  // Adjust the padding as needed to fit within the safe area
            .padding(.trailing, 20)
        }
    }
    
    private func dailyCacheBustedURL(for urlString: String) -> URL? {
        guard var urlComponents = URLComponents(string: urlString) else { return nil }

        // Use a DateFormatter to generate a string that changes once a day
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd" // Year, month, day format
        let dateStamp = dateFormatter.string(from: Date())

        let queryItem = URLQueryItem(name: "cacheBust", value: dateStamp)
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + [queryItem]
        return urlComponents.url
    }
    
    func topTags(for animal: Animal, count: Int = 3) -> [String] {
        let sortedTags = animal.tags?.sorted { $0.value > $1.value }
            .map { $0.key }
            .prefix(count)
        
        return Array(sortedTags ?? [])
    }
    
    func imageExists(at url: URL, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
}

struct FullScreenImageView: View {
    let images: [String] // Assuming these are URLs in String format
    @State var selectedImageIndex: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(images.indices, id: \.self) { index in
                if let url = URL(string: images[index]) {
                    KFImage(url)
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                        .onTapGesture {
                            dismiss()
                        }
                }
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
}
