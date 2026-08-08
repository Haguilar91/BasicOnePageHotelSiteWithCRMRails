// Infinite announcement ticker
document.addEventListener('DOMContentLoaded', function() {
  const announcement = document.getElementById('announcement-ticker');
  
  if (announcement) {
    const text = announcement.getAttribute('data-text');
    const speed = parseInt(announcement.getAttribute('data-speed')) || 50;
    
    // Create a clone for the animation
    const ticker = document.createElement('div');
    ticker.className = 'ticker-content';
    ticker.innerHTML = `<span>${text}</span>`;
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
  let position = 0;
  const content = element.querySelector('span');
  const containerWidth = container.offsetWidth;
  const contentWidth = content.offsetWidth;
  
  function animate() {
    position -= 1; // Scroll speed
    
    if (position <= -contentWidth) {
      position = 0;
    }
    
    element.style.transform = `translateX(${position}px)`;
    requestAnimationFrame(animate);
  }
  
  animate();
  
  // Handle window resize
  window.addEventListener('resize', function() {
    // Reset when resizing to prevent misalignment
    position = 0;
  });
}