import SwiftUI

struct NoTripView: View {
    @EnvironmentObject var tripManager: TripManager
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#B1CEFF"), location: 0.0),
                    .init(color: Color.white, location: 0.20)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 0) {
                NavigationLink {
                    ProfileView()
                } label: {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                            .padding(.leading, 6)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Hello")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#333333"))
                            Text("User")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#4E8FFF"))
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Image("truck")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .onAppear {
                Task {
                    await profileViewModel.fetchUserProfile()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

