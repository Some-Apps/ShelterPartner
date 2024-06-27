import FirebaseAuth
import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel = AuthenticationViewModel.shared
    @AppStorage("accountType") var accountType = "volunteer"
    
    var body: some View {
        if viewModel.isSignedIn {
            switch accountType {
            case "admin":
                TabView {
                        AnimalView()
                            .task {
                                viewModel.fetchUserAccountType(userID: Auth.auth().currentUser?.uid ?? "noAccount")
                            }
                            .tabItem {
                                Label("Volunteer", systemImage: "pawprint.fill")
                            }
                        VisitorView()
                            .task {
                                viewModel.fetchUserAccountType(userID: Auth.auth().currentUser?.uid ?? "noAccount")
                            }
                            .tabItem {
                                Label("Visitor", systemImage: "person.2.circle.fill")
                            }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .task {
                    viewModel.fetchUserAccountType(userID: Auth.auth().currentUser?.uid ?? "noAccount")
                }
            case "volunteer":
                TabView {
                    AnimalView()
                        .task {
                            viewModel.fetchUserAccountType(userID: Auth.auth().currentUser?.uid ?? "noAccount")
                        }
                        .tabItem {
                            Label("Volunteer", systemImage: "pawprint.fill")
                        }
                    VisitorView()
                        .task {
                            viewModel.fetchUserAccountType(userID: Auth.auth().currentUser?.uid ?? "noAccount")
                        }
                        .tabItem {
                            Label("Visitor", systemImage: "person.2.circle.fill")
                        }
                }
                   

               
            default:
                TabView {
                    AnimalView()
                        .task {
                            viewModel.fetchUserAccountType(userID: Auth.auth().currentUser?.uid ?? "noAccount")
                        }
                        .tabItem {
                            Label("Volunteer", systemImage: "pawprint.fill")
                        }
                    VisitorView()
                        .task {
                            viewModel.fetchUserAccountType(userID: Auth.auth().currentUser?.uid ?? "noAccount")
                        }
                        .tabItem {
                            Label("Visitor", systemImage: "person.2.circle.fill")
                        }
                }
            }
        } else {
            LoginView()
                .task {
                    viewModel.fetchUserAccountType(userID: Auth.auth().currentUser?.uid ?? "noAccount")
                }
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
