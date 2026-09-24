//
//  SettingsView.swift
//  MyTube
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("AdBlockerOn") private var adBlockerOn: Bool = true
    @AppStorage("SponsorBlockOn") private var sponsorBlockOn: Bool = true
    @AppStorage("AgeRestrictBypassOn") private var ageRestrictBypassOn: Bool = true
    @AppStorage("Zoom") private var zoom: Int = 80
    @AppStorage("ScreenPersistenceOn") private var screenPersistenceOn: Bool = true
    @AppStorage("LockScreenDimmingOn") private var lockScreenDimmingOn: Bool = true
    
    var body: some View {
        Form {
            Section(header: Text("Tính Năng TizenTube & AdBlock")) {
                Toggle(isOn: $adBlockerOn) {
                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Chặn Quảng Cáo (100% AdBlock)")
                                .fontWeight(.medium)
                            Text("Tự động bỏ qua và chặn video ads, banner")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Toggle(isOn: $sponsorBlockOn) {
                    HStack {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SponsorBlock (Bỏ đoạn tài trợ)")
                                .fontWeight(.medium)
                            Text("Bỏ qua intro, outro, đoạn quảng cáo tài trợ")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Toggle(isOn: $ageRestrictBypassOn) {
                    HStack {
                        Image(systemName: "lock.open.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Vượt Giới Hạn Độ Tuổi")
                                .fontWeight(.medium)
                            Text("Xem được video giới hạn 18+ không cần đăng nhập")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Section(header: Text("Tỉ Lệ Màn Hình Màn Hình Ô Tô (CarPlay)")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Mức Thu Phóng (Zoom):")
                        Spacer()
                        Text("\(zoom)%")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    Slider(value: Binding(
                        get: { Double(zoom) },
                        set: { zoom = Int($0) }
                    ), in: 60...120, step: 5)
                    Text("Khuyến nghị: 80% cho màn hình 7 - 10 inch, 90% cho màn hình 12+ inch.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Tối Ưu Pin & Chạy Nền")) {
                Toggle(isOn: $screenPersistenceOn) {
                    HStack {
                        Image(systemName: "power")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Giữ Màn Hình Không Tắt (Persistence)")
                                .fontWeight(.medium)
                            Text("Giữ luồng phát liên tục ngay cả khi khóa phím")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Toggle(isOn: $lockScreenDimmingOn) {
                    HStack {
                        Image(systemName: "sun.min.fill")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tự Động Giảm Sáng Khi Khóa")
                                .fontWeight(.medium)
                            Text("Tiết kiệm pin iPhone khi xem trên màn hình xe")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Section(footer: Text("Khởi động lại app sau khi thay đổi để áp dụng ngay.")) {
                Button(action: {
                    exitGracefully()
                }) {
                    HStack {
                        Spacer()
                        Text("Lưu & Khởi Động Lại")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Cài Đặt My Tube")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
