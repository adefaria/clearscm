# Bugs and Todo List

Use this file to track bugs, issues, and feature requests.

## Open

## Closed

* **Error dialog consistency** — When adding items or checking addresses, invalid input previously triggered basic browser alert dialogs. Updated `ListActions.js` and `CheckAddress.js` to use the consistent inline modal (`showModal`) across all client-side validation logic. Also globally included `MAPSUtils.js` to ensure the modal functions are available anywhere they're needed.

* **Inline dialog whitelist link navigation failure** — When clicking the sequence link in the "Can you email me" inline dialog, it would fail to display the corresponding whitelist sequence. Fixed to properly calculate the sequence row offset and use the SPA router (activateTab) to seamlessly navigate the iframe.
* **Returned report redisplayed incorrectly** — In MAPS > Returned report, when clicking the sequence number link to nuke a domain, the Returned report was redisplayed incorrectly (ignoring the date filter and displaying all entries).
* **Nuked from web interface comment** — When nuking a domain from the web interface, it was adding the comment "Nuked from web interface". Fixed so it no longer sets this comment.
* **Top 20 display showed doubled prev/next buttons and copyright** — `ListDomains.php` was calling `copyright()` which rendered a full footer inside the iframe; the outer shell already renders its own footer. Removed the redundant `copyright(2001)` call from `ListDomains.php`.
* **Content not scrollable — Totals row and bottom buttons hidden when window is short** — The shell's `position: fixed` footer was overlapping the bottom of the iframe. Added `--footer-height: 44px` CSS variable and subtracted it from `.app-container` height so the iframe's bottom edge sits above the footer. Also added `overflow-y: auto` to MAPS page body.
* **List.php bottom Export/Import buttons misaligned with top toolbar** — Bottom buttons were `align="right"` with a magic `padding-right: 120px` offset. Changed to use the same `class="toolbar" align="center"` as the top Add/Delete/Modify/Reset bar. Also fixed a missing `</div>` closing tag for `#highlightrow`.
