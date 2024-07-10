import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import AlertToast
import CoreLocation
import MapKit

struct Volunteer: Identifiable {
    var id: String
    var name: String
    var email: String
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.distanceFilter = 100
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.location = location.coordinate
        } else {
            print("No locations available in didUpdateLocations.")
        }
    }


    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
    }

    func isWithinBounds(center: CLLocationCoordinate2D, radius: Double) -> Bool {
        print("Checking bounds with center: \(center), radius: \(radius)")
        
        guard let currentLocation = location else {
            print("Current location is nil")
            return false
        }

        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let currentCLLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let distance = centerLocation.distance(from: currentCLLocation)
        
        print("Distance: \(distance), within bounds: \(distance <= radius)")
        
        return distance <= radius
    }

}

struct VolunteerAccountsView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showToast = false
    @State private var volunteers: [Volunteer] = []
    @State private var volunteerToDelete: Volunteer?
    @State private var isDeleting = false
    @State private var isShowingDeleteAlert = false
    @State private var georestrictionEnabled = false
    @State private var georestrictionCenter = CLLocationCoordinate2D()
    @State private var georestrictionRadius = 1000.0 // in meters
    @State private var zoomLevel: Double = 0.05
    @ObservedObject var locationManager = LocationManager()
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    
    var body: some View {
        GeometryReader { geometry in
            let minDimension = min(geometry.size.width, geometry.size.height)
            
            Form {
                Section("Add Volunteer") {
                    TextField("Volunteer Name", text: $name)
                    TextField("Volunteer Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    Button("Send Invite") {
                        sendInvite()
                    }
                }
                if !volunteers.isEmpty {
                    Section("Volunteers") {
                        List {
                            ForEach(volunteers) { volunteer in
                                NavigationLink(destination: VolunteerDetailView(volunteer: volunteer)) {
                                    HStack {
                                        Text(volunteer.name)
                                        Text(" (\(volunteer.email))")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .onDelete(perform: showDeleteConfirmation)
                        }
                    }
                }

                Section("Geo-Restrict Volunteer Accounts") {
                    Toggle(isOn: $georestrictionEnabled) {
                        Text("Enable Geo-Restriction")
                    }
                    .tint(.customBlue)
                    .onChange(of: georestrictionEnabled) { _ in
                        updateGeorestrictionSettings()
                    }
                    
                    if georestrictionEnabled {
                        VStack {
                            Text("Center Location")
                            MapView(centerCoordinate: $georestrictionCenter, radius: $georestrictionRadius, zoomLevel: $zoomLevel, locationManager: locationManager)
                                .frame(width: minDimension * 0.8, height: minDimension * 0.8) // 80% of the smaller dimension
                            Text("Radius: \(Int(georestrictionRadius)) meters")
                            Slider(value: $georestrictionRadius, in: 100...5000, step: 100)
                            Text("Zoom Level")
                            Slider(value: $zoomLevel, in: 0.01...0.2, step: 0.001)
                        }
                        .onAppear {
                            fetchGeorestrictionSettings()
                            if georestrictionCenter.latitude == 0 && georestrictionCenter.longitude == 0 {
                                if let location = locationManager.location {
                                    georestrictionCenter = location
                                }
                            }
                        }
                        .onDisappear {
                            updateGeorestrictionSettings()
                        }
                    }
                }
            }
            .onAppear {
                fetchVolunteers()
                fetchGeorestrictionSettings()
            }
            .alert(isPresented: $isShowingDeleteAlert) {
                Alert(
                    title: Text("Confirm Delete"),
                    message: Text("Are you sure you want to delete \(volunteerToDelete?.name ?? "this volunteer")?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let volunteer = volunteerToDelete {
                            deleteVolunteer(volunteer: volunteer)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .toast(isPresenting: $showingAlert) {
                AlertToast(displayMode: .alert, type: .complete(.green), title: alertMessage)
            }
            .toast(isPresenting: $showToast) {
                AlertToast(type: .loading, title: "Sending Invite...")
            }
            .toast(isPresenting: $isDeleting) {
                AlertToast(type: .loading, title: "Deleting Volunteer...")
            }
        }
    }

    private func sendInvite() {
        showToast = true
        let password = generateRandomPassword()
        
        guard let url = URL(string: "https://us-central1-pawpartnerdevelopment.cloudfunctions.net/VolunteerInvite") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "email": email,
            "password": password,
            "shelterID": authViewModel.shelterID
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertMessage = "Error sending invite: \(error.localizedDescription)"
                    self.showingAlert = true
                    self.showToast = false
                    return
                }
                
                if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    self.alertMessage = "Invite sent successfully!"
                    self.showingAlert = true
                    self.name = ""
                    self.email = ""
                    self.showToast = false
                    self.fetchVolunteers() // Refresh the list after adding a new volunteer
                } else {
                    self.alertMessage = "Failed to send invite."
                    self.showingAlert = true
                    self.showToast = false
                }
            }
        }.resume()
    }

    private func generateRandomPassword() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    private func fetchVolunteers() {
        let db = Firestore.firestore()
        db.collection("Users")
            .whereField("societyID", isEqualTo: authViewModel.shelterID)
            .whereField("type", isEqualTo: "volunteer")
            .order(by: "name")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.alertMessage = "Error fetching volunteers: \(error.localizedDescription)"
                        self.showingAlert = true
                    } else {
                        self.volunteers = snapshot?.documents.compactMap { doc in
                            let data = doc.data()
                            return Volunteer(
                                id: doc.documentID,
                                name: data["name"] as? String ?? "",
                                email: data["email"] as? String ?? ""
                            )
                        } ?? []
                    }
                }
            }
    }

    private func fetchGeorestrictionSettings() {
        let db = Firestore.firestore()
        let shelterDocRef = db.collection("Societies").document(authViewModel.shelterID)
        shelterDocRef.getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                if let georestriction = data["georestriction"] as? [String: Any] {
                    self.georestrictionEnabled = georestriction["enabled"] as? Bool ?? false
                    if let center = georestriction["center"] as? GeoPoint {
                        self.georestrictionCenter = CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude)
                    }
                    self.georestrictionRadius = georestriction["radius"] as? Double ?? 1000.0
                    self.zoomLevel = georestriction["zoomLevel"] as? Double ?? 0.05
                }
            } else {
                print("Document does not exist or error fetching document: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }

    private func updateGeorestrictionSettings() {
        let db = Firestore.firestore()
        let shelterDocRef = db.collection("Societies").document(authViewModel.shelterID)
        let centerGeoPoint = GeoPoint(latitude: georestrictionCenter.latitude, longitude: georestrictionCenter.longitude)
        shelterDocRef.setData([
            "georestriction": [
                "enabled": georestrictionEnabled,
                "center": centerGeoPoint,
                "radius": georestrictionRadius,
                "zoomLevel": zoomLevel
            ]
        ], merge: true) { error in
            if let error = error {
                self.alertMessage = "Error updating georestriction settings: \(error.localizedDescription)"
                self.showingAlert = true
            }
        }
    }

    private func showDeleteConfirmation(at offsets: IndexSet) {
        if let index = offsets.first {
            volunteerToDelete = volunteers[index]
            isShowingDeleteAlert = true
        }
    }

    private func deleteVolunteer(volunteer: Volunteer) {
        isDeleting = true
        let db = Firestore.firestore()
        db.collection("Users").document(volunteer.id).delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertMessage = "Error deleting volunteer: \(error.localizedDescription)"
                    self.showingAlert = true
                    self.isDeleting = false
                } else {
                    self.callDeleteUserFunction(uid: volunteer.id) // Call cloud function to delete from Firebase Auth
                    if let index = self.volunteers.firstIndex(where: { $0.id == volunteer.id }) {
                        self.volunteers.remove(at: index)
                    }
                }
            }
        }
    }
    
    private func callDeleteUserFunction(uid: String) {
        guard let url = URL(string: "https://us-central1-pawpartnerdevelopment.cloudfunctions.net/RemoveVolunteer") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "uid": uid
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertMessage = "Error deleting volunteer: \(error.localizedDescription)"
                    self.showingAlert = true
                } else if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    self.alertMessage = "Volunteer deleted successfully!"
                    self.showingAlert = true
                } else {
                    self.alertMessage = "Failed to delete volunteer."
                    self.showingAlert = true
                }
                self.isDeleting = false
            }
        }.resume()
    }
}

struct VolunteerDetailView: View {
    var volunteer: Volunteer

    var body: some View {
        Text("Detail view for \(volunteer.name)")
    }
}

struct MapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var radius: Double
    @Binding var zoomLevel: Double
    var locationManager: LocationManager

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Add center button
        let button = UIButton(type: .system)
//        button.setTitle("Center", for: .normal)
        button.setImage(UIImage(systemName: "location.circle.fill"), for: .normal)
        button.addTarget(context.coordinator, action: #selector(context.coordinator.centerMap), for: .touchUpInside)
        button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        
        mapView.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -10),
            button.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -10),
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        let invertedZoomLevel = 0.2 - zoomLevel
        let region = MKCoordinateRegion(center: centerCoordinate, span: MKCoordinateSpan(latitudeDelta: invertedZoomLevel, longitudeDelta: invertedZoomLevel))
        view.setRegion(region, animated: true)
        view.removeAnnotations(view.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = centerCoordinate
        view.addAnnotation(annotation)
        view.removeOverlays(view.overlays)
        let circle = MKCircle(center: centerCoordinate, radius: radius)
        view.addOverlay(circle)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, locationManager: locationManager)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var locationManager: LocationManager

        init(_ parent: MapView, locationManager: LocationManager) {
            self.parent = parent
            self.locationManager = locationManager
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circleOverlay)
                renderer.strokeColor = .blue
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.centerCoordinate = mapView.centerCoordinate
        }
        
        @objc func centerMap() {
            if let location = locationManager.location {
                parent.centerCoordinate = location
            }
        }
    }
}
