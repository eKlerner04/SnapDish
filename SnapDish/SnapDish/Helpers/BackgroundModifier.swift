import SwiftUI

// MARK: - Global Background für SnapDish
struct SnapDishBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Hintergrundbild
                    Image("backGroundSnapDish")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    // Farbverlauf darüber (leicht)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.97, blue: 0.87).opacity(0.3),
                            Color(red: 0.94, green: 0.93, blue: 1.0).opacity(0.25)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            )
    }
}

// MARK: - View Extension
extension View {
    func snapDishBackground() -> some View {
        modifier(SnapDishBackgroundModifier())
    }
}

// MARK: - SnapDish Farben
extension Color {
    static let snapDishOrange = Color(red: 1.0, green: 0.5, blue: 0.2)
    static let snapDishBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let snapDishGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let snapDishPeach = Color(red: 1.0, green: 0.97, blue: 0.87)
}

