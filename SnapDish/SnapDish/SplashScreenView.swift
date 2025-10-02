import SwiftUI
import AVKit

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var fadeOutOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // ContentView mit Fade-In Effekt
            if isActive {
                ContentView()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.8), value: isActive)
            }
            
            // SplashScreen mit Fade-Out Effekt
            if !isActive {
                ZStack {
                    // Video-Hintergrund (mit Fallback)
                    VideoBackgroundView()
                        .ignoresSafeArea()
                    
                    // Overlay für bessere Lesbarkeit
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        // Logo/App Icon
                        Image("ChatGPT Image 20. Sept. 2025, 16_28_51")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                        
                        // App Name
                        VStack(spacing: 8) {
                            Text("SnapDish")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.snapDishOrange,
                                            Color(red: 1.0, green: 0.3, blue: 0.4)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(logoOpacity)
                            
                            Text("Gemeinsam kochen, gemeinsam genießen 🦒")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .opacity(logoOpacity)
                        }
                    }
                    
                    // Loading Indicator
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                            .opacity(logoOpacity)
                            .padding(.bottom, 50)
                    }
                }
                .opacity(fadeOutOpacity)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.8), value: fadeOutOpacity)
                .onAppear {
                    // Animation starten
                    withAnimation(.easeOut(duration: 1.0)) {
                        logoScale = 1.0
                        logoOpacity = 1.0
                    }
                    
                    // Nach 2.5 Sekunden zur Hauptansicht wechseln mit Fade-Effekt
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        // Erst SplashScreen ausblenden
                        withAnimation(.easeInOut(duration: 0.6)) {
                            fadeOutOpacity = 0.0
                        }
                        
                        // Dann ContentView einblenden
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                isActive = true
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Video Background Component
struct VideoBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        
        // Video Player erstellen
        let player = AVPlayer()
        let playerLayer = AVPlayerLayer(player: player)
        
        // Video laden
        if let videoURL = Bundle.main.url(forResource: "videoSplashScreen", withExtension: "mov") {
            let playerItem = AVPlayerItem(url: videoURL)
            player.replaceCurrentItem(with: playerItem)
            
            // Video-Einstellungen
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.frame = view.bounds
            
            view.layer.addSublayer(playerLayer)
            
            // Video-Loop
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }
            
            // Abspielen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                player.play()
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
                playerLayer.frame = uiView.bounds
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
