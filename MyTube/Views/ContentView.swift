//
//  ContentView.swift
//  MyTube
//

import SwiftUI
import WebKit

struct ContentView: View {
    @ObservedObject private var carPlay = CarPlaySingleton.shared
    @ObservedObject private var webManager = MyTubeWebManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var selectedTab: Int = 0
    @State private var webURL: String = "https://m.youtube.com/"
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var isLoading: Bool = false
    
    @State private var manualURL: String = ""
    @State private var searchKeyword: String = ""
    
    func playCurrentVideoOnCar() {
        if let videoID = extractYouTubeVideoID(webURL) {
            let target = YT_EMBED + videoID
            carPlay.loadUrl(target)
        } else if isYouTubeURL(manualURL) {
            if let videoID = extractYouTubeVideoID(manualURL) {
                let target = YT_EMBED + videoID
                carPlay.loadUrl(target)
            }
        } else {
            UIApplication.shared.alert(
                title: "Chưa Chọn Video",
                body: "Hãy chọn một video trên màn hình YouTube hoặc dán link video để phát lên màn hình xe ô tô.",
                window: .main
            )
        }
    }
    
    func pasteAndPlay() {
        if let clip = UIPasteboard.general.string {
            manualURL = clip
            if let videoID = extractYouTubeVideoID(clip) {
                let target = YT_EMBED + videoID
                carPlay.loadUrl(target)
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // MARK: - TAB 1: YOUTUBE ĐẦY ĐỦ CÓ ĐĂNG NHẬP & ĐỒNG BỘ
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack(spacing: 12) {
                    Button(action: {
                        // Navigate back inside webview
                        webURL = "javascript:window.history.back();"
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Circle())
                    
                    Button(action: {
                        webURL = "https://m.youtube.com/"
                    }) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .padding(8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Circle())
                    
                    // Nút Kênh Đăng Ký
                    Button(action: {
                        webURL = "https://m.youtube.com/feed/subscriptions"
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.rectangle.on.rectangle.fill")
                            Text("Đăng Ký")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    
                    // Nút Lịch Sử Xem
                    Button(action: {
                        webURL = "https://m.youtube.com/feed/history"
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Lịch Sử")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    
                    Spacer()
                    
                    // Nút Phát Lên Xe Ô Tô
                    Button(action: playCurrentVideoOnCar) {
                        HStack(spacing: 4) {
                            Image(systemName: "car.fill")
                            Text("Lên Xe")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(16)
                        .shadow(color: Color.red.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                
                // Account Sync Banner
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(webManager.isLoggedIn ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(webManager.isLoggedIn ? "Đã Đăng Nhập Google (Đang đồng bộ với CarPlay)" : "Chưa Đăng Nhập. Bấm biểu tượng góc phải để đăng nhập")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if !webManager.isLoggedIn {
                        Button(action: {
                            webURL = "https://accounts.google.com/ServiceLogin?service=youtube&continue=https://m.youtube.com/"
                        }) {
                            Text("Đăng Nhập")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(UIColor.secondarySystemBackground).opacity(0.6))
                
                // Main Embedded YouTube WebView
                PhoneWebViewRepresentable(
                    currentURL: $webURL,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    isLoading: $isLoading,
                    onNavigation: { newURL in
                        // If it's a watch URL, update current state
                        webManager.checkLoginStatus()
                    }
                )
            }
            .tabItem {
                Label("YouTube", systemImage: "play.tv.fill")
            }
            .tag(0)
            
            // MARK: - TAB 2: ĐIỀU KHIỂN CARPLAY & NHẬP LINK
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header & Status
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.18, green: 0.18, blue: 0.22), Color(red: 0.08, green: 0.08, blue: 0.10)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(Color.red, lineWidth: 2)
                                    )
                                
                                Image(systemName: "play.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.red)
                                    .offset(x: 2)
                            }
                            
                            Text("MY TUBE CARPLAY")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .tracking(1.5)
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(carPlay.isCPWindowActive ? Color.green : Color.orange)
                                    .frame(width: 10, height: 10)
                                Text(carPlay.isCPWindowActive ? "Đang Kết Nối Màn Hình Ô Tô (Full Video)" : "Chưa Cắm Vào CarPlay (Chờ Kết Nối)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(20)
                        }
                        .padding(.top, 10)

                        // Sync Notice
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Đồng Bộ Tài Khoản Tự Động")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text(webManager.isLoggedIn ? "Tài khoản của bạn đã được kết nối và đồng bộ hoàn toàn với màn hình xe hơi." : "Đăng nhập một lần trên tab YouTube để lịch sử, kênh đăng ký tự động hiện lên màn hình xe.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(14)
                        .padding(.horizontal)

                        // Manual Link & Search
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Phát Link Thủ Công")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.secondary)
                                TextField("Dán link YouTube bất kỳ...", text: $manualURL)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                
                                if !manualURL.isEmpty {
                                    Button(action: { manualURL = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            
                            HStack(spacing: 12) {
                                Button(action: pasteAndPlay) {
                                    HStack {
                                        Image(systemName: "doc.on.clipboard")
                                        Text("Dán & Phát")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    if !manualURL.isEmpty {
                                        carPlay.loadUrl(manualURL)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "play.tv.fill")
                                        Text("Phát Lên Xe")
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)

                        // Car In-Screen Remote
                        if carPlay.isCPWindowActive {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Điều Khiển Màn Hình Ô Tô")
                                    .font(.headline)
                                
                                HStack(spacing: 12) {
                                    Button(action: { carPlay.goBack() }) {
                                        VStack(spacing: 6) {
                                            Image(systemName: "chevron.left")
                                                .font(.title2)
                                            Text("Quay Lại")
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                    
                                    Button(action: { carPlay.goHome() }) {
                                        VStack(spacing: 6) {
                                            Image(systemName: "house.fill")
                                                .font(.title2)
                                            Text("Trang Chủ")
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                    
                                    Button(action: { carPlay.toggleKeyboard() }) {
                                        VStack(spacing: 6) {
                                            Image(systemName: "keyboard")
                                                .font(.title2)
                                            Text("Bàn Phím Xe")
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                }
                .navigationTitle("CarPlay Hub")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("CarPlay Hub", systemImage: "car.2.fill")
            }
            .tag(1)

            // MARK: - TAB 3: CÀI ĐẶT
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Cài Đặt", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                webManager.checkLoginStatus()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
