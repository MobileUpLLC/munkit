import SwiftUI

struct ErrorView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 150))
                .opacity(0.2)
            Text("Something went wrong")
                .font(.system(size: 24))
            Text("Please try again")
                .font(.system(size: 17))
            Button(action: onRetry) {
                Text("Try again")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(30)
        }
        .foregroundStyle(.gray)
    }
}

#Preview {
    ErrorView(onRetry: {})
}
