////////////////////////////////////////////////////////////////////////////////
//
// File:        QuickStats.js
// Description: Dynamic polling, mechanical split-flap counters (counts and
//              percentages), and live ticking flip clock for MAPS Quick Stats.
//
////////////////////////////////////////////////////////////////////////////////
(function () {
  'use strict';

  var POLL_INTERVAL_MS = 15000;
  var FLIP_DURATION_MS = 500;
  var DIGIT_STAGGER_MS = 45;

  var STAT_KEYS = [
    'processed',
    'nulllist',
    'auth_failed',
    'returned',
    'whitelist',
    'blacklist',
    'registered'
  ];

  var LABEL_TEXT = {
    processed: 'Processed',
    nulllist: 'Null',
    auth_failed: 'Auth\u00A0Failed',
    returned: 'Returned',
    whitelist: 'White',
    blacklist: 'Black',
    registered: 'Registered'
  };

  var NO_PCT_KEYS = {
    processed: true,
    registered: true
  };

  var reducedMotionQuery =
    window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)');

  function prefersReducedMotion() {
    return !!(reducedMotionQuery && reducedMotionQuery.matches);
  }

  function createDigitElement(initialChar) {
    var ch = initialChar == null ? '' : String(initialChar);
    var digit = document.createElement('span');
    digit.className = 'flip-digit';
    digit.dataset.digit = ch;

    var top = document.createElement('span');
    top.className = 'flip-card flip-top';
    var topText = document.createElement('span');
    topText.textContent = ch;
    top.appendChild(topText);

    var bottom = document.createElement('span');
    bottom.className = 'flip-card flip-bottom';
    var bottomText = document.createElement('span');
    bottomText.textContent = ch;
    bottom.appendChild(bottomText);

    var flapTop = document.createElement('span');
    flapTop.className = 'flip-flap flip-flap-top';
    var flapTopText = document.createElement('span');
    flapTopText.textContent = ch;
    flapTop.appendChild(flapTopText);

    var flapBottom = document.createElement('span');
    flapBottom.className = 'flip-flap flip-flap-bottom';
    var flapBottomText = document.createElement('span');
    flapBottomText.textContent = ch;
    flapBottom.appendChild(flapBottomText);

    digit.appendChild(top);
    digit.appendChild(bottom);
    digit.appendChild(flapTop);
    digit.appendChild(flapBottom);

    digit._refs = {
      topText: topText,
      bottomText: bottomText,
      flapTopText: flapTopText,
      flapBottomText: flapBottomText
    };
    digit._flipTimer = null;
    digit._pendingChar = null;

    return digit;
  }

  function setDigitImmediate(digitEl, newChar) {
    var ch = newChar == null ? '' : String(newChar);
    var refs = digitEl._refs;
    if (digitEl._flipTimer) {
      clearTimeout(digitEl._flipTimer);
      digitEl._flipTimer = null;
    }
    digitEl._pendingChar = null;
    digitEl.classList.remove('is-flipping');
    digitEl.dataset.digit = ch;
    refs.topText.textContent = ch;
    refs.bottomText.textContent = ch;
    refs.flapTopText.textContent = ch;
    refs.flapBottomText.textContent = ch;
  }

  function flipDigit(digitEl, newChar, onComplete) {
    var next = newChar == null ? '' : String(newChar);
    var current = digitEl.dataset.digit || '';

    if (current === next) {
      if (typeof onComplete === 'function') {
        onComplete();
      }
      return;
    }

    if (prefersReducedMotion()) {
      setDigitImmediate(digitEl, next);
      if (typeof onComplete === 'function') {
        onComplete();
      }
      return;
    }

    if (digitEl._flipTimer) {
      digitEl._pendingChar = next;
      digitEl._pendingCallback = onComplete || null;
      return;
    }

    var refs = digitEl._refs;
    refs.flapTopText.textContent = current;
    refs.bottomText.textContent = current;
    refs.topText.textContent = next;
    refs.flapBottomText.textContent = next;

    digitEl.classList.remove('is-flipping');
    // Force reflow so CSS keyframes restart cleanly on rapid flips.
    void digitEl.offsetWidth;
    digitEl.classList.add('is-flipping');
    digitEl.dataset.digit = next;

    digitEl._flipTimer = setTimeout(function () {
      refs.bottomText.textContent = next;
      refs.flapTopText.textContent = next;
      digitEl.classList.remove('is-flipping');
      digitEl._flipTimer = null;

      if (digitEl._pendingChar !== null) {
        var queued = digitEl._pendingChar;
        var queuedCb = digitEl._pendingCallback;
        digitEl._pendingChar = null;
        digitEl._pendingCallback = null;
        flipDigit(digitEl, queued, queuedCb);
      } else if (typeof onComplete === 'function') {
        onComplete();
      }
    }, FLIP_DURATION_MS);
  }

  function FlipDigitsGroup(containerEl, initialStr) {
    this.container = containerEl;
    this.str = '';
    this.setString(initialStr, false);
  }

  FlipDigitsGroup.prototype.setString = function (newStr, animate, staggerOffset) {
    var target = String(newStr);
    var oldStr = this.str;
    this.str = target;

    if (!animate || oldStr === '') {
      this.container.textContent = '';
      for (var i = 0; i < target.length; i++) {
        this.container.appendChild(createDigitElement(target.charAt(i)));
      }
      return 0;
    }

    if (oldStr === target) {
      return 0;
    }

    var existing = Array.prototype.slice.call(this.container.children);
    var maxLen = Math.max(existing.length, target.length);

    while (existing.length < maxLen) {
      var leadingTile = createDigitElement('');
      this.container.insertBefore(leadingTile, this.container.firstChild);
      existing.unshift(leadingTile);
    }

    var paddedNew = target;
    while (paddedNew.length < maxLen) {
      paddedNew = ' ' + paddedNew;
    }

    var baseOffset = staggerOffset || 0;
    var flippedCount = 0;
    for (var pos = maxLen - 1; pos >= 0; pos--) {
      (function (tile, targetChar, delay) {
        var normalizedTarget = targetChar === ' ' ? '' : targetChar;
        var currentChar = tile.dataset.digit || '';

        if (currentChar === normalizedTarget) {
          if (normalizedTarget === '' && tile.parentNode) {
            tile.parentNode.removeChild(tile);
          }
          return;
        }

        var runFlip = function () {
          flipDigit(tile, normalizedTarget, function () {
            if (normalizedTarget === '' && tile.parentNode) {
              tile.parentNode.removeChild(tile);
            }
          });
        };

        if (delay > 0 && !prefersReducedMotion()) {
          setTimeout(runFlip, delay);
        } else {
          runFlip();
        }
      })(existing[pos], paddedNew.charAt(pos), (baseOffset + flippedCount) * DIGIT_STAGGER_MS);

      var cur = existing[pos].dataset.digit || '';
      var nxt = paddedNew.charAt(pos) === ' ' ? '' : paddedNew.charAt(pos);
      if (cur !== nxt) {
        flippedCount++;
      }
    }

    return flippedCount;
  };

  function FlipCounter(cellEl, initialValue) {
    this.cellEl = cellEl;
    this.value = null;
    this.container = document.createElement('span');
    this.container.className = 'flip-counter';
    this.container.setAttribute('aria-live', 'polite');

    cellEl.textContent = '';
    cellEl.appendChild(this.container);

    this.group = new FlipDigitsGroup(this.container, '0');
    this.setValue(initialValue, false);
  }

  FlipCounter.prototype.setValue = function (newValue, animate) {
    var num = parseInt(newValue, 10);
    if (isNaN(num) || num < 0) {
      num = 0;
    }
    var newStr = String(num);
    this.value = num;
    this.container.setAttribute('aria-label', newStr);
    this.group.setString(newStr, !!animate, 0);
  };

  function FlipPercent(cellEl, initialPctStr) {
    this.cellEl = cellEl;
    this.pctStr = '';

    this.wrapper = document.createElement('span');
    this.wrapper.className = 'flip-counter flip-counter-pct';
    this.wrapper.setAttribute('aria-live', 'polite');

    this.intContainer = document.createElement('span');
    this.intContainer.className = 'flip-counter';

    var dot = document.createElement('span');
    dot.className = 'flip-sep';
    dot.textContent = '.';

    this.decTile = createDigitElement('0');

    var pctSign = document.createElement('span');
    pctSign.className = 'flip-sep';
    pctSign.textContent = '%';

    this.wrapper.appendChild(this.intContainer);
    this.wrapper.appendChild(dot);
    this.wrapper.appendChild(this.decTile);
    this.wrapper.appendChild(pctSign);

    cellEl.textContent = '';
    cellEl.appendChild(this.wrapper);

    this.intGroup = new FlipDigitsGroup(this.intContainer, '0');
    this.setPercent(initialPctStr, false);
  }

  FlipPercent.prototype.setPercent = function (pctValue, animate) {
    var cleaned = String(pctValue == null ? '0.0' : pctValue).replace(/%/g, '').trim();
    var num = parseFloat(cleaned);
    if (isNaN(num) || num < 0) {
      num = 0;
    }
    var formatted = num.toFixed(1);
    var parts = formatted.split('.');
    var intPart = parts[0];
    var decChar = parts[1] || '0';

    if (this.pctStr === formatted && animate) {
      return;
    }
    this.pctStr = formatted;
    this.wrapper.setAttribute('aria-label', formatted + '%');

    if (!animate) {
      this.intGroup.setString(intPart, false, 0);
      setDigitImmediate(this.decTile, decChar);
      return;
    }

    var decChanged = (this.decTile.dataset.digit || '') !== decChar;
    if (decChanged) {
      flipDigit(this.decTile, decChar);
    }
    this.intGroup.setString(intPart, true, decChanged ? 1 : 0);
  };

  function FlipClock(el) {
    this.el = el;
    this.timer = null;

    this.el.textContent = '';

    var prefix = document.createElement('span');
    prefix.textContent = 'as of';

    var clockWrap = document.createElement('span');
    clockWrap.className = 'flip-counter flip-clock';

    this.hourContainer = document.createElement('span');
    this.hourContainer.className = 'flip-counter';

    var colon = document.createElement('span');
    colon.className = 'flip-sep';
    colon.textContent = ':';

    this.minContainer = document.createElement('span');
    this.minContainer.className = 'flip-counter';

    this.ampmEl = document.createElement('span');
    this.ampmEl.className = 'flip-sep flip-ampm';

    clockWrap.appendChild(this.hourContainer);
    clockWrap.appendChild(colon);
    clockWrap.appendChild(this.minContainer);
    clockWrap.appendChild(this.ampmEl);

    this.el.appendChild(prefix);
    this.el.appendChild(clockWrap);

    var now = new Date();
    var parts = this._formatParts(now);

    this.hourGroup = new FlipDigitsGroup(this.hourContainer, parts.hour);
    this.minGroup = new FlipDigitsGroup(this.minContainer, parts.min);
    this.ampmEl.textContent = parts.ampm;

    this.start();
  }

  FlipClock.prototype._formatParts = function (dateObj) {
    var hours24 = dateObj.getHours();
    var ampm = hours24 >= 12 ? 'PM' : 'AM';
    var hours12 = hours24 % 12;
    if (hours12 === 0) {
      hours12 = 12;
    }
    var mins = dateObj.getMinutes();
    return {
      hour: String(hours12),
      min: (mins < 10 ? '0' : '') + mins,
      ampm: ampm
    };
  };

  FlipClock.prototype.tick = function (animate) {
    var parts = this._formatParts(new Date());
    var doAnim = animate !== false;
    this.minGroup.setString(parts.min, doAnim, 0);
    this.hourGroup.setString(parts.hour, doAnim, 0);
    if (this.ampmEl.textContent !== parts.ampm) {
      this.ampmEl.textContent = parts.ampm;
    }
  };

  FlipClock.prototype._scheduleNext = function () {
    var self = this;
    this.stop();
    if (document.hidden) {
      return;
    }
    var msUntilNextMin = 60000 - (Date.now() % 60000);
    if (msUntilNextMin < 50) {
      msUntilNextMin += 60000;
    }
    this.timer = setTimeout(function () {
      if (!document.hidden) {
        self.tick(true);
        self._scheduleNext();
      }
    }, msUntilNextMin);
  };

  FlipClock.prototype.start = function () {
    this.tick(false);
    this._scheduleNext();
  };

  FlipClock.prototype.stop = function () {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  };

  function calcPctString(val, processed) {
    if (!processed || processed <= 0) {
      return '0.0';
    }
    return ((val / processed) * 100).toFixed(1);
  }

  function QuickStatsController(rootEl) {
    this.rootEl = rootEl;
    this.userid = rootEl.getAttribute('data-userid') || '';
    this.date = rootEl.getAttribute('data-date') || '';
    this.asOfEl = document.getElementById('quickstats-asof');
    this.clock = this.asOfEl ? new FlipClock(this.asOfEl) : null;
    this.counters = {};
    this.pctCounters = {};
    this.labelCells = {};
    this.pollTimer = null;
    this.inFlight = false;

    this._init();
  }

  QuickStatsController.prototype._storageKey = function () {
    return 'maps_quickstats_' + (this.userid || 'default') + '_' + (this.date || 'today');
  };

  QuickStatsController.prototype._loadSnapshot = function () {
    try {
      var raw = window.sessionStorage.getItem(this._storageKey());
      return raw ? JSON.parse(raw) : null;
    } catch (e) {
      return null;
    }
  };

  QuickStatsController.prototype._saveSnapshot = function (stats) {
    try {
      window.sessionStorage.setItem(this._storageKey(), JSON.stringify(stats));
    } catch (e) {
      // Ignore storage quota or private-mode errors.
    }
  };

  QuickStatsController.prototype._init = function () {
    var self = this;
    var serverStats = {};

    for (var i = 0; i < STAT_KEYS.length; i++) {
      var key = STAT_KEYS[i];
      var countCell = this.rootEl.querySelector('[data-stat="' + key + '"]');
      var labelCell = this.rootEl.querySelector('[data-stat-label="' + key + '"]');

      if (labelCell) {
        this.labelCells[key] = labelCell;
      }
      if (countCell) {
        var val = parseInt(countCell.textContent.trim(), 10);
        serverStats[key] = isNaN(val) ? 0 : val;
      }
    }

    var previous = this._loadSnapshot();
    var hasDiff = false;
    if (previous) {
      for (var j = 0; j < STAT_KEYS.length; j++) {
        var k = STAT_KEYS[j];
        if (typeof previous[k] === 'number' && previous[k] !== serverStats[k]) {
          hasDiff = true;
          break;
        }
      }
    }

    var initialStats = hasDiff && previous ? previous : serverStats;
    var initialProcessed = initialStats.processed || 0;

    for (var m = 0; m < STAT_KEYS.length; m++) {
      var statKey = STAT_KEYS[m];
      var cell = this.rootEl.querySelector('[data-stat="' + statKey + '"]');
      if (cell) {
        var initialVal =
          typeof initialStats[statKey] === 'number'
            ? initialStats[statKey]
            : serverStats[statKey];
        this.counters[statKey] = new FlipCounter(cell, initialVal);
      }

      if (!NO_PCT_KEYS[statKey]) {
        var pctCell = this.rootEl.querySelector('[data-stat-pct="' + statKey + '"]');
        if (pctCell) {
          var initStatVal =
            typeof initialStats[statKey] === 'number'
              ? initialStats[statKey]
              : serverStats[statKey];
          this.pctCounters[statKey] = new FlipPercent(
            pctCell,
            calcPctString(initStatVal, initialProcessed)
          );
        }
      }
    }

    if (hasDiff) {
      setTimeout(function () {
        self.applyStats(serverStats, true);
      }, 120);
    } else {
      this._saveSnapshot(serverStats);
    }

    this._bindVisibility();
    this.startPolling();
  };

  QuickStatsController.prototype._updateLabelLink = function (key, count) {
    if (key === 'processed') {
      return;
    }
    var cell = this.labelCells[key];
    if (!cell) {
      return;
    }
    var label = LABEL_TEXT[key] || key;
    if (count > 0) {
      var href =
        '/maps/bin/detail.cgi?type=' +
        encodeURIComponent(key) +
        ';date=' +
        encodeURIComponent(this.date);
      var existingLink = cell.querySelector('a');
      if (existingLink) {
        existingLink.setAttribute('href', href);
      } else {
        cell.textContent = '';
        var link = document.createElement('a');
        link.setAttribute('href', href);
        link.textContent = label;
        cell.appendChild(link);
      }
    } else {
      cell.textContent = label;
    }
  };

  QuickStatsController.prototype._updatePercentages = function (stats, animate) {
    var processed = stats.processed || 0;
    for (var i = 0; i < STAT_KEYS.length; i++) {
      var key = STAT_KEYS[i];
      if (NO_PCT_KEYS[key]) {
        continue;
      }
      var pctCounter = this.pctCounters[key];
      if (!pctCounter) {
        continue;
      }
      var val = stats[key] || 0;
      pctCounter.setPercent(calcPctString(val, processed), animate);
    }
  };

  QuickStatsController.prototype.applyStats = function (data, animate) {
    if (!data) {
      return;
    }

    if (data.date && data.date !== this.date) {
      this.date = data.date;
      this.rootEl.setAttribute('data-date', this.date);
      var heading = document.querySelector('.quickstats .todaysactivity');
      if (heading) {
        heading.setAttribute('title', this.date);
      }
    }

    var normalized = {};
    var shouldAnimate = animate !== false;

    for (var i = 0; i < STAT_KEYS.length; i++) {
      var key = STAT_KEYS[i];
      var val = parseInt(data[key], 10);
      if (isNaN(val) || val < 0) {
        val = 0;
      }
      normalized[key] = val;

      if (this.counters[key]) {
        this.counters[key].setValue(val, shouldAnimate);
      }
      this._updateLabelLink(key, val);
    }

    this._updatePercentages(normalized, shouldAnimate);
    this._saveSnapshot(normalized);
  };

  QuickStatsController.prototype.refresh = function () {
    var self = this;
    if (this.inFlight) {
      return Promise.resolve();
    }

    this.inFlight = true;
    var url = '/maps/bin/api.cgi?action=stats';
    if (this.userid) {
      url += '&userid=' + encodeURIComponent(this.userid);
    }

    return fetch(url, {
      method: 'GET',
      credentials: 'include',
      cache: 'no-store'
    })
      .then(function (response) {
        if (!response.ok) {
          throw new Error('HTTP ' + response.status);
        }
        return response.json();
      })
      .then(function (payload) {
        if (payload && payload.status === 'success' && payload.data) {
          self.applyStats(payload.data, true);
        }
      })
      .catch(function (err) {
        if (window.console && console.debug) {
          console.debug('QuickStats poll skipped:', err);
        }
      })
      .finally(function () {
        self.inFlight = false;
      });
  };

  QuickStatsController.prototype.startPolling = function () {
    var self = this;
    this.stopPolling();
    if (document.hidden) {
      return;
    }
    this.pollTimer = setInterval(function () {
      if (!document.hidden) {
        self.refresh();
      }
    }, POLL_INTERVAL_MS);
  };

  QuickStatsController.prototype.stopPolling = function () {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  };

  QuickStatsController.prototype._bindVisibility = function () {
    var self = this;
    document.addEventListener('visibilitychange', function () {
      if (document.hidden) {
        self.stopPolling();
        if (self.clock) {
          self.clock.stop();
        }
      } else {
        if (self.clock) {
          self.clock.start();
        }
        self.refresh();
        self.startPolling();
      }
    });
  };

  QuickStatsController.prototype.demo = function () {
    var self = this;
    var current = {};
    for (var i = 0; i < STAT_KEYS.length; i++) {
      var key = STAT_KEYS[i];
      current[key] = self.counters[key] ? self.counters[key].value : 0;
    }

    // Step 1: simulate a new returned email arriving.
    var step1 = Object.assign({}, current, {
      processed: current.processed + 1,
      returned: current.returned + 1
    });
    self.applyStats(step1, true);

    // Step 2: simulate moving it from Returned to Nulllist.
    setTimeout(function () {
      var step2 = Object.assign({}, step1, {
        returned: Math.max(0, step1.returned - 1),
        nulllist: step1.nulllist + 1
      });
      self.applyStats(step2, true);
    }, 1100);

    // Step 3: resync with real server stats.
    setTimeout(function () {
      self.refresh();
    }, 2600);
  };

  function boot() {
    var rootEl = document.getElementById('quickstats');
    if (!rootEl || rootEl.dataset.quickstatsInit === '1') {
      return;
    }
    rootEl.dataset.quickstatsInit = '1';
    window.MAPSQuickStats = new QuickStatsController(rootEl);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
