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

    // Build "Title: Description" for each announcement, title in bold,
    // separated with a bullet so multiple announcements read cleanly.
    const html = items
      .map(item => `<strong>${escapeHtml(item.title)}</strong>: ${escapeHtml(item.description)}`)
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
  const contentWidth = content.offsetWidth;
  let position = containerWidth;
  const pixelsPerFrame = speed / 60;

  function animate() {
    position -= pixelsPerFrame;

    if (position <= -contentWidth) {
      position = containerWidth;
    }

    element.style.transform = `translateX(${position}px)`;
    requestAnimationFrame(animate);
  }

  animate();

  window.addEventListener('resize', function() {
    containerWidth = container.offsetWidth;
    position = containerWidth;
  });
}