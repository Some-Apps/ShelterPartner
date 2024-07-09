import SwiftUI

struct SettingElement: View {
    let title: String
    let explanation: String
    
    @State private var showPopover = false
    
    var body: some View {
        HStack {
            Button {
                showPopover = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.blue)
            }
            .popover(isPresented: $showPopover) {
                Text(explanation)
                    .padding()
                    .textCase(nil)
                    .lineLimit(nil) // Allows unlimited lines
                    .fixedSize(horizontal: false, vertical: true) // Wrap text to new line
            }
            Text(title)
        }
    }
}
