<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ClearSCM Reachout Control Panel</title>
    <link rel="icon" href="/Icons/Home.ico" type="image/x-icon">
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;700&family=Outfit:wght@500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-emerald: #10b981;
            --primary-light: #34d399;
            --primary-dark: #059669;
            --primary-forest: #047857;
            --accent-mint: #6ee7b7;
            --bg-deep: #050f0c;
            --bg-surface: #0a1814;
            --bg-card: rgba(16, 185, 129, 0.035);
            --bg-card-hover: rgba(16, 185, 129, 0.07);
            --border-glass: rgba(52, 211, 153, 0.16);
            --border-glow: rgba(52, 211, 153, 0.4);
            --text-main: #f0fdf4;
            --text-secondary: #94a3b8;
            --text-muted: #64748b;
            --status-active: #10b981;
            --status-paused: #f59e0b;
            --status-booked: #06b6d4;
            --status-completed: #3b82f6;
            --status-declined: #ef4444;
            --font-heading: 'Outfit', sans-serif;
            --font-body: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            --font-mono: 'JetBrains Mono', monospace;
            --radius-sm: 8px;
            --radius-md: 12px;
            --radius-lg: 18px;
            --shadow-glow: 0 0 25px rgba(16, 185, 129, 0.15);
            --shadow-card: 0 10px 30px rgba(0, 0, 0, 0.45);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            background-color: var(--bg-deep);
            background-image: 
                radial-gradient(circle at 15% 15%, rgba(16, 185, 129, 0.08) 0%, transparent 40%),
                radial-gradient(circle at 85% 85%, rgba(5, 150, 105, 0.06) 0%, transparent 40%),
                linear-gradient(180deg, #06130f 0%, #030806 100%);
            background-attachment: fixed;
            color: var(--text-main);
            font-family: var(--font-body);
            min-height: 100vh;
            line-height: 1.5;
            -webkit-font-smoothing: antialiased;
        }

        /* Container */
        .app-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 2rem 1.5rem 4rem 1.5rem;
        }

        /* Header Navigation */
        .nav-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 1.25rem;
            padding: 1.25rem 1.75rem;
            background: var(--bg-card);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-lg);
            margin-bottom: 2rem;
            box-shadow: var(--shadow-card);
        }

        .brand-section {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .brand-logo {
            width: 44px;
            height: 44px;
            border-radius: 12px;
            background: linear-gradient(135deg, var(--primary-light), var(--primary-forest));
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 4px 15px rgba(16, 185, 129, 0.3);
            font-size: 1.35rem;
        }

        .brand-text h1 {
            font-family: var(--font-heading);
            font-size: 1.5rem;
            font-weight: 700;
            letter-spacing: -0.02em;
            background: linear-gradient(90deg, #ffffff, var(--accent-mint));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            display: flex;
            align-items: center;
            gap: 0.6rem;
        }

        .brand-text .subline {
            font-size: 0.825rem;
            color: var(--text-secondary);
            font-weight: 400;
        }

        .env-badge {
            font-size: 0.75rem;
            padding: 0.2rem 0.6rem;
            border-radius: 20px;
            font-family: var(--font-mono);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .env-badge.production {
            background: rgba(16, 185, 129, 0.15);
            color: var(--primary-light);
            border: 1px solid rgba(16, 185, 129, 0.4);
        }
        .env-badge.staging {
            background: rgba(245, 158, 11, 0.15);
            color: #fbbf24;
            border: 1px solid rgba(245, 158, 11, 0.4);
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            flex-wrap: wrap;
        }

        /* Buttons */
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.65rem 1.15rem;
            font-family: var(--font-body);
            font-size: 0.875rem;
            font-weight: 600;
            border-radius: var(--radius-md);
            cursor: pointer;
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
            text-decoration: none;
            border: none;
            outline: none;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--primary-light) 0%, var(--primary-dark) 100%);
            color: #03140e;
            box-shadow: 0 4px 14px rgba(16, 185, 129, 0.25);
        }
        .btn-primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 20px rgba(16, 185, 129, 0.4);
            filter: brightness(1.08);
        }

        .btn-secondary {
            background: rgba(16, 185, 129, 0.08);
            color: var(--text-main);
            border: 1px solid var(--border-glass);
        }
        .btn-secondary:hover {
            background: rgba(16, 185, 129, 0.16);
            border-color: var(--border-glow);
            transform: translateY(-1px);
        }

        .btn-danger {
            background: rgba(239, 68, 68, 0.12);
            color: #fca5a5;
            border: 1px solid rgba(239, 68, 68, 0.25);
        }
        .btn-danger:hover {
            background: rgba(239, 68, 68, 0.22);
            border-color: #ef4444;
        }

        .btn-icon {
            padding: 0.5rem;
            border-radius: var(--radius-sm);
        }

        /* Stats Grid */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 1.25rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-md);
            padding: 1.25rem;
            display: flex;
            align-items: center;
            gap: 1.15rem;
            transition: all 0.25s ease;
            box-shadow: var(--shadow-card);
        }
        .stat-card:hover {
            transform: translateY(-2px);
            border-color: var(--border-glow);
            box-shadow: var(--shadow-glow);
        }

        .stat-icon {
            width: 50px;
            height: 50px;
            border-radius: 12px;
            background: rgba(16, 185, 129, 0.1);
            border: 1px solid rgba(16, 185, 129, 0.2);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.4rem;
            color: var(--primary-light);
            flex-shrink: 0;
        }

        .stat-details .stat-val {
            font-family: var(--font-heading);
            font-size: 1.75rem;
            font-weight: 700;
            line-height: 1.1;
            color: #ffffff;
        }
        .stat-details .stat-label {
            font-size: 0.8rem;
            color: var(--text-secondary);
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-top: 0.2rem;
        }

        /* Filter & Control Bar */
        .controls-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 1rem;
            margin-bottom: 1.25rem;
        }

        .search-box {
            position: relative;
            flex: 1;
            max-width: 380px;
            min-width: 240px;
        }

        .search-box input {
            width: 100%;
            padding: 0.7rem 1rem 0.7rem 2.5rem;
            background: rgba(10, 24, 20, 0.6);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-md);
            color: var(--text-main);
            font-size: 0.9rem;
            outline: none;
            transition: all 0.2s;
        }
        .search-box input:focus {
            border-color: var(--primary-light);
            box-shadow: 0 0 15px rgba(16, 185, 129, 0.2);
            background: rgba(10, 24, 20, 0.9);
        }
        .search-box .icon {
            position: absolute;
            left: 0.85rem;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-muted);
            pointer-events: none;
        }

        .filter-tabs {
            display: flex;
            background: rgba(10, 24, 20, 0.5);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-md);
            padding: 0.25rem;
            gap: 0.25rem;
        }

        .filter-tab {
            padding: 0.45rem 0.95rem;
            border-radius: var(--radius-sm);
            background: transparent;
            color: var(--text-secondary);
            font-size: 0.85rem;
            font-weight: 600;
            border: none;
            cursor: pointer;
            transition: all 0.2s;
        }
        .filter-tab.active {
            background: var(--primary-forest);
            color: #ffffff;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
        }

        /* Contacts Table View */
        .table-container {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-lg);
            overflow: hidden;
            box-shadow: var(--shadow-card);
        }

        table.contacts-table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
            font-size: 0.9rem;
        }

        table.contacts-table th {
            background: rgba(6, 19, 15, 0.8);
            padding: 1rem 1.25rem;
            font-family: var(--font-heading);
            font-size: 0.8rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--text-secondary);
            border-bottom: 1px solid var(--border-glass);
        }

        table.contacts-table td {
            padding: 1.1rem 1.25rem;
            border-bottom: 1px solid rgba(52, 211, 153, 0.07);
            vertical-align: middle;
        }

        table.contacts-table tr {
            transition: background 0.15s ease;
        }
        table.contacts-table tr:hover {
            background: var(--bg-card-hover);
        }

        .venue-cell {
            display: flex;
            flex-direction: column;
            gap: 0.2rem;
        }
        .venue-title {
            font-weight: 600;
            color: #ffffff;
            font-size: 1rem;
            display: flex;
            align-items: center;
            gap: 0.4rem;
        }
        .venue-id {
            font-family: var(--font-mono);
            font-size: 0.75rem;
            color: var(--text-muted);
        }
        .venue-web {
            font-size: 0.78rem;
            color: var(--primary-light);
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 0.25rem;
        }
        .venue-web:hover {
            text-decoration: underline;
        }

        .contact-cell {
            display: flex;
            flex-direction: column;
            gap: 0.2rem;
        }
        .contact-name {
            font-weight: 500;
            color: var(--text-main);
        }
        .contact-meta {
            font-size: 0.8rem;
            color: var(--text-secondary);
        }
        .contact-meta a {
            color: inherit;
            text-decoration: none;
        }
        .contact-meta a:hover {
            color: var(--primary-light);
        }

        /* Status & Schedule Badges */
        .badge {
            display: inline-flex;
            align-items: center;
            gap: 0.35rem;
            padding: 0.3rem 0.65rem;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
            letter-spacing: 0.02em;
        }

        .badge-active {
            background: rgba(16, 185, 129, 0.12);
            color: var(--primary-light);
            border: 1px solid rgba(16, 185, 129, 0.35);
        }
        .badge-paused {
            background: rgba(245, 158, 11, 0.12);
            color: #fbbf24;
            border: 1px solid rgba(245, 158, 11, 0.35);
        }
        .badge-booked, .badge-completed {
            background: rgba(6, 182, 212, 0.12);
            color: #38bdf8;
            border: 1px solid rgba(6, 182, 212, 0.35);
        }
        .badge-declined {
            background: rgba(239, 68, 68, 0.12);
            color: #f87171;
            border: 1px solid rgba(239, 68, 68, 0.35);
        }

        .badge-pulse {
            position: relative;
        }
        .badge-pulse::before {
            content: '';
            display: inline-block;
            width: 7px;
            height: 7px;
            border-radius: 50%;
            background: var(--primary-light);
            box-shadow: 0 0 8px var(--primary-light);
            animation: pulse-dot 1.8s infinite;
        }

        @keyframes pulse-dot {
            0% { transform: scale(0.9); opacity: 0.8; }
            50% { transform: scale(1.3); opacity: 1; }
            100% { transform: scale(0.9); opacity: 0.8; }
        }

        .schedule-box {
            display: flex;
            flex-direction: column;
            gap: 0.2rem;
        }
        .schedule-date {
            font-weight: 600;
            color: #ffffff;
            font-size: 0.85rem;
            display: flex;
            align-items: center;
            gap: 0.35rem;
        }
        .schedule-relative {
            font-size: 0.75rem;
            color: var(--text-secondary);
        }

        .attempts-pill {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 28px;
            height: 28px;
            border-radius: 50%;
            background: rgba(16, 185, 129, 0.08);
            border: 1px solid var(--border-glass);
            font-family: var(--font-mono);
            font-weight: 700;
            font-size: 0.825rem;
            color: var(--primary-light);
        }

        /* Action Buttons */
        .actions-group {
            display: flex;
            align-items: center;
            gap: 0.4rem;
        }

        .action-btn {
            background: rgba(16, 185, 129, 0.08);
            border: 1px solid var(--border-glass);
            color: var(--text-main);
            width: 32px;
            height: 32px;
            border-radius: var(--radius-sm);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s;
            font-size: 0.9rem;
        }
        .action-btn:hover {
            background: rgba(16, 185, 129, 0.22);
            border-color: var(--border-glow);
            transform: scale(1.06);
            color: #ffffff;
        }
        .action-btn.delete-btn:hover {
            background: rgba(239, 68, 68, 0.2);
            border-color: #ef4444;
            color: #f87171;
        }

        /* Modals */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.75);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.2s ease;
            padding: 1.5rem;
        }
        .modal-overlay.active {
            opacity: 1;
            pointer-events: auto;
        }

        .modal-card {
            background: #091713;
            border: 1px solid var(--border-glow);
            border-radius: var(--radius-lg);
            width: 100%;
            max-width: 620px;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 25px 60px rgba(0, 0, 0, 0.8), var(--shadow-glow);
            transform: translateY(20px);
            transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .modal-overlay.active .modal-card {
            transform: translateY(0);
        }

        .modal-card.modal-lg {
            max-width: 900px;
        }

        .modal-header {
            padding: 1.25rem 1.5rem;
            border-bottom: 1px solid var(--border-glass);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .modal-header h3 {
            font-family: var(--font-heading);
            font-size: 1.25rem;
            color: #ffffff;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        .modal-close {
            background: transparent;
            border: none;
            color: var(--text-secondary);
            font-size: 1.25rem;
            cursor: pointer;
            padding: 0.3rem;
            transition: color 0.15s;
        }
        .modal-close:hover {
            color: #ffffff;
        }

        .modal-body {
            padding: 1.5rem;
        }

        .modal-footer {
            padding: 1rem 1.5rem;
            border-top: 1px solid var(--border-glass);
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 0.75rem;
            background: rgba(5, 14, 11, 0.5);
        }

        /* Forms */
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1.15rem;
        }
        .form-group.full-width {
            grid-column: span 2;
        }

        .form-label {
            display: block;
            font-size: 0.825rem;
            font-weight: 600;
            color: var(--text-secondary);
            margin-bottom: 0.4rem;
        }

        .form-input, .form-select, .form-textarea {
            width: 100%;
            padding: 0.65rem 0.9rem;
            background: rgba(14, 34, 28, 0.6);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-sm);
            color: var(--text-main);
            font-size: 0.9rem;
            font-family: var(--font-body);
            outline: none;
            transition: all 0.2s;
        }
        .form-input:focus, .form-select:focus, .form-textarea:focus {
            border-color: var(--primary-light);
            background: rgba(14, 34, 28, 0.9);
            box-shadow: 0 0 12px rgba(16, 185, 129, 0.2);
        }

        /* Quick Schedule Chips */
        .quick-chips {
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
            margin-top: 0.6rem;
        }
        .chip-btn {
            background: rgba(16, 185, 129, 0.08);
            border: 1px solid var(--border-glass);
            color: var(--text-main);
            padding: 0.4rem 0.75rem;
            border-radius: 20px;
            font-size: 0.78rem;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.15s;
        }
        .chip-btn:hover {
            background: var(--primary-forest);
            color: #ffffff;
            border-color: var(--primary-light);
        }

        /* History & Preview Tabs */
        .modal-tabs {
            display: flex;
            border-bottom: 1px solid var(--border-glass);
            margin-bottom: 1.25rem;
            gap: 0.5rem;
        }
        .modal-tab-btn {
            padding: 0.6rem 1.2rem;
            background: transparent;
            border: none;
            border-bottom: 2px solid transparent;
            color: var(--text-secondary);
            font-size: 0.9rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
        }
        .modal-tab-btn.active {
            color: var(--primary-light);
            border-bottom-color: var(--primary-light);
        }

        .tab-panel {
            display: none;
        }
        .tab-panel.active {
            display: block;
        }

        /* History Timeline */
        .timeline {
            position: relative;
            padding-left: 1.5rem;
            border-left: 2px solid var(--border-glass);
            display: flex;
            flex-direction: column;
            gap: 1.5rem;
        }
        .timeline-item {
            position: relative;
        }
        .timeline-item::before {
            content: '';
            position: absolute;
            left: -1.95rem;
            top: 0.3rem;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: var(--primary-light);
            box-shadow: 0 0 10px var(--primary-light);
        }
        .timeline-meta {
            font-size: 0.75rem;
            color: var(--text-muted);
            font-family: var(--font-mono);
        }
        .timeline-subject {
            font-weight: 600;
            color: #ffffff;
            font-size: 0.95rem;
            margin: 0.2rem 0;
        }
        .timeline-recipient {
            font-size: 0.85rem;
            color: var(--text-secondary);
        }

        /* Preview Containers */
        .preview-frame {
            width: 100%;
            min-height: 480px;
            background: #ffffff;
            border-radius: var(--radius-sm);
            border: 1px solid #e2e8f0;
        }
        .preview-text {
            width: 100%;
            min-height: 300px;
            background: #040907;
            color: #a7f3d0;
            font-family: var(--font-mono);
            font-size: 0.825rem;
            padding: 1rem;
            border-radius: var(--radius-sm);
            border: 1px solid var(--border-glass);
            white-space: pre-wrap;
            word-break: break-all;
        }

        /* Terminal Drawer */
        .terminal-drawer {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            height: 380px;
            background: #020806;
            border-top: 2px solid var(--primary-emerald);
            box-shadow: 0 -10px 40px rgba(0, 0, 0, 0.8);
            z-index: 900;
            transform: translateY(100%);
            transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            display: flex;
            flex-direction: column;
        }
        .terminal-drawer.active {
            transform: translateY(0);
        }

        .terminal-header {
            padding: 0.75rem 1.5rem;
            background: rgba(16, 185, 129, 0.08);
            border-bottom: 1px solid var(--border-glass);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .terminal-title {
            font-family: var(--font-mono);
            font-size: 0.85rem;
            font-weight: 700;
            color: var(--primary-light);
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        .terminal-body {
            flex: 1;
            padding: 1rem 1.5rem;
            overflow-y: auto;
            font-family: var(--font-mono);
            font-size: 0.825rem;
            color: #ecfdf5;
            white-space: pre-wrap;
            line-height: 1.6;
        }

        /* Toast Notifications */
        .toast-container {
            position: fixed;
            bottom: 2rem;
            right: 2rem;
            z-index: 2000;
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            pointer-events: none;
        }
        .toast {
            background: #081d16;
            border: 1px solid var(--primary-light);
            color: #ffffff;
            padding: 0.85rem 1.25rem;
            border-radius: var(--radius-md);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.6), 0 0 15px rgba(16, 185, 129, 0.2);
            font-size: 0.875rem;
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 0.6rem;
            animation: toast-in 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            pointer-events: auto;
        }
        @keyframes toast-in {
            from { transform: translateX(50px); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }

        /* Responsive Breakpoints */
        @media (max-width: 900px) {
            .form-grid {
                grid-template-columns: 1fr;
            }
            .form-group.full-width {
                grid-column: span 1;
            }
            table.contacts-table th:nth-child(3),
            table.contacts-table td:nth-child(3) {
                display: none;
            }
        }
    </style>
</head>
<body>

<div class="app-container">
    <!-- Header Navigation -->
    <header class="nav-header">
        <div class="brand-section">
            <div class="brand-logo">📬</div>
            <div class="brand-text">
                <h1>
                    Reachout Control Panel
                    <span id="envBadge" class="env-badge production">Production</span>
                </h1>
                <div class="subline">Automated Outreach Campaign & Scheduling Engine</div>
            </div>
        </div>
        <div class="header-actions">
            <button id="btnRefresh" class="btn btn-secondary" title="Refresh Contacts & State">
                🔄 Refresh
            </button>
            <button id="btnRunDry" class="btn btn-secondary" title="Simulate outreach execution without sending">
                🧪 Dry-Run
            </button>
            <button id="btnRunLive" class="btn btn-primary" title="Trigger immediate scheduled reachout run">
                🚀 Execute Run
            </button>
            <button id="btnAddContact" class="btn btn-primary">
                ➕ Add Contact
            </button>
        </div>
    </header>

    <!-- Stats Dashboard Cards -->
    <section class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon">🎯</div>
            <div class="stat-details">
                <div class="stat-val" id="statTotal">--</div>
                <div class="stat-label">Total Targets</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon">⚡</div>
            <div class="stat-details">
                <div class="stat-val" id="statActive">--</div>
                <div class="stat-label">Active Campaigns</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon">⏸️</div>
            <div class="stat-details">
                <div class="stat-val" id="statPaused">--</div>
                <div class="stat-label">Paused Contacts</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon">📅</div>
            <div class="stat-details">
                <div class="stat-val" id="statReady">--</div>
                <div class="stat-label">Ready for Today</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon">⏳</div>
            <div class="stat-details">
                <div class="stat-val" id="statStaggered">--</div>
                <div class="stat-label">Staggered Queue</div>
            </div>
        </div>
    </section>

    <!-- Search & Filter Bar -->
    <div class="controls-bar">
        <div class="search-box">
            <span class="icon">🔍</span>
            <input type="text" id="searchInput" placeholder="Search venues, contacts, or emails..." autocomplete="off">
        </div>
        <div class="filter-tabs">
            <button class="filter-tab active" data-filter="all">All Targets</button>
            <button class="filter-tab" data-filter="active">Active</button>
            <button class="filter-tab" data-filter="ready">Ready Now</button>
            <button class="filter-tab" data-filter="staggered">Staggered</button>
            <button class="filter-tab" data-filter="paused">Paused</button>
        </div>
    </div>

    <!-- Main Table Container -->
    <main class="table-container">
        <table class="contacts-table">
            <thead>
                <tr>
                    <th>Target / Venue</th>
                    <th>Contact Info</th>
                    <th>Template & Policy</th>
                    <th>Attempts</th>
                    <th>Campaign Status</th>
                    <th>Scheduled Run</th>
                    <th style="text-align: right;">Actions</th>
                </tr>
            </thead>
            <tbody id="contactsTbody">
                <tr>
                    <td colspan="7" style="text-align: center; padding: 3rem; color: var(--text-secondary);">
                        Loading reachout data...
                    </td>
                </tr>
            </tbody>
        </table>
    </main>
</div>

<!-- Add / Edit Contact Modal -->
<div id="contactModal" class="modal-overlay">
    <div class="modal-card">
        <div class="modal-header">
            <h3 id="contactModalTitle">➕ Add Reachout Contact</h3>
            <button class="modal-close" onclick="closeModal('contactModal')">&times;</button>
        </div>
        <form id="contactForm">
            <div class="modal-body">
                <div class="form-grid">
                    <div class="form-group">
                        <label class="form-label" for="inpId">Target ID (Slug)</label>
                        <input type="text" id="inpId" class="form-input" placeholder="e.g. belly-up (auto-generated if empty)">
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="inpVenue">Venue / Organization *</label>
                        <input type="text" id="inpVenue" class="form-input" placeholder="e.g. Belly Up Tavern" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="inpContact">Contact Person Name</label>
                        <input type="text" id="inpContact" class="form-input" placeholder="e.g. Booking Manager">
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="inpEmail">Email Address *</label>
                        <input type="email" id="inpEmail" class="form-input" placeholder="booking@venue.com" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="inpPhone">Phone Number</label>
                        <input type="text" id="inpPhone" class="form-input" placeholder="(858) 555-1234">
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="inpWeb">Website URL</label>
                        <input type="url" id="inpWeb" class="form-input" placeholder="https://venue.com">
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="selTemplate">Email Template</label>
                        <select id="selTemplate" class="form-select">
                            <option value="rockready_club">Rock Ready Club Booking</option>
                            <option value="personal_job">Senior DevOps / SCM Career Outreach</option>
                            <option value="support_vendor">Vendor Support Gripe / Follow-up</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="selPolicy">Cadence Policy</label>
                        <select id="selPolicy" class="form-select">
                            <option value="passive">Passive (5-day spacing, polite reminder)</option>
                            <option value="aggressive">Aggressive (2-day spacing, high urgency)</option>
                        </select>
                    </div>
                    <div class="form-group full-width">
                        <label class="form-label" for="inpScheduleDate">Initial Schedule / Next Run Date</label>
                        <input type="datetime-local" id="inpScheduleDate" class="form-input">
                        <div class="quick-chips">
                            <button type="button" class="chip-btn" onclick="setQuickDate('inpScheduleDate', 0)">Ready Today</button>
                            <button type="button" class="chip-btn" onclick="setQuickDate('inpScheduleDate', 1)">Tomorrow 9am</button>
                            <button type="button" class="chip-btn" onclick="setQuickDateNextDay('inpScheduleDate', 1)">Next Monday 9am</button>
                            <button type="button" class="chip-btn" onclick="setQuickDateNextDay('inpScheduleDate', 2)">Next Tuesday 9am</button>
                            <button type="button" class="chip-btn" onclick="clearInput('inpScheduleDate')">Clear (Ready Now)</button>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeModal('contactModal')">Cancel</button>
                <button type="submit" class="btn btn-primary">Save Target</button>
            </div>
        </form>
    </div>
</div>

<!-- Schedule Modal -->
<div id="scheduleModal" class="modal-overlay">
    <div class="modal-card">
        <div class="modal-header">
            <h3>⏰ Schedule Next Outreach Run</h3>
            <button class="modal-close" onclick="closeModal('scheduleModal')">&times;</button>
        </div>
        <form id="scheduleForm">
            <input type="hidden" id="schedTargetId">
            <div class="modal-body">
                <p id="schedTargetName" style="color: var(--primary-light); font-weight: 600; margin-bottom: 1rem;"></p>
                <div class="form-group">
                    <label class="form-label" for="schedDateTime">Choose Date & Time for Dispatch:</label>
                    <input type="datetime-local" id="schedDateTime" class="form-input">
                </div>
                <div class="quick-chips">
                    <button type="button" class="chip-btn" onclick="setQuickDate('schedDateTime', 0)">Send on Next Run (Ready)</button>
                    <button type="button" class="chip-btn" onclick="setQuickDate('schedDateTime', 1)">Tomorrow 9:00 AM</button>
                    <button type="button" class="chip-btn" onclick="setQuickDateNextDay('schedDateTime', 1)">Next Monday 9:00 AM</button>
                    <button type="button" class="chip-btn" onclick="setQuickDateNextDay('schedDateTime', 2)">Next Tuesday 9:00 AM</button>
                    <button type="button" class="chip-btn" onclick="setQuickDate('schedDateTime', 7)">+1 Week</button>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeModal('scheduleModal')">Cancel</button>
                <button type="submit" class="btn btn-primary">Update Schedule</button>
            </div>
        </form>
    </div>
</div>

<!-- History & Preview Modal -->
<div id="previewModal" class="modal-overlay">
    <div class="modal-card modal-lg">
        <div class="modal-header">
            <h3 id="previewModalTitle">📧 Email Details & History</h3>
            <button class="modal-close" onclick="closeModal('previewModal')">&times;</button>
        </div>
        <div class="modal-body">
            <div class="modal-tabs">
                <button class="modal-tab-btn active" onclick="switchTab('tabHistory', this)">📜 Dispatch History</button>
                <button class="modal-tab-btn" onclick="switchTab('tabHtmlPreview', this)">🌐 HTML Email Preview</button>
                <button class="modal-tab-btn" onclick="switchTab('tabTextPreview', this)">📄 Plain Text Preview</button>
            </div>

            <!-- Tab: History -->
            <div id="tabHistory" class="tab-panel active">
                <div id="historyTimeline" class="timeline">
                    <!-- Populated dynamically -->
                </div>
            </div>

            <!-- Tab: HTML Preview -->
            <div id="tabHtmlPreview" class="tab-panel">
                <iframe id="htmlPreviewIframe" class="preview-frame" sandbox="allow-same-origin"></iframe>
            </div>

            <!-- Tab: Text Preview -->
            <div id="tabTextPreview" class="tab-panel">
                <pre id="textPreviewContainer" class="preview-text"></pre>
            </div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn btn-secondary" onclick="closeModal('previewModal')">Close</button>
        </div>
    </div>
</div>

<!-- Terminal Output Drawer -->
<div id="terminalDrawer" class="terminal-drawer">
    <div class="terminal-header">
        <div class="terminal-title">
            <span>💻</span>
            <span id="terminalDrawerTitle">Execution Output</span>
        </div>
        <button class="action-btn" onclick="closeTerminalDrawer()" title="Close Terminal">✕</button>
    </div>
    <pre id="terminalDrawerContent" class="terminal-body"></pre>
</div>

<!-- Toast Container -->
<div id="toastContainer" class="toast-container"></div>

<script>
    // State management
    let appData = {
        contacts: [],
        targets: {},
        stats: {},
        environment: 'production'
    };
    let currentFilter = 'all';

    // Fetch initial data
    async function loadData() {
        try {
            const resp = await fetch('api.php?action=data');
            const data = await resp.json();
            if (!data.success) {
                showToast(data.error || 'Failed to load data', 'error');
                return;
            }
            appData = data;
            renderEnvironment();
            renderStats();
            renderTable();
        } catch (err) {
            console.error(err);
            showToast('Network error loading data', 'error');
        }
    }

    function renderEnvironment() {
        const badge = document.getElementById('envBadge');
        if (appData.environment === 'production') {
            badge.className = 'env-badge production';
            badge.textContent = `Production (${appData.hostname})`;
        } else {
            badge.className = 'env-badge staging';
            badge.textContent = `Staging (${appData.hostname})`;
        }
    }

    function renderStats() {
        document.getElementById('statTotal').textContent = appData.stats.total ?? 0;
        document.getElementById('statActive').textContent = appData.stats.active ?? 0;
        document.getElementById('statPaused').textContent = appData.stats.paused ?? 0;
        document.getElementById('statReady').textContent = appData.stats.ready_now ?? 0;
        document.getElementById('statStaggered').textContent = appData.stats.staggered ?? 0;
    }

    function renderTable() {
        const tbody = document.getElementById('contactsTbody');
        const search = document.getElementById('searchInput').value.toLowerCase().trim();
        const now = Math.floor(Date.now() / 1000);

        const filtered = appData.contacts.filter(c => {
            const id = c.id;
            const t = appData.targets[id] || {};
            const status = t.status || c.status || 'active';
            const nextEpoch = t.next_run_epoch;

            // Search query
            const matchSearch = !search || 
                (c.venue && c.venue.toLowerCase().includes(search)) ||
                (c.contact && c.contact.toLowerCase().includes(search)) ||
                (c.email && c.email.toLowerCase().includes(search)) ||
                (id && id.toLowerCase().includes(search));

            if (!matchSearch) return false;

            // Filter tab
            if (currentFilter === 'active') return status === 'active';
            if (currentFilter === 'paused') return status === 'paused';
            if (currentFilter === 'ready') return status === 'active' && (!nextEpoch || nextEpoch <= now);
            if (currentFilter === 'staggered') return status === 'active' && (nextEpoch && nextEpoch > now);
            return true;
        });

        if (filtered.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" style="text-align: center; padding: 3rem; color: var(--text-secondary);">
                        No contacts found matching your criteria.
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = filtered.map(c => {
            const id = c.id;
            const t = appData.targets[id] || {};
            const status = t.status || c.status || 'active';
            const attempts = t.attempts || 0;
            const nextEpoch = t.next_run_epoch;
            const nextDate = t.next_run_date;

            // Schedule display calculation
            let schedHtml = '';
            if (status !== 'active') {
                schedHtml = `<div class="schedule-box"><span class="badge badge-paused">Paused</span><span class="schedule-relative">Campaign on hold</span></div>`;
            } else if (!nextEpoch || nextEpoch <= now) {
                schedHtml = `<div class="schedule-box"><span class="badge badge-active badge-pulse">Ready for Today</span><span class="schedule-relative">Queued for next dispatch</span></div>`;
            } else {
                const diffDays = Math.ceil((nextEpoch - now) / 86400);
                const relText = diffDays === 1 ? 'Tomorrow' : (diffDays > 1 ? `in ${diffDays} days` : 'Soon');
                schedHtml = `
                    <div class="schedule-box">
                        <span class="schedule-date">📅 ${formatDateTime(nextDate)}</span>
                        <span class="schedule-relative">${relText}</span>
                    </div>
                `;
            }

            // Status Badge
            const statusBadge = `<span class="badge badge-${status}">${capitalize(status)}</span>`;

            // Template & Policy formatting
            const tplName = c.template === 'rockready_club' ? 'Rock Ready' : (c.template === 'personal_job' ? 'Career' : 'Support');
            const polName = c.policy === 'aggressive' ? '2d Cadence' : '5d Cadence';

            return `
                <tr>
                    <td>
                        <div class="venue-cell">
                            <span class="venue-title">
                                ${escapeHtml(c.venue)}
                            </span>
                            <span class="venue-id">${escapeHtml(id)}</span>
                            ${c.web ? `<a href="${escapeHtml(c.web)}" target="_blank" rel="noopener" class="venue-web">🌐 Website ↗</a>` : ''}
                        </div>
                    </td>
                    <td>
                        <div class="contact-cell">
                            <span class="contact-name">${escapeHtml(c.contact || 'Booking Manager')}</span>
                            <span class="contact-meta"><a href="mailto:${escapeHtml(c.email)}">✉️ ${escapeHtml(c.email)}</a></span>
                            ${c.phone ? `<span class="contact-meta">📞 ${escapeHtml(c.phone)}</span>` : ''}
                        </div>
                    </td>
                    <td>
                        <div style="display:flex; flex-direction:column; gap:0.25rem;">
                            <span style="font-weight:600; color:#fff;">${tplName}</span>
                            <span style="font-size:0.75rem; color:var(--text-secondary);">${polName}</span>
                        </div>
                    </td>
                    <td>
                        <span class="attempts-pill">${attempts}</span>
                    </td>
                    <td>
                        ${statusBadge}
                    </td>
                    <td>
                        ${schedHtml}
                    </td>
                    <td style="text-align: right;">
                        <div class="actions-group" style="justify-content: flex-end;">
                            <button class="action-btn" title="${status === 'active' ? 'Pause Campaign' : 'Resume Campaign'}" onclick="toggleStatus('${escapeHtml(id)}', '${status}')">
                                ${status === 'active' ? '⏸️' : '▶️'}
                            </button>
                            <button class="action-btn" title="Set Scheduled Date" onclick="openScheduleModal('${escapeHtml(id)}')">
                                ⏰
                            </button>
                            <button class="action-btn" title="View History & Email Preview" onclick="openPreviewModal('${escapeHtml(id)}')">
                                👁️
                            </button>
                            <button class="action-btn" title="Edit Contact" onclick="openEditModal('${escapeHtml(id)}')">
                                ✏️
                            </button>
                            <button class="action-btn delete-btn" title="Delete Contact" onclick="deleteContact('${escapeHtml(id)}')">
                                🗑️
                            </button>
                        </div>
                    </td>
                </tr>
            `;
        }).join('');
    }

    // Modal Operations
    function openModal(id) {
        document.getElementById(id).classList.add('active');
    }
    function closeModal(id) {
        document.getElementById(id).classList.remove('active');
    }

    // Add / Edit Modal
    document.getElementById('btnAddContact').addEventListener('click', () => {
        document.getElementById('contactModalTitle').textContent = '➕ Add Reachout Contact';
        document.getElementById('contactForm').reset();
        document.getElementById('inpId').disabled = false;
        openModal('contactModal');
    });

    function openEditModal(id) {
        const c = appData.contacts.find(x => x.id === id);
        if (!c) return;
        const t = appData.targets[id] || {};

        document.getElementById('contactModalTitle').textContent = '✏️ Edit Reachout Contact';
        document.getElementById('inpId').value = c.id;
        document.getElementById('inpId').disabled = true;
        document.getElementById('inpVenue').value = c.venue || '';
        document.getElementById('inpContact').value = c.contact || '';
        document.getElementById('inpEmail').value = c.email || '';
        document.getElementById('inpPhone').value = c.phone || '';
        document.getElementById('inpWeb').value = c.web || '';
        document.getElementById('selTemplate').value = c.template || 'rockready_club';
        document.getElementById('selPolicy').value = c.policy || 'passive';
        
        if (t.next_run_date) {
            document.getElementById('inpScheduleDate').value = t.next_run_date.replace(' ', 'T').substring(0, 16);
        } else {
            document.getElementById('inpScheduleDate').value = '';
        }

        openModal('contactModal');
    }

    document.getElementById('contactForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const payload = {
            id: document.getElementById('inpId').value.trim(),
            venue: document.getElementById('inpVenue').value.trim(),
            contact: document.getElementById('inpContact').value.trim(),
            email: document.getElementById('inpEmail').value.trim(),
            phone: document.getElementById('inpPhone').value.trim(),
            web: document.getElementById('inpWeb').value.trim(),
            template: document.getElementById('selTemplate').value,
            policy: document.getElementById('selPolicy').value,
            schedule_date: document.getElementById('inpScheduleDate').value.replace('T', ' ')
        };

        try {
            const resp = await fetch('api.php?action=save_contact', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            const data = await resp.json();
            if (data.success) {
                showToast(data.message, 'success');
                closeModal('contactModal');
                loadData();
            } else {
                showToast(data.error || 'Failed to save contact', 'error');
            }
        } catch (err) {
            console.error(err);
            showToast('Network error saving contact', 'error');
        }
    });

    // Schedule Modal
    function openScheduleModal(id) {
        const c = appData.contacts.find(x => x.id === id);
        const t = appData.targets[id] || {};
        document.getElementById('schedTargetId').value = id;
        document.getElementById('schedTargetName').textContent = `${c ? c.venue : id} (${id})`;
        if (t.next_run_date) {
            document.getElementById('schedDateTime').value = t.next_run_date.replace(' ', 'T').substring(0, 16);
        } else {
            document.getElementById('schedDateTime').value = '';
        }
        openModal('scheduleModal');
    }

    document.getElementById('scheduleForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const id = document.getElementById('schedTargetId').value;
        const dt = document.getElementById('schedDateTime').value;

        try {
            const resp = await fetch('api.php?action=schedule', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    id: id,
                    date: dt ? dt.replace('T', ' ') : ''
                })
            });
            const data = await resp.json();
            if (data.success) {
                showToast(data.message, 'success');
                closeModal('scheduleModal');
                loadData();
            } else {
                showToast(data.error || 'Failed to update schedule', 'error');
            }
        } catch (err) {
            console.error(err);
            showToast('Network error scheduling target', 'error');
        }
    });

    // Toggle Status
    async function toggleStatus(id, currentStatus) {
        const newStatus = currentStatus === 'active' ? 'paused' : 'active';
        try {
            const resp = await fetch('api.php?action=set_status', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    id: id,
                    status: newStatus,
                    reason: newStatus === 'paused' ? 'Paused from Web UI' : 'Resumed from Web UI'
                })
            });
            const data = await resp.json();
            if (data.success) {
                showToast(data.message, 'success');
                loadData();
            } else {
                showToast(data.error, 'error');
            }
        } catch (err) {
            console.error(err);
            showToast('Network error updating status', 'error');
        }
    }

    // Delete Contact
    async function deleteContact(id) {
        const c = appData.contacts.find(x => x.id === id);
        const name = c ? c.venue : id;
        if (!confirm(`Are you sure you want to delete target '${name}'? This cannot be undone.`)) {
            return;
        }

        try {
            const resp = await fetch('api.php?action=delete_contact', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id: id })
            });
            const data = await resp.json();
            if (data.success) {
                showToast(data.message, 'success');
                loadData();
            } else {
                showToast(data.error, 'error');
            }
        } catch (err) {
            console.error(err);
            showToast('Network error deleting contact', 'error');
        }
    }

    // Preview & History Modal
    async function openPreviewModal(id) {
        const c = appData.contacts.find(x => x.id === id);
        const t = appData.targets[id] || {};

        document.getElementById('previewModalTitle').textContent = `📧 ${c ? c.venue : id} — Details & Preview`;

        // Render History
        const historyContainer = document.getElementById('historyTimeline');
        const history = t.history || [];
        if (history.length === 0) {
            historyContainer.innerHTML = `
                <div style="color: var(--text-secondary); font-size: 0.9rem;">
                    No outreach attempts have been dispatched for this target yet.
                </div>
            `;
        } else {
            historyContainer.innerHTML = history.slice().reverse().map(h => `
                <div class="timeline-item">
                    <div class="timeline-meta">Attempt #${h.attempt} &bull; ${h.date}</div>
                    <div class="timeline-subject">${escapeHtml(h.subject)}</div>
                    <div class="timeline-recipient">To: ${escapeHtml(h.recipient)}</div>
                    <div style="font-family:var(--font-mono); font-size:0.75rem; color:var(--text-muted); margin-top:0.2rem;">
                        ID: ${escapeHtml(h.message_id)}
                    </div>
                </div>
            `).join('');
        }

        // Fetch Live Rendered Template Preview
        try {
            const resp = await fetch(`api.php?action=preview&id=${encodeURIComponent(id)}`);
            const pData = await resp.json();
            if (pData.success) {
                // Populate iframe safely
                const iframe = document.getElementById('htmlPreviewIframe');
                iframe.srcdoc = pData.html;
                document.getElementById('textPreviewContainer').textContent = pData.text;
            }
        } catch (err) {
            console.error(err);
        }

        // Switch to history tab by default
        switchTab('tabHistory', document.querySelector('.modal-tab-btn'));
        openModal('previewModal');
    }

    function switchTab(tabId, btn) {
        document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
        document.querySelectorAll('.modal-tab-btn').forEach(b => b.classList.remove('active'));
        document.getElementById(tabId).classList.add('active');
        if (btn) btn.classList.add('active');
    }

    // Quick Date Helpers
    function setQuickDate(elementId, daysAhead) {
        const d = new Date();
        d.setDate(d.getDate() + daysAhead);
        d.setHours(9, 0, 0, 0);
        const str = formatDateForInput(d);
        document.getElementById(elementId).value = str;
    }

    function setQuickDateNextDay(elementId, targetDayOfWeek) { // 1 = Monday, 2 = Tuesday
        const d = new Date();
        const currentDay = d.getDay();
        let daysToAdd = (targetDayOfWeek + 7 - currentDay) % 7;
        if (daysToAdd === 0) daysToAdd = 7;
        d.setDate(d.getDate() + daysToAdd);
        d.setHours(9, 0, 0, 0);
        document.getElementById(elementId).value = formatDateForInput(d);
    }

    function clearInput(elementId) {
        document.getElementById(elementId).value = '';
    }

    function formatDateForInput(d) {
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        const hours = String(d.getHours()).padStart(2, '0');
        const mins = String(d.getMinutes()).padStart(2, '0');
        return `${year}-${month}-${day}T${hours}:${mins}`;
    }

    function formatDateTime(str) {
        if (!str) return 'Ready Now';
        const d = new Date(str.replace(' ', 'T'));
        if (isNaN(d)) return str;
        return d.toLocaleDateString('en-US', {
            weekday: 'short',
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        });
    }

    // Execution Drawer
    document.getElementById('btnRunDry').addEventListener('click', () => runReachout(true));
    document.getElementById('btnRunLive').addEventListener('click', () => {
        if (confirm("Are you sure you want to execute a LIVE reachout run? Active ready emails will be dispatched.")) {
            runReachout(false);
        }
    });

    async function runReachout(dryRun) {
        const title = dryRun ? "🧪 Dry-Run Execution" : "🚀 Live Outreach Execution";
        document.getElementById('terminalDrawerTitle').textContent = title;
        document.getElementById('terminalDrawerContent').textContent = "Executing reachout run...\n";
        document.getElementById('terminalDrawer').classList.add('active');

        try {
            const resp = await fetch('api.php?action=run', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ dry_run: dryRun ? 1 : 0 })
            });
            const data = await resp.json();
            const output = `$ ${data.command}\n\n${data.output || '(No output returned)'}\n\nProcess finished with exit code ${data.exit_code}.`;
            document.getElementById('terminalDrawerContent').textContent = output;
            loadData();
        } catch (err) {
            document.getElementById('terminalDrawerContent').textContent = `Execution failed: ${err.message}`;
        }
    }

    function closeTerminalDrawer() {
        document.getElementById('terminalDrawer').classList.remove('active');
    }

    // Filter tabs listener
    document.querySelectorAll('.filter-tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.filter-tab').forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            currentFilter = tab.getAttribute('data-filter');
            renderTable();
        });
    });

    document.getElementById('searchInput').addEventListener('input', renderTable);
    document.getElementById('btnRefresh').addEventListener('click', () => {
        showToast('Refreshing reachout state...', 'info');
        loadData();
    });

    // Toast utility
    function showToast(msg, type = 'info') {
        const container = document.getElementById('toastContainer');
        const toast = document.createElement('div');
        toast.className = 'toast';
        const icon = type === 'error' ? '❌' : (type === 'success' ? '✅' : 'ℹ️');
        toast.innerHTML = `<span>${icon}</span><span>${escapeHtml(msg)}</span>`;
        container.appendChild(toast);
        setTimeout(() => {
            toast.style.transition = 'opacity 0.3s';
            toast.style.opacity = '0';
            setTimeout(() => toast.remove(), 300);
        }, 3200);
    }

    function escapeHtml(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    function capitalize(str) {
        if (!str) return '';
        return str.charAt(0).toUpperCase() + str.slice(1);
    }

    // Initialize
    loadData();
</script>

</body>
</html>
