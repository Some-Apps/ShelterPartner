import FirebaseAuth
import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel = AuthenticationViewModel.shared
//    @AppStorage("accountType") var accountType = "volunteer"
    
    var body: some View {
        if viewModel.isSignedIn {
            switch viewModel.accountType {
            case "admin":
                TabView {
                        AnimalView()
                            .tabItem {
                                Label("Volunteer", systemImage: "pawprint.fill")
                            }
                        VisitorView()
                         
                            .tabItem {
                                Label("Visitor", systemImage: "person.2.circle.fill")
                            }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .onAppear {
                    print("Admin")
                    print(viewModel.shelterID)
                    print(viewModel.accountType)
                }
                
            case "volunteer":
                TabView {
                    AnimalView()
                   
                        .tabItem {
                            Label("Volunteer", systemImage: "pawprint.fill")
                        }
                    VisitorView()
                     
                        .tabItem {
                            Label("Visitor", systemImage: "person.2.circle.fill")
                        }
                    VisitorSettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .onAppear {
                    print("Volunteer")
                    print(viewModel.shelterID)
                    print(viewModel.accountType)
                }

               
            default:
                TabView {
                    AnimalView()
                      
                        .tabItem {
                            Label("Volunteer", systemImage: "pawprint.fill")
                        }
                    VisitorView()
                      
                        .tabItem {
                            Label("Visitor", systemImage: "person.2.circle.fill")
                        }
                }
                .onAppear {
                    print("Other")
                    print(viewModel.shelterID)
                    print(viewModel.accountType)
                }
            }
        } else {
            LoginView()
              
        }
    }
}

