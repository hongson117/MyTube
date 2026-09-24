//
// BackgroundPlayback.js - My Tube Background Audio & Video Engine
//

(function() {
    'use strict';

    if (window.__mytube_background_initialized) return;
    window.__mytube_background_initialized = true;

    // 1. Giả lập trang luôn luôn hiển thị (Ngăn YouTube tự động Pause khi ẩn tab/tắt màn hình)
    try {
        Object.defineProperty(document, 'hidden', {
            get: function() { return false; },
            configurable: true
        });
        Object.defineProperty(document, 'visibilityState', {
            get: function() { return 'visible'; },
            configurable: true
        });
        Object.defineProperty(document, 'webkitVisibilityState', {
            get: function() { return 'visible'; },
            configurable: true
        });
        Object.defineProperty(document, 'hasFocus', {
            value: function() { return true; },
            configurable: true
        });
    } catch (e) {
        console.warn('[MyTube BG] Error overriding visibility:', e);
    }

    // 2. Chặn các sự kiện ẩn trang truyền tới trình phát của YouTube
    const blockEvent = function(e) {
        e.stopImmediatePropagation();
    };

    window.addEventListener('visibilitychange', blockEvent, true);
    document.addEventListener('visibilitychange', blockEvent, true);
    window.addEventListener('webkitvisibilitychange', blockEvent, true);
    document.addEventListener('webkitvisibilitychange', blockEvent, true);
    window.addEventListener('pagehide', blockEvent, true);

    // 3. Theo dõi hành động bấm tạm dừng có chủ đích của người dùng
    let userIntentionalPause = false;
    let userActionTimeout = null;

    function registerUserAction() {
        userIntentionalPause = true;
        if (userActionTimeout) clearTimeout(userActionTimeout);
        userActionTimeout = setTimeout(() => {
            userIntentionalPause = false;
        }, 1200);
    }

    document.addEventListener('click', registerUserAction, true);
    document.addEventListener('touchstart', registerUserAction, true);
    document.addEventListener('keydown', registerUserAction, true);

    // 4. Cấu hình thẻ <video> chạy ngầm mượt mà
    function configureVideoElement(video) {
        if (!video || video.__mytube_bg_configured) return;
        video.__mytube_bg_configured = true;

        // Bật phát ngầm & Picture-in-Picture
        video.setAttribute('playsinline', 'true');
        video.setAttribute('webkit-playsinline', 'true');
        video.setAttribute('x5-playsinline', 'true');
        video.playsInline = true;

        // Bọc hàm pause() của video
        const originalPause = video.pause;
        video.pause = function() {
            // Nếu người dùng thực sự bấm vào nút Pause trên màn hình, cho phép dừng bình thường
            if (userIntentionalPause || video.ended || !video.duration) {
                return originalPause.apply(this, arguments);
            }
            // Nếu là do hệ thống/trình duyệt cố tình pause khi ra ngoài nền, bỏ qua lệnh pause
            console.log('[MyTube BG] Đã chặn lệnh tự động pause ngầm.');
        };

        // Nếu video bị dừng đột ngột ngoài ý muốn khi đang phát (không do người dùng bấm), tự động tiếp tục
        video.addEventListener('pause', function() {
            if (!userIntentionalPause && !video.ended && video.currentTime > 0) {
                setTimeout(() => {
                    if (!userIntentionalPause && video.paused && !video.ended) {
                        video.play().catch(() => {});
                    }
                }, 150);
            }
        });
    }

    // Quan sát DOM để cấu hình ngay khi video xuất hiện
    const videoObserver = new MutationObserver(() => {
        const videos = document.querySelectorAll('video');
        for (let i = 0; i < videos.length; i++) {
            configureVideoElement(videos[i]);
        }
    });

    videoObserver.observe(document.documentElement, {
        childList: true,
        subtree: true
    });

    document.addEventListener('DOMContentLoaded', () => {
        const videos = document.querySelectorAll('video');
        for (let i = 0; i < videos.length; i++) {
            configureVideoElement(videos[i]);
        }
    });

})();
