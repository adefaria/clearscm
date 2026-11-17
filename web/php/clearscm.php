<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSfile: clearscm.php,v $
// Revision:	$Revision: 2.0 $
// Description:	ClearSCM modern layout, navigation, code display, and POD helpers
// Author:	Andrew@DeFaria.com
// Created:	Wed Apr 11 18:37:09 2007
// Modified:	$Date: 2026/11/17 $
// Language:	Php
//
// (c) Copyright 2007-2026, ClearSCM Inc., all rights reserved
//
////////////////////////////////////////////////////////////////////////////////
require_once __DIR__ . "/scm.php";

date_default_timezone_set('America/Los_Angeles');

$base = $_SERVER['DOCUMENT_ROOT'];

function menu_css () {
  $script_file = $_SERVER['SCRIPT_FILENAME'] ?? __FILE__;
  $mod_time = @file_exists($script_file)
    ? date("F d Y @ g:i a", filemtime($script_file))
    : date("F d Y @ g:i a");

  print '<meta name="viewport" content="width=device-width, initial-scale=1.0">' . "\n";
  print '<meta name="last-modified" content="' . htmlspecialchars($mod_time, ENT_QUOTES) . '">' . "\n";
  print '<link rel="preconnect" href="https://fonts.googleapis.com">' . "\n";
  print '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>' . "\n";
  print '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Outfit:wght@500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">' . "\n";
  print '<link rel="stylesheet" href="/css/style.css" id="clearscm-site-css">' . "\n";

  print <<<'MODERN_CSS'
<style id="clearscm-modern-css" type="text/css">
  :root {
    --bg-color: #121212;
    --surface-color: #1e1e1e;
    --surface-elevated: #262626;
    --text-color: #e0e0e0;
    --muted-color: #a0a0a0;
    --card-border: rgba(255, 255, 255, 0.09);
    --code-bg: #16181d;
    --code-border: rgba(255, 255, 255, 0.12);
    --code-line-bg: rgba(255, 255, 255, 0.03);
    --google-blue: rgb(66, 133, 244);
    --google-red: rgb(234, 67, 53);
    --google-yellow: rgb(251, 188, 5);
    --google-green: rgb(52, 168, 83);
    --clearscm-link: #8ab4f8;
    --font-main: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    --font-heading: 'Outfit', sans-serif;
    --font-mono: 'JetBrains Mono', 'Fira Code', Consolas, monospace;
  }

  [data-theme="light"] {
    --bg-color: #f4f6f9;
    --surface-color: #ffffff;
    --surface-elevated: #f8f9fa;
    --text-color: #202124;
    --muted-color: #5f6368;
    --card-border: rgba(0, 0, 0, 0.09);
    --code-bg: #f4f6f8;
    --code-border: rgba(0, 0, 0, 0.12);
    --code-line-bg: rgba(0, 0, 0, 0.04);
    --clearscm-link: #1a73e8;
  }

  body {
    background: var(--bg-color) !important;
    color: var(--text-color) !important;
    font-family: var(--font-main) !important;
    font-size: 15px !important;
    line-height: 1.65 !important;
    margin: 0 !important;
    padding: 0 0 90px 0 !important;
    text-align: left !important;
    height: auto !important;
    min-height: 100vh !important;
    overflow-x: hidden !important;
  }

  .filtered {
    display: none !important;
  }

  /* Modern Header & Sub-Navigation */
  .clearscm-modern-header {
    background: var(--surface-color);
    border-bottom: 1px solid var(--card-border);
    position: sticky;
    top: 0;
    z-index: 1000;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  }

  .clearscm-header-inner {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0.75rem 2rem;
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 1rem;
  }

  .clearscm-brand {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    text-decoration: none !important;
  }

  .clearscm-brand-badge {
    width: 36px;
    height: 36px;
    border-radius: 10px;
    background: linear-gradient(135deg, var(--google-red), #ff7043);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    font-family: var(--font-heading);
    font-weight: 700;
    font-size: 1.05rem;
    letter-spacing: -0.5px;
    box-shadow: 0 2px 8px rgba(234, 67, 53, 0.35);
    flex-shrink: 0;
  }

  .clearscm-brand-text {
    display: flex;
    flex-direction: column;
  }

  .clearscm-brand-title {
    font-family: var(--font-heading);
    font-size: 1.25rem;
    font-weight: 700;
    color: var(--text-color);
    line-height: 1.15;
  }

  .clearscm-brand-subtitle {
    font-size: 0.75rem;
    color: var(--muted-color);
    font-weight: 500;
  }

  .clearscm-nav {
    display: flex;
    align-items: center;
    gap: 0.25rem;
    flex-wrap: wrap;
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .clearscm-nav-item {
    position: relative;
  }

  .clearscm-nav-link {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 0.45rem 0.85rem;
    border-radius: 8px;
    color: var(--text-color) !important;
    font-weight: 500;
    font-size: 0.9rem;
    text-decoration: none !important;
    transition: background-color 0.15s ease, color 0.15s ease;
  }

  .clearscm-nav-link:hover,
  .clearscm-nav-item:hover > .clearscm-nav-link,
  .clearscm-nav-link.active {
    background: var(--surface-elevated);
    color: var(--google-red) !important;
  }

  .clearscm-caret {
    font-size: 0.7rem;
    opacity: 0.7;
    transition: transform 0.15s ease;
  }

  .clearscm-nav-item:hover > .clearscm-nav-link .clearscm-caret {
    transform: rotate(180deg);
  }

  /* Dropdown Menus */
  .clearscm-dropdown {
    position: absolute;
    top: 100%;
    left: 0;
    min-width: 210px;
    background: var(--surface-color);
    border: 1px solid var(--card-border);
    border-radius: 10px;
    padding: 0.4rem;
    box-shadow: 0 10px 28px rgba(0, 0, 0, 0.25);
    list-style: none;
    margin: 0;
    opacity: 0;
    visibility: hidden;
    transform: translateY(6px);
    transition: opacity 0.15s ease, transform 0.15s ease, visibility 0.15s;
    z-index: 1100;
  }

  .clearscm-nav-item:last-child .clearscm-dropdown {
    left: auto;
    right: 0;
  }

  .clearscm-nav-item:hover > .clearscm-dropdown,
  .clearscm-nav-item:focus-within > .clearscm-dropdown {
    opacity: 1;
    visibility: visible;
    transform: translateY(0);
  }

  .clearscm-dropdown li {
    position: relative;
  }

  .clearscm-dropdown a {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0.45rem 0.75rem;
    border-radius: 7px;
    color: var(--text-color) !important;
    font-size: 0.86rem;
    font-weight: 500;
    text-decoration: none !important;
    transition: background-color 0.15s ease, color 0.15s ease;
    white-space: nowrap;
  }

  .clearscm-dropdown a:hover {
    background: var(--surface-elevated);
    color: var(--google-red) !important;
  }

  /* Nested Sub-Dropdown */
  .clearscm-subdropdown {
    position: absolute;
    top: -0.4rem;
    left: 100%;
    min-width: 195px;
    background: var(--surface-color);
    border: 1px solid var(--card-border);
    border-radius: 10px;
    padding: 0.4rem;
    box-shadow: 0 10px 28px rgba(0, 0, 0, 0.25);
    list-style: none;
    margin: 0;
    opacity: 0;
    visibility: hidden;
    transform: translateX(6px);
    transition: opacity 0.15s ease, transform 0.15s ease, visibility 0.15s;
    z-index: 1200;
  }

  .clearscm-dropdown li:hover > .clearscm-subdropdown {
    opacity: 1;
    visibility: visible;
    transform: translateX(0);
  }

  /* Page & Content Layout */
  #page {
    position: static !important;
    background: transparent !important;
    color: var(--text-color) !important;
    max-width: 1200px !important;
    width: auto !important;
    min-height: 0 !important;
    margin: 0 auto !important;
    padding: 1.75rem 2rem !important;
    text-align: left !important;
  }

  #content {
    max-width: 100% !important;
    min-width: 0 !important;
    width: auto !important;
    margin: 0 !important;
    padding: 2rem 2.25rem !important;
    background: var(--surface-color);
    border: 1px solid var(--card-border);
    border-top: 3px solid var(--google-red);
    border-radius: 16px;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  }

  /* Multi-card grid pages (index.php, services/index.php) */
  #content.clearscm-grid-page,
  #content:has(#contentWrapper2) {
    background: transparent !important;
    border: none !important;
    box-shadow: none !important;
    padding: 0 !important;
  }

  /* Card Grid Utilities */
  .clearscm-hero-card {
    background: var(--surface-color);
    border: 1px solid var(--card-border);
    border-top: 3px solid var(--google-red);
    border-radius: 16px;
    padding: 1.75rem 2rem;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
    margin-bottom: 1.5rem;
  }

  .clearscm-lead-banner {
    background: var(--surface-elevated);
    border: 1px solid var(--card-border);
    border-left: 4px solid var(--google-blue);
    border-radius: 10px;
    padding: 1rem 1.25rem;
    margin-bottom: 1.25rem;
    font-size: 1.02rem;
  }

  .clearscm-lead-banner p {
    margin: 0 !important;
  }

  .clearscm-card-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
    gap: 1.25rem;
    align-items: stretch;
  }

  .clearscm-card-grid-2 {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 1.25rem;
    align-items: stretch;
  }

  .clearscm-card {
    background: var(--surface-color);
    border: 1px solid var(--card-border);
    border-top: 3px solid var(--google-blue);
    border-radius: 14px;
    padding: 1.4rem 1.6rem;
    box-shadow: 0 3px 12px rgba(0, 0, 0, 0.07);
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
  }

  .clearscm-card.accent-red    { border-top-color: var(--google-red); }
  .clearscm-card.accent-blue   { border-top-color: var(--google-blue); }
  .clearscm-card.accent-green  { border-top-color: var(--google-green); }
  .clearscm-card.accent-yellow { border-top-color: var(--google-yellow); }

  .clearscm-card h2,
  .clearscm-card h3 {
    margin-top: 0 !important;
  }

  @media (max-width: 860px) {
    .clearscm-card-grid-2 {
      grid-template-columns: 1fr;
    }
    .clearscm-header-inner {
      padding: 0.75rem 1rem;
    }
    #page {
      padding: 1rem !important;
    }
    #content {
      padding: 1.25rem !important;
    }
  }

  /* Contained Boxes (start_box / end_box inside #content or #main)
     NEVER show a colored top border inside a container that already has one! */
  .rcbox {
    margin: 0 0 1.25rem 0 !important;
  }

  .rcbox b.xtop,
  .rcbox b.xbottom {
    display: none !important;
  }

  /* Page Title Box at the very top of #content */
  #content > .rcbox:first-child {
    margin: 0 0 1.5rem 0 !important;
  }

  #content > .rcbox:first-child .xboxcontent {
    background: transparent !important;
    border: none !important;
    border-bottom: 1px solid var(--card-border) !important;
    border-radius: 0 !important;
    padding: 0 0 1rem 0 !important;
    box-shadow: none !important;
  }

  #content > .rcbox:first-child h2 {
    text-align: left !important;
    margin: 0 !important;
    font-size: 1.75rem !important;
    color: var(--google-red) !important;
  }

  /* Inline Callout Boxes inside Article Content (e.g. Problem Statement, In-depth links) */
  #content .rcbox:not(:first-child) .xboxcontent,
  #main .rcbox .xboxcontent {
    background: var(--surface-elevated) !important;
    border: 1px solid var(--card-border) !important;
    border-left: 4px solid var(--google-blue) !important;
    border-radius: 10px !important;
    padding: 0.95rem 1.25rem !important;
    color: var(--text-color) !important;
    box-shadow: none !important;
  }

  /* Standalone Grid Boxes (#supporting / #related if used) */
  #supporting .rcbox,
  #related .rcbox {
    margin: 0 !important;
    display: flex;
    flex-direction: column;
  }

  #supporting .rcbox .xboxcontent,
  #related .rcbox .xboxcontent {
    background: var(--surface-color) !important;
    border: 1px solid var(--card-border) !important;
    border-top: 3px solid var(--google-blue) !important;
    border-radius: 14px !important;
    padding: 1.35rem 1.5rem !important;
    color: var(--text-color) !important;
    box-shadow: 0 3px 12px rgba(0, 0, 0, 0.07) !important;
    flex: 1;
  }

  #supporting .rcbox.cs3 .xboxcontent,
  #related .rcbox.cs3 .xboxcontent {
    border-top-color: var(--google-red) !important;
  }

  #supporting .rcbox.cs4 .xboxcontent,
  #related .rcbox.cs4 .xboxcontent {
    border-top-color: var(--google-green) !important;
  }

  #supporting .rcbox.cs5 .xboxcontent,
  #related .rcbox.cs5 .xboxcontent {
    border-top-color: var(--google-yellow) !important;
  }

  /* Typography & Elements */
  #content h1,
  #content h2,
  #content h3,
  #content h4 {
    font-family: var(--font-heading) !important;
    margin-left: 0 !important;
    margin-right: 0 !important;
    line-height: 1.3 !important;
  }

  #content h1 {
    color: var(--google-red) !important;
    font-size: 1.65rem !important;
    margin-top: 1.5rem !important;
    margin-bottom: 0.75rem !important;
    border-bottom: 1px solid var(--card-border);
    padding-bottom: 0.4rem;
  }

  #content h1:first-child {
    margin-top: 0 !important;
  }

  #content h2 {
    color: var(--google-red) !important;
    font-size: 1.35rem !important;
    margin-top: 1.1rem !important;
    margin-bottom: 0.6rem !important;
    text-align: left !important;
  }

  #content h3 {
    color: var(--google-blue) !important;
    font-size: 1.15rem !important;
    margin-top: 1.35rem !important;
    margin-bottom: 0.45rem !important;
    clear: both;
  }

  #content p {
    margin: 0.65rem 0 !important;
    color: var(--text-color) !important;
  }

  #content a {
    color: var(--clearscm-link) !important;
    text-decoration: none;
  }

  #content a:hover {
    text-decoration: underline;
    color: var(--google-red) !important;
  }

  .standout,
  font.standout {
    color: var(--google-green) !important;
    font-weight: 600 !important;
  }

  dt {
    font-weight: 600;
    color: var(--google-blue);
    margin-top: 0.75rem;
  }

  dd {
    margin-left: 1.25rem;
    margin-bottom: 0.5rem;
  }

  blockquote {
    margin: 0.75rem 0;
    padding: 0.5rem 1rem;
    border-left: 3px solid var(--google-blue);
    background: var(--surface-elevated);
    border-radius: 0 8px 8px 0;
  }

  /* Images & Customer Logos */
  #content img {
    border-radius: 10px;
    max-width: 100%;
    height: auto;
  }

  #content img[style*="float:left"],
  #content img[style*="float: left"] {
    margin: 0.25rem 1.25rem 0.75rem 0 !important;
  }

  #content img[style*="float:right"],
  #content img[style*="float: right"] {
    margin: 0.25rem 0 0.75rem 1.25rem !important;
  }

  .clearscm-logo-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 1rem;
    align-items: center;
    margin: 1rem 0;
  }

  .clearscm-logo-item {
    background: #ffffff;
    border: 1px solid rgba(0, 0, 0, 0.08);
    border-radius: 12px;
    padding: 1rem;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 80px;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
    transition: transform 0.15s ease, box-shadow 0.15s ease;
  }

  .clearscm-logo-item:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  }

  .clearscm-logo-item img {
    max-height: 56px;
    width: auto;
    border-radius: 0 !important;
    margin: 0 !important;
    padding: 0 !important;
    box-shadow: none !important;
  }

  #content img[src$="Aspen.gif"],
  #content img[src$="Edentree.jpg"],
  #content img[src$="Vpacket.png"],
  #content img[src$="Nortel.gif"] {
    background: #ffffff;
    padding: 10px 14px;
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
    margin: 6px 0;
  }

  /* Code Blocks & Listings */
  div.code {
    background: var(--code-bg) !important;
    border: 1px solid var(--code-border) !important;
    border-radius: 10px !important;
    margin: 1rem 0 !important;
    padding: 0 !important;
    overflow-x: auto !important;
    font-family: var(--font-mono) !important;
    font-size: 0.85rem !important;
    line-height: 1.55 !important;
  }

  div.code pre {
    margin: 0 !important;
    padding: 1rem 1.25rem !important;
    font-family: var(--font-mono) !important;
    color: var(--text-color) !important;
    overflow-x: auto;
  }

  table#listing {
    width: 100% !important;
    border-collapse: collapse !important;
    margin: 0 !important;
    font-family: var(--font-mono) !important;
    font-size: 0.84rem !important;
  }

  table#listing tr:hover {
    background: rgba(128, 128, 128, 0.06);
  }

  table#listing td#line-number {
    width: 48px !important;
    min-width: 48px !important;
    text-align: right !important;
    padding: 1px 12px !important;
    background: var(--code-line-bg) !important;
    border-right: 1px solid var(--code-border) !important;
    color: var(--muted-color) !important;
    user-select: none;
    vertical-align: top;
  }

  table#listing td#code {
    padding: 1px 14px !important;
    color: var(--text-color) !important;
    white-space: nowrap;
    vertical-align: top;
  }

  table#listing td#code tt {
    font-family: var(--font-mono) !important;
  }

  /* File / Manpage Toolbar */
  .scm-toolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 0.75rem;
    padding: 0.75rem 1.1rem;
    margin-bottom: 1.25rem;
    background: var(--surface-elevated);
    border: 1px solid var(--card-border);
    border-radius: 10px;
  }

  .scm-toolbar-title {
    font-family: var(--font-mono);
    font-weight: 600;
    font-size: 0.95rem;
    color: var(--google-blue);
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .scm-toolbar-actions {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    flex-wrap: wrap;
  }

  .scm-btn {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 0.35rem 0.75rem;
    border-radius: 7px;
    font-size: 0.82rem;
    font-weight: 500;
    background: var(--surface-color);
    border: 1px solid var(--card-border);
    color: var(--text-color) !important;
    text-decoration: none !important;
    transition: all 0.15s ease;
  }

  .scm-btn:hover,
  .scm-btn.active {
    border-color: var(--google-red);
    color: var(--google-red) !important;
    text-decoration: none !important;
  }

  /* Hide redundant inner copyright footer when embedded in defaria.com iframe */
  html.embedded #foot {
    display: none !important;
  }

  #foot {
    position: static !important;
    margin-top: 2rem;
    padding: 1rem 0;
    text-align: center;
    color: var(--muted-color);
    font-size: 0.85rem;
  }
</style>
<script type="text/javascript">
(function() {
  // 1. If loaded at top-level window, redirect into defaria.com shell iframe
  // unless ?standalone=1 is present.
  if (window.top === window.self && window.location.search.indexOf('standalone=1') === -1) {
    var currentUrl = window.location.pathname + window.location.search + window.location.hash;
    window.location.replace('/?url=' + encodeURIComponent(currentUrl));
    return;
  }

  if (window.top !== window.self) {
    document.documentElement.classList.add('embedded');
  }

  // Disable any legacy stylesheet links immediately before body render
  var links = document.querySelectorAll('link[rel="stylesheet"]');
  for (var i = 0; i < links.length; i++) {
    var href = links[i].getAttribute('href') || '';
    if (href.indexOf('FrontPage.css') !== -1 ||
        href.indexOf('Article.css') !== -1 ||
        href.indexOf('ManPage.css') !== -1 ||
        href.indexOf('Code.css') !== -1 ||
        href.indexOf('Menus.css') !== -1 ||
        href.indexOf('TableBorders.css') !== -1) {
      links[i].disabled = true;
    }
  }

  // 2. Theme synchronization (dark / light) with parent shell
  function detectTheme() {
    var t = null;
    try {
      if (window.parent && window.parent.document && window.self !== window.top) {
        t = window.parent.document.documentElement.getAttribute('data-theme');
      }
    } catch (e) {}
    if (!t) {
      try { t = localStorage.getItem('user_theme_override'); } catch (e) {}
    }
    if (!t) {
      try {
        var m = document.cookie.match(/(^| )user_theme_override=([^;]+)/);
        if (m) t = m[2];
      } catch (e) {}
    }
    if (!t && window.matchMedia) {
      t = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    }
    return t || 'dark';
  }

  document.documentElement.setAttribute('data-theme', detectTheme());

  window.addEventListener('message', function(event) {
    if (event.data && event.data.type === 'themeChange' && event.data.theme) {
      document.documentElement.setAttribute('data-theme', event.data.theme);
    }
  });

  if (window.self !== window.top) {
    try {
      var obs = new MutationObserver(function() {
        try {
          var pt = window.parent.document.documentElement.getAttribute('data-theme');
          if (pt) document.documentElement.setAttribute('data-theme', pt);
        } catch (e) {}
      });
      obs.observe(window.parent.document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
    } catch (e) {}
  }

  // 3. Sync Title & Footer Last Modified with parent shell
  window.addEventListener('DOMContentLoaded', function() {
    if (window.self !== window.top) {
      try {
        if (document.title) window.parent.document.title = document.title;
        var footerDate = window.parent.document.getElementById('footer-mod-date');
        var meta = document.querySelector('meta[name="last-modified"]');
        if (footerDate && meta) {
          var pageName = document.title.replace(' - Andrew DeFaria', '');
          footerDate.textContent = pageName + ': Last modified ' + meta.getAttribute('content');
        }
      } catch (e) {}
    }
  });
})();
</script>
MODERN_CSS;
} // menu_css

function heading () {
  $uri = $_SERVER['REQUEST_URI'] ?? '/clearscm/';
  $is_home = ($uri === '/clearscm/' || $uri === '/clearscm/index.php');
  $is_services = (strpos($uri, '/services') !== false);
  $is_scm = (strpos($uri, '/clearcase') !== false || strpos($uri, '/clearquest') !== false || strpos($uri, 'scm_man.php') !== false);
  $is_scripts = (strpos($uri, '/scripts') !== false);
  $is_sysadm = (strpos($uri, '/sysadm') !== false);
  $is_about = (strpos($uri, '/people.php') !== false || strpos($uri, '/contact.php') !== false || strpos($uri, '/addendum.php') !== false || strpos($uri, '/Resumes/') !== false);

  $c_home = $is_home ? 'active' : '';
  $c_services = $is_services ? 'active' : '';
  $c_scm = $is_scm ? 'active' : '';
  $c_scripts = $is_scripts ? 'active' : '';
  $c_sysadm = $is_sysadm ? 'active' : '';
  $c_about = $is_about ? 'active' : '';

  print <<<HTML
<header class="clearscm-modern-header">
  <div class="clearscm-header-inner">
    <a href="/clearscm/" class="clearscm-brand">
      <div class="clearscm-brand-badge">CS</div>
      <div class="clearscm-brand-text">
        <span class="clearscm-brand-title">ClearSCM Inc.</span>
        <span class="clearscm-brand-subtitle">SCM, Build &amp; Release, and Systems Engineering</span>
      </div>
    </a>

    <ul class="clearscm-nav">
      <li class="clearscm-nav-item">
        <a href="/clearscm/" class="clearscm-nav-link $c_home">Home</a>
      </li>

      <li class="clearscm-nav-item">
        <a href="/clearscm/services/" class="clearscm-nav-link $c_services">Services</a>
      </li>

      <li class="clearscm-nav-item">
        <a href="/clearscm/services/#scm" class="clearscm-nav-link $c_scm">SCM <span class="clearscm-caret">&#9662;</span></a>
        <ul class="clearscm-dropdown">
          <li>
            <a href="/clearscm/clearcase/">ClearCase <span>&#9656;</span></a>
            <ul class="clearscm-subdropdown">
              <li><a href="/clearscm/clearcase/triggers.php">Triggers</a></li>
              <li><a href="/clearscm/php/scm_man.php?file=cc/etf.pl">Evil Twin Finder</a></li>
              <li><a href="/clearscm/php/scm_man.php?file=cc/diffbl.pl">GUI DiffBL</a></li>
              <li><a href="/clearscm/php/scm_man.php?file=clearadm/viewager.cgi">View Ager</a></li>
              <li><a href="/clearscm/clearcase/OpenSourceBuild.php">Open Source Builds</a></li>
            </ul>
          </li>
          <li>
            <a href="/clearscm/clearquest/">ClearQuest <span>&#9656;</span></a>
            <ul class="clearscm-subdropdown">
              <li><a href="/clearscm/clearquest/cqd/">ClearQuest Daemon</a></li>
              <li><a href="/clearscm/clearquest/db.php">DB Conversions</a></li>
            </ul>
          </li>
          <li>
            <a href="https://github.com/adefaria/clearscm" target="_blank">GitHub Repository <span>&#8599;</span></a>
          </li>
        </ul>
      </li>

      <li class="clearscm-nav-item">
        <a href="/clearscm/scripts/" class="clearscm-nav-link $c_scripts">Scripting <span class="clearscm-caret">&#9662;</span></a>
        <ul class="clearscm-dropdown">
          <li><a href="/clearscm/scripts/perl.php">Perl Modules</a></li>
          <li><a href="/clearscm/scripts/ecrd/">ECRDig</a></li>
        </ul>
      </li>

      <li class="clearscm-nav-item">
        <a href="/clearscm/sysadm/" class="clearscm-nav-link $c_sysadm">Sysadm <span class="clearscm-caret">&#9662;</span></a>
        <ul class="clearscm-dropdown">
          <li><a href="/clearscm/sysadm/env/">Environment</a></li>
        </ul>
      </li>

      <li class="clearscm-nav-item">
        <a href="/clearscm/people.php" class="clearscm-nav-link $c_about">About <span class="clearscm-caret">&#9662;</span></a>
        <ul class="clearscm-dropdown">
          <li><a href="/clearscm/services/">Services</a></li>
          <li><a href="/clearscm/people.php">Our People</a></li>
          <li><a href="/clearscm/contact.php">Contact Us</a></li>
          <li><a href="/clearscm/addendum.php">Contract Addendum</a></li>
        </ul>
      </li>
    </ul>
  </div>
</header>
HTML;
} // heading

function start_box ($type) {
  print "<div class=\"rcbox $type\"><div class=\"xboxcontent\">\n";
} // start_box

function end_box () {
  print "</div></div>\n";
} // end_box

function search_box () {
  print <<<END
<div id="search">
  <form method="get" action="https://www.google.com/search" name="search">
  <div>Search my site
  <input type="text" name="q" size="15" id="q" maxlength=255 value=""
    onclick="document.search.q.value='';">
  <input type="hidden" name="domains" value="defaria.com">
  <input type="hidden" name="sitesearch" value="defaria.com">
  </div>
  </form>
</div>
<br>
END;
} // search_box

function copyright ($start_year	= "",
		    $author	= "Andrew DeFaria",
	            $email	= "info@clearscm.com",
		    $home       = "") {
  $today	= getdate ();
  $current_year	= $today ["year"];

  $this_file = $_SERVER['SCRIPT_FILENAME'] ?? (__FILE__);
  $mod_time  = @file_exists($this_file)
    ? date ("F d Y @ g:i a", filemtime ($this_file))
    : date ("F d Y @ g:i a");

  print <<<END
<div id="foot"><p>
  Last modified: $mod_time<br>
  Copyright &copy;&nbsp;
END;

  if ($start_year != "") {
    print "$start_year-";
  } // if

  print <<<END
$current_year, ClearSCM Inc. - All rights reserved
</p></div>
END;
} // copyright

function render_scm_toolbar ($file, $active = 'man') {
  $safe_file = htmlspecialchars ($file, ENT_QUOTES);
  $url_file  = urlencode ($file);
  $git_rel   = resolveSCMGitRelPath ($file);
  $gh_url    = "https://github.com/adefaria/clearscm/blob/main/" . htmlspecialchars ($git_rel, ENT_QUOTES);
  $gh_hist   = "https://github.com/adefaria/clearscm/commits/main/" . htmlspecialchars ($git_rel, ENT_QUOTES);

  $man_cls = ($active === 'man') ? 'active' : '';
  $src_cls = ($active === 'source') ? 'active' : '';

  print <<<HTML
<div class="scm-toolbar">
  <div class="scm-toolbar-title">
    <span>&#128196; $safe_file</span>
  </div>
  <div class="scm-toolbar-actions">
    <a class="scm-btn $man_cls" href="/clearscm/php/scm_man.php?file=$url_file">POD Manual</a>
    <a class="scm-btn $src_cls" href="/clearscm/php/scm_man.php?file=$url_file&amp;action=source">Source Code</a>
    <a class="scm-btn" href="/clearscm/php/scm_man.php?file=$url_file&amp;action=raw">Download</a>
    <a class="scm-btn" href="$gh_hist" target="_blank">Git History &#8599;</a>
    <a class="scm-btn" href="$gh_url" target="_blank">GitHub &#8599;</a>
  </div>
</div>
HTML;
} // render_scm_toolbar

function display_contents_as_code ($contents) {
  print "<div class=code>";
  print "<table id=listing cellspacing=0 cellpadding=2 border=0 width=100%>";

  $line_number = 1;

  foreach ($contents as $line) {
    $line = rtrim ($line, "\r\n");
    print "<tr>";
    print "  <td id=line-number><a name=line_$line_number></a>" .
      $line_number++ . "</td>";
    print "  <td id=code><tt>";

    $escaped = htmlspecialchars ($line, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    $out = '';
    $len = strlen ($escaped);
    for ($i = 0; $i < $len; $i++) {
      if ($escaped[$i] === ' ') {
        $out .= '&nbsp;';
      } else if ($escaped[$i] === "\t") {
        $out .= '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
      } else {
        $out .= $escaped[$i];
      }
    }
    echo $out === '' ? '&nbsp;' : $out;

    print "</tt></td>";
    print "</tr>\n";
  } // foreach

  print "</table>";
  print "</div>";
} // display_contents_as_code

function display_contents_as_snippet ($contents) {
  print "<div class=code>";

  foreach ($contents as $line) {
    $escaped = htmlspecialchars (rtrim ($line, "\r\n"), ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    $escaped = str_replace (array (" ", "\t"), array ("&nbsp;", "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"), $escaped);
    echo $escaped . "<br>\n";
  } // foreach

  print "</div>";
} // display_contents_as_snippet

function display_code ($file, $show_toolbar = true) {
  if ($show_toolbar) {
    render_scm_toolbar ($file, 'source');
  }
  display_contents_as_code (getSCMFile ($file));
} // display_code

function scm_man ($file, $show_toolbar = true) {
  if ($show_toolbar) {
    render_scm_toolbar ($file, 'man');
  }

  $desc_spec = array (
    0 => array ("pipe", "r"), // stdin
    1 => array ("pipe", "w"), // stdout
    2 => array ("pipe", "w"), // stderr
  );

  $pod2html = proc_open ("pod2html --cachedir=/tmp --noindex --htmlroot=https://perldoc.perl.org", $desc_spec, $pipes);

  if (!is_resource ($pod2html)) {
    die ("Unable to start pod2html");
  } // if

  $stdin	= $pipes [0];
  $stdout	= $pipes [1];
  $stderr	= $pipes [2];

  $contents = getSCMFile ($file);

  // Write to stdin
  foreach ($contents as $line) {
    fwrite ($stdin, $line);
  } // foreach
  fclose ($stdin);

  $raw_html = stream_get_contents ($stdout);
  fclose ($stdout);
  fclose ($stderr);
  proc_close ($pod2html);

  // Extract body content if pod2html emitted a full XHTML document
  if (preg_match ('/<body[^>]*>(.*)<\/body>/is', $raw_html, $matches)) {
    $raw_html = $matches[1];
  }

  $url_file = urlencode ($file);
  $git_rel  = resolveSCMGitRelPath ($file);
  $url      = "/clearscm/php/scm_man.php?file=$url_file&amp;action=raw";
  $history  = "https://github.com/adefaria/clearscm/commits/main/" . htmlspecialchars ($git_rel, ENT_QUOTES);

  // Rewrite legacy clearscm.com links inside POD HTML blocks
  $raw_html = preg_replace ('#https?://(www\.)?clearscm\.com/php/scm_man\.php#i', '/clearscm/php/scm_man.php', $raw_html);
  $raw_html = preg_replace ('#https?://(www\.)?clearscm\.com/#i', '/clearscm/', $raw_html);

  $lines = explode ("\n", $raw_html);
  foreach ($lines as $line) {
    // Filter CVS keywords properly
    $line = preg_replace ("/\\\$Revision\:\s*(\S*)\s*\\\$/",
                          "Revision <a href=\"$history\" target=\"_blank\">$1</a>",
                          $line);
    $line = preg_replace ("/\\\$Date\:\s*(.*)\s*\\\$/",
                          "Modified $1",
                          $line);
    $line = preg_replace ("/\\\$RCSfile\:\s*(\S*),v\s*\\\$/",
                          "$1",
                          $line);

    $line = preg_replace ("/<pre>/",
                          "<div class=code><pre>",
                          $line);
    $line = preg_replace ("/<\/pre>/",
                          "</pre></div>",
                          $line);
    $line = preg_replace ("/<a name=.*>(.*)<\/a>/",
                          "$1",
                          $line);
    $line = preg_replace ("/NAME (\S*)<\/h1>/",
                          "NAME $1 <a href=\"$url\"><img src=\"/clearscm/Icons/Download.jpg\" border=0 title=Download style=\"vertical-align:middle;margin-left:6px;\"></a></h1>",
                          $line);
    $line = preg_replace ("/NAME (\S*)<\/h2>/",
                          "NAME $1 <a href=\"$url\"><img src=\"/clearscm/Icons/Download.jpg\" border=0 title=Download style=\"vertical-align:middle;margin-left:6px;\"></a></h2>",
                          $line);
    echo $line . "\n";
  }
} // scm_man
?>
