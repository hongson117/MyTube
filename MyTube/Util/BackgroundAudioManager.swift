//
//  BackgroundAudioManager.swift
//  MyTube
//
//  Quản lý âm thanh phát dưới nền (Background Audio) & Điều khiển Màn hình khóa (Lock Screen Remote)
//

import Foundation
import AVFoundation
import MediaPlayer
import WebKit

class BackgroundAudioManager: NSObject, AVAudioPlayerDelegate {
    static let shared = BackgroundAudioManager()
    
    private var silentPlayer: AVAudioPlayer?
    private var isKeepAliveActive: Bool = false
    weak var activeWebView: WKWebView?
    
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
    }
    
    // MARK: - 1. Cấu hình AVAudioSession Chuyên Nghiệp Cho Phát Dưới Nền
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
            print("[MyTube BG] AVAudioSession activated for background playback successfully.")
        } catch {
            print("[MyTube BG] Failed to configure AVAudioSession: \(error)")
        }
    }
    
    // MARK: - 2. Động Cơ Giữ Nhịp Nền (Silent Audio Engine)
    /// Phát luồng âm thanh im lặng 0% CPU để iOS không bao giờ đóng băng tiến trình WebKit khi khóa màn hình
    func startKeepAlive() {
        guard !isKeepAliveActive else { return }
        
        setupAudioSession()
        
        let silentWAV = generateSilentWAV()
        do {
            silentPlayer = try AVAudioPlayer(data: silentWAV)
            silentPlayer?.delegate = self
            silentPlayer?.numberOfLoops = -1 // Lặp vô hạn
            silentPlayer?.volume = 0.0001    // Hoàn toàn im lặng, không ảnh hưởng âm thanh video
            silentPlayer?.prepareToPlay()
            silentPlayer?.play()
            isKeepAliveActive = true
            print("[MyTube BG] Silent audio keep-alive started.")
        } catch {
            print("[MyTube BG] Could not start silent audio: \(error)")
        }
    }
    
    func stopKeepAlive() {
        silentPlayer?.stop()
        silentPlayer = nil
        isKeepAliveActive = false
    }
    
    // MARK: - 3. Tạo Dữ Liệu Sóng Âm Im Lặng Chuẩn PCM WAV Trực Tiếp Trong RAM
    private func generateSilentWAV() -> Data {
        var data = Data()
        // Header RIFF
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        let sampleRate: UInt32 = 44100
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let blockAlign: UInt16 = numChannels * (bitsPerSample / 8)
        let byteRate: UInt32 = sampleRate * UInt32(blockAlign)
        let dataSize: UInt32 = sampleRate * UInt32(blockAlign) // 1 giây âm thanh
        let chunkSize: UInt32 = 36 + dataSize
        
        withUnsafeBytes(of: chunkSize.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        
        // Chunk fmt
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        let subchunk1Size: UInt32 = 16
        withUnsafeBytes(of: subchunk1Size.littleEndian) { data.append(contentsOf: $0) }
        let audioFormat: UInt16 = 1 // PCM
        withUnsafeBytes(of: audioFormat.littleEndian) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: numChannels.littleEndian) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: sampleRate.littleEndian) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: byteRate.littleEndian) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: blockAlign.littleEndian) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: bitsPerSample.littleEndian) { data.append(contentsOf: $0) }
        
        // Chunk data (chứa byte 0 = im lặng tuyệt đối)
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        withUnsafeBytes(of: dataSize.littleEndian) { data.append(contentsOf: $0) }
        data.append(Data(count: Int(dataSize)))
        
        return data
    }
    
    // MARK: - 4. Điều Khiển Màn Hình Khóa / Tai Nghe / Nút Vô Lăng Xe
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Lệnh Phát
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.executeJS("const v = document.querySelector('video'); if (v) { v.play(); }")
            return .success
        }
        
        // Lệnh Dừng
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.executeJS("const v = document.querySelector('video'); if (v) { v.pause(); }")
            return .success
        }
        
        // Lệnh Đổi Trạng Thái Phát/Dừng
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.executeJS("const v = document.querySelector('video'); if (v) { if (v.paused) { v.play(); } else { v.pause(); } }")
            return .success
        }
        
        // Lệnh Bài Tiếp Theo
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.executeJS("""
            const nextBtn = document.querySelector('.ytp-next-button') || document.querySelector('button[aria-label*=\"tiếp\"]');
            if (nextBtn) { nextBtn.click(); }
            """)
            return .success
        }
        
        // Lệnh Lùi 10 Giây
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [10]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.executeJS("const v = document.querySelector('video'); if (v) { v.currentTime = Math.max(0, v.currentTime - 10); }")
            return .success
        }
        
        // Lệnh Tiến 10 Giây
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [10]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.executeJS("const v = document.querySelector('video'); if (v) { v.currentTime = Math.min(v.duration || 99999, v.currentTime + 10); }")
            return .success
        }
    }
    
    private func executeJS(_ code: String) {
        DispatchQueue.main.async { [weak self] in
            self?.activeWebView?.evaluateJavaScript(code, completionHandler: nil)
        }
    }
    
    // MARK: - 5. Cập Nhật Thông Tin Bài Hát Lên Màn Hình Khóa
    func updateNowPlaying(title: String, channel: String = "YouTube", duration: Double = 0, currentTime: Double = 0) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = channel
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        if duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
