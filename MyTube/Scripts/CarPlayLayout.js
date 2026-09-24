//
// CarPlayLayout.js - Exclusively for Apple CarPlay In-Car Screen
//

(function() {
    'use strict';

    // 1. Text input detection specifically for CarPlay virtual keyboard
    const isTextInput = el => el && (el.tagName === "TEXTAREA" || (el.tagName === "INPUT" && (el.type === "text" || el.type === "email" || el.type === "search" || el.type === "url" || el.type === "password")));

    window.addEventListener("focus", e => {
        if (isTextInput(e.target)) {
            try { window.webkit.messageHandlers.keyboard.postMessage("show"); } catch(e){}
        }
    }, true);

    window.addEventListener("click", e => {
        if (isTextInput(e.target)) {
            try { window.webkit.messageHandlers.keyboard.postMessage("show"); } catch(e){}
        }
    }, true);

    window.addEventListener("blur", e => {
        if (isTextInput(e.target)) {
            try { window.webkit.messageHandlers.keyboard.postMessage("hide"); } catch(e){}
        }
    }, true);

    // 2. In-Car Dashboard & Fullscreen Cinema Mode Styles
    const style = document.createElement('style');
    style.id = 'mytube-carplay-specific-styles';
    style.textContent = `
        /* Chế độ toàn màn hình khi phát video trên ô tô */
        body.mytube-cinema-mode #player-container-id,
        body.mytube-cinema-mode .player-container,
        body.mytube-cinema-mode ytm-player,
        body.mytube-cinema-mode .html5-video-player,
        body.mytube-cinema-mode video {
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            max-width: 100vw !important;
            max-height: 100vh !important;
            z-index: 999980 !important;
            background: #000 !important;
            object-fit: contain !important;
            margin: 0 !important;
            padding: 0 !important;
        }

        body.mytube-cinema-mode .ytp-chrome-bottom,
        body.mytube-cinema-mode .ytp-chrome-top,
        body.mytube-cinema-mode .ytp-gradient-bottom,
        body.mytube-cinema-mode .ytp-gradient-top,
        body.mytube-cinema-mode .player-controls-container {
            z-index: 999999 !important;
        }

        body.mytube-cinema-mode ytm-item-section-renderer[section-identifier="comment-item-section"],
        body.mytube-cinema-mode ytm-comment-section-renderer,
        body.mytube-cinema-mode ytm-single-column-watch-next-results-renderer,
        body.mytube-cinema-mode ytm-watch-metadata,
        body.mytube-cinema-mode header.mobile-topbar-header {
            display: none !important;
        }

        /* Thanh điều khiển nổi chuyên biệt trên xe ô tô (Floating Car Bar) */
        #mytube-floating-bar {
            position: fixed;
            top: 8px;
            left: 8px;
            z-index: 9999999;
            display: flex;
            align-items: center;
            gap: 6px;
            background: rgba(16, 16, 18, 0.85);
            backdrop-filter: blur(14px);
            -webkit-backdrop-filter: blur(14px);
            padding: 5px 10px;
            border-radius: 20px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.6);
            transition: opacity 0.3s ease, transform 0.3s ease;
        }

        #mytube-floating-bar.autohide {
            opacity: 0.1;
            transform: translateY(-4px);
        }

        #mytube-floating-bar.autohide:hover,
        #mytube-floating-bar.active {
            opacity: 1 !important;
            transform: translateY(0) !important;
        }

        .mytube-fbtn {
            background: rgba(255, 255, 255, 0.15);
            border: none;
            color: #fff;
            font-size: 12px;
            font-weight: 600;
            padding: 5px 10px;
            border-radius: 14px;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            user-select: none;
            -webkit-user-select: none;
        }

        .mytube-fbtn:active {
            background: rgba(255, 0, 0, 0.7);
        }
        
        .mytube-fbtn.active {
            background: #e60000;
        }
    `;
    document.head.appendChild(style);

    // 3. Create & Attach Floating In-Car Control Bar
    let floatingBar = null;
    let autohideTimer = null;
    let isCinemaMode = true;

    function createFloatingBar() {
        if (document.getElementById('mytube-floating-bar')) return;
        floatingBar = document.createElement('div');
        floatingBar.id = 'mytube-floating-bar';

        const backBtn = document.createElement('button');
        backBtn.className = 'mytube-fbtn';
        backBtn.innerHTML = '◀ Quay Lại';
        backBtn.onclick = () => {
            if (window.history.length > 1) {
                window.history.back();
            } else {
                window.location.href = 'https://m.youtube.com/feed/trending';
            }
        };

        const fsBtn = document.createElement('button');
        fsBtn.className = 'mytube-fbtn active';
        fsBtn.id = 'mytube-fs-toggle';
        fsBtn.innerHTML = '⤢ Toàn Màn Hình';
        fsBtn.onclick = () => {
            isCinemaMode = !isCinemaMode;
            updateCinemaState();
        };

        const trendBtn = document.createElement('button');
        trendBtn.className = 'mytube-fbtn';
        trendBtn.innerHTML = '🔥 Thịnh Hành';
        trendBtn.onclick = () => {
            window.location.href = 'https://m.youtube.com/feed/trending';
        };

        const homeBtn = document.createElement('button');
        homeBtn.className = 'mytube-fbtn';
        homeBtn.innerHTML = '🏠 Trang Chủ';
        homeBtn.onclick = () => {
            window.location.href = 'https://m.youtube.com/';
        };

        floatingBar.appendChild(backBtn);
        floatingBar.appendChild(fsBtn);
        floatingBar.appendChild(trendBtn);
        floatingBar.appendChild(homeBtn);
        document.body.appendChild(floatingBar);

        document.addEventListener('touchstart', wakeFloatingBar, { passive: true });
        document.addEventListener('click', wakeFloatingBar, { passive: true });
        wakeFloatingBar();
    }

    function wakeFloatingBar() {
        if (!floatingBar) return;
        floatingBar.classList.remove('autohide');
        floatingBar.classList.add('active');
        clearTimeout(autohideTimer);
        autohideTimer = setTimeout(() => {
            if (isWatchPage()) {
                floatingBar.classList.add('autohide');
                floatingBar.classList.remove('active');
            }
        }, 4000);
    }

    function isWatchPage() {
        return window.location.pathname.startsWith('/watch') || window.location.href.includes('watch?v=') || window.location.pathname.startsWith('/embed/');
    }

    function updateCinemaState() {
        const fsBtn = document.getElementById('mytube-fs-toggle');
        if (isWatchPage() && isCinemaMode) {
            document.body.classList.add('mytube-cinema-mode');
            if (fsBtn) {
                fsBtn.innerHTML = '⤢ Đầy Màn Hình';
                fsBtn.classList.add('active');
            }
        } else {
            document.body.classList.remove('mytube-cinema-mode');
            if (fsBtn) {
                fsBtn.innerHTML = '⤡ Thu Nhỏ';
                fsBtn.classList.remove('active');
            }
        }
    }

    // 4. Auto Cinema Mode & URL change tracking
    let lastUrl = location.href;
    setInterval(() => {
        if (location.href !== lastUrl) {
            lastUrl = location.href;
            if (isWatchPage()) {
                isCinemaMode = true;
            }
            updateCinemaState();
        }
        
        if (isWatchPage() && isCinemaMode && !document.body.classList.contains('mytube-cinema-mode')) {
            updateCinemaState();
        }
    }, 500);

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            createFloatingBar();
            updateCinemaState();
        });
    } else {
        createFloatingBar();
        updateCinemaState();
    }

})();
