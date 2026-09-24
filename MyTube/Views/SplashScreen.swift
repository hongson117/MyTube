//
//  SplashScreen.swift
//  MyTube
//

import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.15, green: 0.15, blue: 0.18), Color(red: 0.05, green: 0.05, blue: 0.07)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.8), Color.white.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.red.opacity(0.4), radius: 15, x: 0, y: 5)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.red)
                        .offset(x: 2)
                }
                
                Text("MY TUBE")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2)
                
                Text("CarPlay YouTube Experience")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    .scaleEffect(1.2)
                    .padding(.top, 8)
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
