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

    // 2. Trang Trí Khối Trang Chủ Trống (Không Reload Gây Nhấp Nháy)
    function enhanceEmptyState() {
        const path = window.location.pathname;
        if (path === '/' || path === '') {
            const emptyContainer = document.querySelector('ytm-browse-response[rendered-from-cache], ytm-section-list-renderer');
            if (emptyContainer && !document.getElementById('mytube-empty-helper')) {
                const bodyText = (document.body && document.body.innerText) ? document.body.innerText : '';
                if (bodyText.includes('Thử tìm kiếm để bắt đầu') || bodyText.includes('Try searching to get started') || bodyText.includes('bắt đầu xem video')) {
                    const helper = document.createElement('div');
                    helper.id = 'mytube-empty-helper';
                    helper.style.cssText = 'margin: 20px auto; max-width: 340px; text-align: center; padding: 16px; background: #1a1a1a; border-radius: 16px; border: 1px solid #333;';
                    helper.innerHTML = `
                        <p style="color: #eee; font-size: 14px; margin-bottom: 12px; font-weight: 500;">
                            💡 Chưa có lịch sử xem? Chọn ngay nội dung bạn thích:
                        </p>
                        <div style="display: flex; gap: 8px; justify-content: center; flex-wrap: wrap;">
                            <a href="/results?search_query=th%E1%BB%8Bnh+h%C3%A0nh" style="display: inline-block; background: #e50914; color: #fff; text-decoration: none; padding: 8px 16px; border-radius: 20px; font-size: 13px; font-weight: bold;">
                                🔥 Thịnh Hành
                            </a>
                            <a href="/results?search_query=nhac+tre+remix" style="display: inline-block; background: #272727; color: #fff; text-decoration: none; padding: 8px 16px; border-radius: 20px; font-size: 13px; font-weight: 500; border: 1px solid #444;">
                                🎵 Nhạc Trẻ
                            </a>
                        </div>
                    `;
                    const promptBox = document.querySelector('.yt-spec-button-shape-next, ytm-message-renderer');
                    if (promptBox && promptBox.parentNode) {
                        promptBox.parentNode.insertBefore(helper, promptBox.nextSibling);
                    }
                }
            }
        }
    }

    // 3. Quan sát DOM an toàn (không reload lặp lại)
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', enhanceEmptyState);
    } else {
        enhanceEmptyState();
    }

    setTimeout(enhanceEmptyState, 1000);

})();
