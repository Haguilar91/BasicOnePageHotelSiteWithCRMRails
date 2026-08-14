// Infinite announcement ticker
function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

document.addEventListener('DOMContentLoaded', function() {
  const announcement = document.getElementById('announcement-ticker');

  if (announcement) {
    let items = [];
    try {
      items = JSON.parse(announcement.getAttribute('data-announcements') || '[]');
    } catch (e) {
      items = [];
    }
    const speed = parseInt(announcement.getAttribute('data-speed')) || 50;

    if (!items.length) return;

    // Build "Title: Description" for each item, title in bold, separated with
    // a bullet so multiple announcements read cleanly.
    const html = items
      .map(item => {
        const title = `<strong>${escapeHtml(item.title)}</strong>`;
        return item.description ? `${title}: ${escapeHtml(item.description)}` : title;
      })
      .join('&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;');

    // Create a clone for the animation
    const ticker = document.createElement('div');
    ticker.className = 'ticker-content';
    ticker.innerHTML = `<span>${html}</span>`;
    ticker.style.position = 'absolute';
    ticker.style.whiteSpace = 'nowrap';
    ticker.style.top = '0';
    ticker.style.left = '0';

    // Initialize
    announcement.appendChild(ticker);
    startInfiniteScroll(ticker, announcement, speed);
  }
});

function startInfiniteScroll(element, container, speed) {
  const content = element.querySelector('span');
  let containerWidth = container.offsetWidth;
  let contentWidth = content.offsetWidth;
  let position = containerWidth;
  let lastTimestamp = null;

  function animate(timestamp) {
    // Advance by elapsed time rather than a fixed per-frame step, so the
    // scroll runs at the same speed on 60Hz and 120Hz displays. The delta is
    // clamped because backgrounding the tab pauses rAF, and the first frame
    // after returning would otherwise jump the ticker far off-screen.
    if (lastTimestamp === null) lastTimestamp = timestamp;
    const elapsed = Math.min(timestamp - lastTimestamp, 100);
    lastTimestamp = timestamp;

    position -= (speed * elapsed) / 1000;

    if (position <= -contentWidth) {
      position = containerWidth;
    }

    element.style.transform = `translateX(${position}px)`;
    requestAnimationFrame(animate);
  }

  requestAnimationFrame(animate);

  // Only react to genuine width changes. On mobile, scrolling shows/hides the
  // browser chrome, which fires `resize` with a new viewport *height* — and
  // restarting the ticker on those events is what made it jump back to the
  // start whenever the page was scrolled.
  window.addEventListener('resize', function() {
    const newContainerWidth = container.offsetWidth;
    if (newContainerWidth === containerWidth) return;

    containerWidth = newContainerWidth;
    contentWidth = content.offsetWidth;
    if (position > containerWidth) position = containerWidth;
  });
}
