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
    @State private var webURL: String = MyTubeWebManager.shared.initialHomeURL
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var isLoading: Bool = false
    
    @State private var searchText: String = ""
    @State private var manualURL: String = ""
    
    func performSearch() {
        hideKeyboard()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        if let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            webURL = "https://m.youtube.com/results?search_query=\(encoded)"
        }
    }
    
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
                body: "Hãy chạm mở một video trên màn hình hoặc tìm kiếm bài hát rồi bấm 'Lên Xe'.",
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
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // MARK: - TAB 1: YOUTUBE ĐẦY ĐỦ CÓ ĐĂNG NHẬP, TÌM KIẾM & THỊNH HÀNH
            VStack(spacing: 0) {
                
                // 1. Native Search & Cast Bar (Hỗ trợ bàn phím iOS gõ trực tiếp)
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                        
                        TextField("Tìm kiếm bài hát, video trên YouTube...", text: $searchText, onCommit: performSearch)
                            .font(.system(size: 14))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Nút Lên Xe (CarPlay)
                    Button(action: playCurrentVideoOnCar) {
                        HStack(spacing: 4) {
                            Image(systemName: "car.fill")
                            Text("Lên Xe")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color(red: 0.85, green: 0.0, blue: 0.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.red.opacity(0.35), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(Color(UIColor.systemBackground))
                
                // 2. Category Quick Filters (Thịnh hành, Âm nhạc, Đăng ký, Lịch sử, Đăng nhập)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: {
                            webURL = "https://m.youtube.com/results?search_query=th%E1%BB%8Bnh+h%C3%A0nh"
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("Thịnh Hành")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(14)
                        }
                        
                        Button(action: {
                            webURL = "https://m.youtube.com/results?search_query=nhac+tre+remix"
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "music.note")
                                    .foregroundColor(.pink)
                                Text("Âm Nhạc")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(14)
                        }
                        
                        Button(action: {
                            webURL = "https://m.youtube.com/feed/subscriptions"
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.rectangle.on.rectangle.fill")
                                    .foregroundColor(.red)
                                Text("Kênh Đăng Ký")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(14)
                        }
                        
                        Button(action: {
                            webURL = "https://m.youtube.com/feed/history"
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.blue)
                                Text("Lịch Sử Xem")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(14)
                        }
                        
                        Button(action: {
                            webURL = "https://accounts.google.com/ServiceLogin?service=youtube&continue=https://m.youtube.com/"
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: webManager.isLoggedIn ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                                    .foregroundColor(webManager.isLoggedIn ? .green : .primary)
                                Text(webManager.isLoggedIn ? "Tài Khoản" : "Đăng Nhập")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(webManager.isLoggedIn ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }
                .background(Color(UIColor.systemBackground))
                
                Divider()
                
                // 3. Embedded YouTube WebView (Chia sẻ cookie trực tiếp với CarPlay)
                PhoneWebViewRepresentable(
                    currentURL: $webURL,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    isLoading: $isLoading,
                    onNavigation: { url in
                        if url.contains("accounts.google") || url.contains("signin") {
                            webManager.checkLoginStatus()
                        }
                    }
                )
            }
            .tabItem {
                Label("YouTube", systemImage: "play.tv.fill")
            }
            .tag(0)
            
            // MARK: - TAB 2: ĐIỀU KHIỂN CARPLAY
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        
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

                        HStack(spacing: 12) {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Đồng Bộ Tài Khoản & Thịnh Hành")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text(webManager.isLoggedIn ? "Tài khoản của bạn đã được kết nối và đồng bộ hoàn toàn với màn hình xe hơi." : "Chưa có lịch sử? My Tube sẽ tự động nạp Video Thịnh Hành (Trending) để bạn xem ngay mà không bị trống màn hình.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(14)
                        .padding(.horizontal)

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
            } else if phase == .background {
                BackgroundAudioManager.shared.startKeepAlive()
                BackgroundAudioManager.shared.activeWebView?.evaluateJavaScript("""
                const v = document.querySelector('video');
                if (v && !v.ended && v.currentTime > 0) {
                    v.play();
                }
                """, completionHandler: nil)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
