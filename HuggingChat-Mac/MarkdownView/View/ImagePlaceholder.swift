import SwiftUI

struct ImagePlaceholder: View {
    var body: some View {
        Image(systemName: "photo")
            .imageScale(.large)
            .foregroundStyle(.secondary)
            .padding(5)
    }
}
