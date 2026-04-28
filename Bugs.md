# Bugs and Todo List

Use this file to track bugs, issues, and feature requests.

## Open

* In MAPS > Returned report, when clicking the sequence number link to nuke a domain, the Returned report is redisplayed incorrectly (ignores the date filter and displays all entries).
* When nuking a domain from the web interface, it adds the comment "Nuked from web interface". It should not set the comment.

## Closed

* **Top 20 display showed doubled prev/next buttons and copyright** — `ListDomains.php` was calling `copyright()` which rendered a full footer inside the iframe; the outer shell already renders its own footer. Removed the redundant `copyright(2001)` call from `ListDomains.php`.
* **Content not scrollable — Totals row and bottom buttons hidden when window is short** — The shell's `position: fixed` footer was overlapping the bottom of the iframe. Added `--footer-height: 44px` CSS variable and subtracted it from `.app-container` height so the iframe's bottom edge sits above the footer. Also added `overflow-y: auto` to MAPS page body.
* **List.php bottom Export/Import buttons misaligned with top toolbar** — Bottom buttons were `align="right"` with a magic `padding-right: 120px` offset. Changed to use the same `class="toolbar" align="center"` as the top Add/Delete/Modify/Reset bar. Also fixed a missing `</div>` closing tag for `#highlightrow`.
