//
//  PulsingDot.swift
//  Fleetigo
//
//  Created by Deeptanshu Pal on 05/05/25.
//


//
//  PulsingDot.swift
//  Fleetigo
//
//  Created by user@22 on 05/05/25.
//


import SwiftUI

struct PulsingDot: View {
    @State private var isAnimating = false
    let delay: Double
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .opacity(isAnimating ? 1.0 : 0.3)
            .blur(radius: isAnimating ? 0.0 : 0.5)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct ModernLoadingIndicator: View {
    let message: String
    @Environment(\.colorScheme) var colorScheme
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated loader
            ZStack {
                // Rotating circle with gradient
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.2), .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(Angle(degrees: rotation))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                
                // Dots animation
                HStack(spacing: 8) {
                    PulsingDot(delay: 0.0, color: .blue)
                    PulsingDot(delay: 0.2, color: .blue)
                    PulsingDot(delay: 0.4, color: .blue)
                }
            }
            
            // Message text
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct NeuomorphicLoadingIndicator: View {
    let message: String
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false
    
    var baseColor: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.9)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated circle loader
            ZStack {
                // Shadow circles for depth effect
                Circle()
                    .fill(baseColor)
                    .frame(width: 80, height: 80)
                    .shadow(color: colorScheme == .dark ? .black : .gray.opacity(0.5), radius: 10, x: 5, y: 5)
                    .shadow(color: colorScheme == .dark ? Color(white: 0.3) : .white, radius: 10, x: -5, y: -5)
                
                // Animated progress circle
                Circle()
                    .trim(from: 0, to: isAnimating ? 0.8 : 0.0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            .onAppear {
                isAnimating = true
            }
            
            // Message
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(baseColor)
                .shadow(color: colorScheme == .dark ? .black : .gray.opacity(0.3), radius: 15, x: 10, y: 10)
                .shadow(color: colorScheme == .dark ? Color(white: 0.3) : .white, radius: 15, x: -10, y: -10)
        )
    }
}

struct GlassmorphicLoadingIndicator: View {
    let message: String
    @Environment(\.colorScheme) var colorScheme
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Loading animation with sparkles
            ZStack {
                // Rotating gradient circle
                Circle()
                    .trim(from: 0.2, to: 0.8)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .blue]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(Angle(degrees: animate ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: animate
                    )
                
                // Sparkles
                ForEach(0..<4) { i in
                    Circle()
                        .fill(i % 2 == 0 ? Color.blue : Color.purple)
                        .frame(width: 8, height: 8)
                        .offset(x: animate ? 30 : 0)
                        .rotationEffect(Angle(degrees: Double(i) * 90))
                        .opacity(animate ? 0 : 0.7)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                            value: animate
                        )
                }
            }
            .onAppear {
                animate = true
            }
            
            // Message with animated dots
            HStack(spacing: 0) {
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .opacity(animate ? 1 : 0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: animate
                    )
            }
            .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(.vertical, 25)
        .padding(.horizontal, 35)
        .background(
            // Glassmorphic effect
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? 
                      Color.black.opacity(0.5) : 
                      Color.white.opacity(0.7))
                .background(
                    colorScheme == .dark ?
                    Color.black.opacity(0.1) :
                    Color.white.opacity(0.1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.5),
                                    Color.clear,
                                    Color.white.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                .blur(radius: 0.5)
        )
    }
}