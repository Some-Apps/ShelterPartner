import SwiftUI

struct DeviceSettingsView: View {
    @AppStorage("minimumDuration") var minimumDuration = 5
    @AppStorage("cardsPerPage") var cardsPerPage = 30
    @AppStorage("customFormURL") var customFormURL = ""
    @AppStorage("isCustomFormOn") var isCustomFormOn = false
    @AppStorage("linkType") var linkType = "QR Code"
    @AppStorage("showNoteDates") var showNoteDates = true
    @AppStorage("requireName") var requireName = false
    @AppStorage("groupsEnabled") var groupsEnabled = false
    @AppStorage("showAllAnimals") var showAllAnimals = false
    @AppStorage("createLogsAlways") var createLogsAlways = false
    @AppStorage("requireReason") var requireReason = false
    @AppStorage("showSearchBar") var showSearchBar = false
    @AppStorage("secondarySortOption") var secondarySortOption = ""

    @ObservedObject var viewModel = SettingsViewModel.shared
    @ObservedObject var animalViewModel = AnimalViewModel.shared

    
    @AppStorage("filterPicker") var filterPicker: Bool = false
    
    @State private var showPopover1 = false
    @State private var showPopover2 = false
    @State private var showPopover3 = false
    @State private var showPopover4 = false
    @State private var showPopover5 = false
    @State private var showPopover6 = false
    @State private var showPopover7 = false
    @State private var showPopover8 = false
    @State private var showPopover9 = false
    @State private var showPopover10 = false
    @State private var showPopover11 = false
    
    let linkTypes = ["QR Code", "Open In App"]
    
    var body: some View {
        Form {
            Section {
                Stepper(minimumDuration == 1 ? "\(minimumDuration) minute" : "\(minimumDuration) minutes", value: $minimumDuration, in: 0...30, step: 1)
            } header: {
                HStack {
                    Text("Minimum Log Duration")
                    Button {
                        showPopover1 = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $showPopover1) {
                        Text("This sets the minimum duration for a visit. If a volunteer takes out an animal for a visit lasting less than this amount, it will show an error and not count the visit.")
                            .padding()
                            .textCase(nil)
                    }
                }
            }
            
            Section {
                Toggle(requireReason ? "Enabled" : "Disabled", isOn: $requireReason)
                    .tint(.blue)
            } header: {
                HStack {
                    Text("Require Reason When Under Minimum Duration")
                    Button {
                        showPopover8 = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $showPopover8) {
                        Text("This will require users to add a reason for why they put the animal back before the minimum duration.")
                            .padding()
                            .textCase(nil)
                    }
                }
            }
            
            Section {
                Toggle(createLogsAlways ? "Enabled" : "Disabled", isOn: $createLogsAlways)
                    .tint(.blue)
            } header: {
                HStack {
                    Text("Create Logs Even Under Minimum Duration")
                    Button {
                        showPopover7 = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $showPopover7) {
                        Text("This will create a log for animals that are put back before the minimum duration.")
                            .padding()
                            .textCase(nil)
                    }
                }
            }

            Section {
                Stepper(cardsPerPage == 1 ? "\(cardsPerPage) card per page" : "\(cardsPerPage) cards per page", value: $cardsPerPage, in: 1...200, step: 1)
            } header: {
                HStack {
                    Text("Cards Per Page")
                    Button {
                        showPopover2 = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $showPopover2) {
                        Text("Cards are split into pages to ensure smooth performance. Depending on your device, you may be able to raise this number. However, if you notice the app is running slowing, you should lower this number until it runs smoothly.")
                            .padding()
                            .textCase(nil)
                    }
                }
            }
            
           


            Section {
                Toggle(showNoteDates ? "Enabled" : "Disabled", isOn: $showNoteDates)
                    .tint(.blue)
            } header: {
                HStack {
                    Text("Show Note Dates")
                    Button {
                        showPopover4 = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $showPopover4) {
                        Text("This displays the date a note was created")
                            .padding()
                            .textCase(nil)
                    }
                }
            }
            
            Section {
                Toggle(requireName ? "Enabled" : "Disabled", isOn: $requireName)
                    .tint(.blue)
            } header: {
                HStack {
                    Text("Require Name")
                    Button {
                        showPopover5 = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $showPopover5) {
                        Text("Before an animal can be taken out, you must enter your name.")
                            .padding()
                            .textCase(nil)
                    }
                }
            }
 
//            Section {
//                Toggle("Filter Picker", isOn: $filterPicker)
//                    .disabled(viewModel.filterOptions.isEmpty)
//                    .tint(.blue)
//                    .onAppear {
//                        if viewModel.filterOptions.isEmpty {
//                            filterPicker = false
//                        }
//                    }
//            } footer: {
//                Text(viewModel.filterOptions.isEmpty ? "Allow users to selected from additional filters on the main screen. As of now, this requires additional setup. Feel free to email jared@pawpartner.app if you're interested in using this feature." : "Allow users to filter animals from the main page.")
//            }
            
            Section {
                Toggle(isCustomFormOn ? "Enabled" : "Disabled", isOn: $isCustomFormOn)
                    .tint(.blue)
                TextField("https://example.com", text: $customFormURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(!isCustomFormOn)
                    .foregroundStyle(isCustomFormOn ? .primary : .secondary)
                Picker("Button Type", selection: $linkType) {
                    ForEach(linkTypes, id: \.self) {
                        Text($0)
                    }
                }
                .disabled(!isCustomFormOn)
                .foregroundStyle(isCustomFormOn ? .primary : .secondary)
            } header: {
                HStack {
                    Text("Custom Form")
                    Button {
                        showPopover6 = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $showPopover6) {
                        Text("If you would like to prompt users to fill out a custom form of your choice after visiting with an animal, add the url and turn on the toggle. This will display a \"Custom Form\" button on the \"Thank You\" pop up after putting an animal back. If the button doesn't work, make sure your url begins with https://")
                            .padding()
                            .textCase(nil)
                    }
                }
            }
            
            
            Section {
                Toggle(showAllAnimals ? "Enabled" : "Disabled", isOn: $showAllAnimals)
                    .tint(.blue)
            } header: {
                HStack {
                    Text("Display All Animals")
                    Button {
                        showPopover9 = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $showPopover9) {
                        Text("This will display all animals including ones you've selected to filter out. Filtered animals will be gray and won't be able to be taken out.")
                            .padding()
                            .textCase(nil)
                    }
                }
            }
            
            Section {
                Toggle(showSearchBar ? "Enabled" : "Disabled", isOn: $showSearchBar)
                    .tint(.blue)
            } header: {
                HStack {
                    Text("Show Search Bar")
                    Button {
                        showPopover10 = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $showPopover10) {
                        Text("This allows you to search animals by name, notes, breed, etc from the volunteer screen.")
                            .padding()
                            .textCase(nil)
                    }
                }
            }
            
            Section {
                Toggle(groupsEnabled ? "Enabled" : "Disabled", isOn: $groupsEnabled)
                    .tint(.blue)
            } header: {
                HStack {
                    Text("Groups")
                    Button {
                        showPopover3 = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $showPopover3) {
                        Text("Automatically group animals by categories of your choice. To set up the groups, email jared@pawpartner.app. In the future, this will be able to be set up directly in the app.")
                            .padding()
                            .textCase(nil)
                    }
                }
            }
            
            if !viewModel.secondarySortOptions.isEmpty {
                Section {
                    Picker("Secondary Sort", selection: $secondarySortOption) {
                        Text("").tag("")
                        ForEach(viewModel.secondarySortOptions, id: \.self) {
                            Text($0)
                        }
                    }
                } header: {
                    HStack {
                        Text("Secondary Sort")
                        Button {
                            showPopover11 = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                        .popover(isPresented: $showPopover11) {
                            Text("This allows you to search animals by name, notes, breed, etc from the volunteer screen.")
                                .padding()
                                .textCase(nil)
                        }
                    }
                }
            }
            
            
            
        }
    }
}


