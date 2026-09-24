//
// CustomLayout.js - My Tube YouTube Optimization & Auto-Trending Engine
//

(function() {
    'use strict';

    // 1. Inject Style for Clean Mobile YouTube UI
    const style = document.createElement('style');
    style.id = 'mytube-core-styles';
    style.textContent = `
        /* Ẩn các banner cài app và quảng cáo ứng dụng của YouTube */
        .open-app-button,
        ytm-mealbar-promo-renderer,
        .yt-spec-button-shape-next--call-to-action {
            display: none !important;
        }

        /* Nút đăng nhập nổi bật, trang nhã */
        .mobile-topbar-header-sign-in-button,
        a[href*="accounts.google.com"],
        a[href*="/signin"] {
            display: inline-flex !important;
            align-items: center !important;
            background: #cc0000 !important;
            color: #ffffff !important;
            border-radius: 18px !important;
            padding: 4px 12px !important;
            font-size: 13px !important;
            font-weight: 600 !important;
        }

        /* Tối ưu hóa kích thước chữ và khoảng cách video */
        ytm-media-item, ytm-compact-video-renderer, ytm-video-with-context-renderer {
            margin-bottom: 12px !important;
        }

        .compact-media-item-headline, .media-item-headline {
            font-size: 15px !important;
            line-height: 1.35 !important;
            font-weight: 600 !important;
            color: #fff !important;
        }

        .compact-media-item-byline, .media-item-byline {
            font-size: 12px !important;
            color: #aaa !important;
        }

        /* Đảm bảo thanh tìm kiếm luôn sẵn sàng nhận cảm ứng và hiển thị bàn phím */
        input[type="search"],
        input[type="text"],
        .searchbox-input {
            -webkit-user-select: text !important;
            user-select: text !important;
            font-size: 16px !important; /* Tránh iOS tự động zoom khi focus */
        }
    `;
    document.head.appendChild(style);

    // 2. Tự Động Chuyển Sang Trending (Thịnh Hành) Nếu Trang Chủ Trống
    function checkAndRedirectEmptyHome() {
        const path = window.location.pathname;
        if (path === '/' || path === '') {
            const bodyText = (document.body && document.body.innerText) ? document.body.innerText : '';
            const isEmptyPrompt = bodyText.includes('Thử tìm kiếm để bắt đầu') || 
                                  bodyText.includes('Try searching to get started') ||
                                  bodyText.includes('Hãy bắt đầu xem video');
            
            if (isEmptyPrompt) {
                console.log('[MyTube] Phát hiện trang chủ trống (chưa có lịch sử), tự động chuyển sang Trending...');
                window.location.replace('https://m.youtube.com/feed/trending');
                return;
            }

            // Kiểm tra xem sau khi tải có video nào không
            setTimeout(() => {
                if (window.location.pathname === '/' || window.location.pathname === '') {
                    const videoItems = document.querySelectorAll('ytm-media-item, ytm-video-with-context-renderer, ytm-compact-video-renderer, ytm-rich-item-renderer');
                    const text = (document.body && document.body.innerText) ? document.body.innerText : '';
                    if (videoItems.length === 0 && (text.includes('Thử tìm kiếm') || text.includes('Try searching') || text.includes('bắt đầu xem video'))) {
                        console.log('[MyTube] Xác nhận trang chủ trống, nạp ngay Video Thịnh Hành...');
                        window.location.replace('https://m.youtube.com/feed/trending');
                    }
                }
            }, 800);
        }
    }

    // 3. Quan sát tải trang để tự động phát hiện trang chủ trống
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', checkAndRedirectEmptyHome);
    } else {
        checkAndRedirectEmptyHome();
    }

    // Theo dõi chuyển trang Single Page App
    let lastUrl = location.href;
    setInterval(() => {
        if (location.href !== lastUrl) {
            lastUrl = location.href;
            checkAndRedirectEmptyHome();
        }
    }, 600);

})();
