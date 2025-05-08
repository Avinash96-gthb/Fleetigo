//
//  SplashScreenView.swift
//  Fleetigo
//
//  Created by Deeptanshu Pal on 28/04/25.
//

import SwiftUI
import AVKit // For VideoPlayer and AVPlayer

struct SplashScreenView: View {
    // State to toggle between splash screen and main app
    @State private var isSplashActive = true
    
    // Initialize AVPlayer with the video from the bundle, with error handling
    let player: AVPlayer = {
        if let url = Bundle.main.url(forResource: "Animation", withExtension: "mp4") {
            return AVPlayer(url: url)
        } else {
            print("Error: 'Animation.mp4' not found in bundle!")
            return AVPlayer() // Fallback to an empty player
        }
    }()
    
    var body: some View {
        if isSplashActive {
            // Use ZStack to center the video and fill the screen
            ZStack {
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fill) // Fill the frame, cropping if necessary
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .ignoresSafeArea(.all) // Cover the entire screen
                    .allowsHitTesting(false) // Disable user interaction
            }
            .onAppear {
                // Start playing the video when the view appears
                player.play()
            }
            .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
                // Check if the finished item is our player's current item
                if let item = notification.object as? AVPlayerItem, item == player.currentItem {
                    withAnimation {
                        isSplashActive = false // Switch to main app with animation
                    }
                }
            }
        } else {
            // Show the main app's root view after the video ends
            AppRootView()
        }
    }
}

#Preview {
    SplashScreenView()
}
