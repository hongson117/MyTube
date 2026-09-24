//
//  ContentView.swift
//  MyTube
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var carPlay = CarPlaySingleton.shared
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var urlString: String = ""
    @State private var searchKeyword: String = ""
    
    func playVideo() {
        hideKeyboard()
        if let videoID = extractYouTubeVideoID(urlString) {
            let targetURL = YT_EMBED + videoID
            carPlay.loadUrl(targetURL)
        } else if !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Treat as query
            carPlay.searchVideo(urlString)
        } else {
            UIApplication.shared.alert(
                title: "Lỗi Đường Dẫn",
                body: "Vui lòng nhập đường link YouTube hợp lệ hoặc dán từ bộ nhớ tạm.",
                window: .main
            )
        }
    }
    
    func searchAction() {
        hideKeyboard()
        let query = searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            carPlay.searchVideo(query)
        }
    }
    
    func pasteFromClipboard() {
        if let clip = UIPasteboard.general.string {
            urlString = clip
            if isYouTubeURL(clip) {
                playVideo()
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Header & 3D Logo Card
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
                                .frame(width: 84, height: 84)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.red, Color.red.opacity(0.3)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: Color.red.opacity(0.35), radius: 12, x: 0, y: 6)
                            
                            Image(systemName: "play.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.red)
                                .offset(x: 2)
                        }
                        
                        Text("MY TUBE")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .tracking(2)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(carPlay.isCPWindowActive ? Color.green : Color.orange)
                                .frame(width: 10, height: 10)
                            Text(carPlay.isCPWindowActive ? "Đang Kết Nối CarPlay (Toàn Màn Hình)" : "Chưa Cắm Vào CarPlay (Chờ Kết Nối)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(20)
                    }
                    .padding(.top, 10)

                    // MARK: - Play URL Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Phát Link YouTube Trên Xe")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.secondary)
                            TextField("Dán link YouTube (youtu.be / watch?v=...)", text: $urlString)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            if !urlString.isEmpty {
                                Button(action: { urlString = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        HStack(spacing: 12) {
                            Button(action: pasteFromClipboard) {
                                HStack {
                                    Image(systemName: "doc.on.clipboard")
                                    Text("Dán Link")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(12)
                            }
                            
                            Button(action: playVideo) {
                                HStack {
                                    Image(systemName: "play.tv.fill")
                                    Text("Phát Trên Màn Hình Xe")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.red, Color(red: 0.8, green: 0.0, blue: 0.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.red.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)

                    // MARK: - Search Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tìm Kiếm Video")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Tìm bài hát, ca sĩ, phim...", text: $searchKeyword, onCommit: searchAction)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            Button(action: searchAction) {
                                Text("Tìm")
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)

                    // MARK: - In-Car Remote Controls
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

                    // MARK: - Features Info Banner
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.red)
                            Text("Đặc Quyền Của My Tube")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Label("100% Chặn Quảng Cáo (No Pre-roll / Mid-roll)", systemImage: "checkmark.seal.fill")
                            Label("Tự động bỏ qua đoạn tài trợ (SponsorBlock)", systemImage: "checkmark.seal.fill")
                            Label("Chạm cảm ứng trực tiếp trên màn hình xe ô tô", systemImage: "checkmark.seal.fill")
                            Label("Bàn phím gõ trực tiếp trên taplo xe", systemImage: "checkmark.seal.fill")
                            Label("Phát âm thanh nền không ngắt quãng qua loa xe", systemImage: "checkmark.seal.fill")
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                if let clip = UIPasteboard.general.string, isYouTubeURL(clip) {
                    urlString = clip
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
