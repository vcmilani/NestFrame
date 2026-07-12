import SwiftUI

struct TitleBar: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "film.stack")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color("Teal"))

            Text("NestFrame")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(Color("TextPrimary"))

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color("Surface"))
        .overlay(alignment: .bottom) {
            Divider().background(Color("Stroke"))
        }
    }
}
