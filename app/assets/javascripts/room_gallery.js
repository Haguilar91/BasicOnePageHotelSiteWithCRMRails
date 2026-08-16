// Per-room photo carousel on the room cards, plus a shared lightbox modal
// that opens the full gallery for whichever room was clicked.
document.addEventListener('DOMContentLoaded', function () {
  const galleries = document.querySelectorAll('[data-room-gallery]');
  if (!galleries.length) return;

  const modal = document.querySelector('[data-room-gallery-modal]');
  const modalImage = modal ? modal.querySelector('[data-room-gallery-modal-image]') : null;
  const modalTitle = modal ? modal.querySelector('[data-room-gallery-modal-title]') : null;
  const modalCounter = modal ? modal.querySelector('[data-room-gallery-modal-counter]') : null;

  let modalPhotos = [];
  let modalTitleText = '';
  let modalIndex = 0;

  function updateCard(gallery) {
    const photos = gallery._photos;
    const index = gallery._index;
    const track = gallery.querySelector('.room-gallery-track');
    if (track) {
      track.style.transform = `translateX(-${index * (100 / photos.length)}%)`;
    }
    gallery.querySelectorAll('[data-room-gallery-dots] .room-gallery-dot').forEach((dot, i) => {
      dot.classList.toggle('bg-white', i === index);
      dot.classList.toggle('bg-white/40', i !== index);
    });
  }

  function updateModal() {
    if (!modal || !modalPhotos.length) return;
    modalImage.src = modalPhotos[modalIndex];
    modalImage.alt = modalTitleText;
    modalTitle.textContent = modalTitleText;
    const hasMultiple = modalPhotos.length > 1;
    modalCounter.textContent = hasMultiple ? `${modalIndex + 1} / ${modalPhotos.length}` : '';
    const prevBtn = modal.querySelector('[data-room-gallery-modal-prev]');
    const nextBtn = modal.querySelector('[data-room-gallery-modal-next]');
    if (prevBtn) prevBtn.classList.toggle('hidden', !hasMultiple);
    if (nextBtn) nextBtn.classList.toggle('hidden', !hasMultiple);
  }

  function openModal(photos, title, startIndex) {
    if (!modal || !photos.length) return;
    modalPhotos = photos;
    modalTitleText = title;
    modalIndex = startIndex || 0;
    updateModal();
    modal.classList.remove('hidden');
    modal.classList.add('flex');
    document.body.style.overflow = 'hidden';
  }

  function closeModal() {
    if (!modal) return;
    modal.classList.add('hidden');
    modal.classList.remove('flex');
    document.body.style.overflow = '';
  }

  // Lets touch users flip images by swiping left/right, on both the card
  // carousel and the modal. Only treated as a swipe once horizontal drag
  // clearly outweighs vertical, so a normal page-scroll gesture over a card
  // still scrolls the page instead of getting hijacked.
  function addSwipe(el, onPrev, onNext) {
    let startX = null;
    let startY = null;
    let swiping = false;

    el.addEventListener('touchstart', (e) => {
      const t = e.touches[0];
      startX = t.clientX;
      startY = t.clientY;
      swiping = false;
    }, { passive: true });

    el.addEventListener('touchmove', (e) => {
      if (startX === null) return;
      const t = e.touches[0];
      const dx = t.clientX - startX;
      const dy = t.clientY - startY;
      if (!swiping && Math.abs(dx) > 12 && Math.abs(dx) > Math.abs(dy)) {
        swiping = true;
      }
      if (swiping) e.preventDefault();
    }, { passive: false });

    el.addEventListener('touchend', (e) => {
      if (swiping && startX !== null) {
        const dx = e.changedTouches[0].clientX - startX;
        const threshold = 40;
        if (dx <= -threshold) onNext();
        else if (dx >= threshold) onPrev();
      }
      startX = null;
      startY = null;
      swiping = false;
    });
  }

  galleries.forEach((gallery) => {
    let photos = [];
    try {
      photos = JSON.parse(gallery.getAttribute('data-photos') || '[]');
    } catch (e) {
      photos = [];
    }
    gallery._photos = photos;
    gallery._index = 0;

    const roomName = gallery.getAttribute('data-room-name') || '';

    const prevBtn = gallery.querySelector('[data-room-gallery-prev]');
    const nextBtn = gallery.querySelector('[data-room-gallery-next]');

    if (prevBtn) {
      prevBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        gallery._index = (gallery._index - 1 + photos.length) % photos.length;
        updateCard(gallery);
      });
    }

    if (nextBtn) {
      nextBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        gallery._index = (gallery._index + 1) % photos.length;
        updateCard(gallery);
      });
    }

    if (photos.length > 1) {
      addSwipe(
        gallery,
        () => { gallery._index = (gallery._index - 1 + photos.length) % photos.length; updateCard(gallery); },
        () => { gallery._index = (gallery._index + 1) % photos.length; updateCard(gallery); }
      );
    }

    gallery.querySelectorAll('[data-room-gallery-dots] .room-gallery-dot').forEach((dot) => {
      dot.addEventListener('click', (e) => {
        e.stopPropagation();
        gallery._index = parseInt(dot.getAttribute('data-index'), 10) || 0;
        updateCard(gallery);
      });
    });

    gallery.querySelectorAll('[data-room-gallery-open]').forEach((img) => {
      img.addEventListener('click', () => {
        openModal(gallery._photos, roomName, gallery._index);
      });
    });
  });

  if (modal) {
    const showModalPrev = () => {
      modalIndex = (modalIndex - 1 + modalPhotos.length) % modalPhotos.length;
      updateModal();
    };
    const showModalNext = () => {
      modalIndex = (modalIndex + 1) % modalPhotos.length;
      updateModal();
    };

    modal.querySelector('[data-room-gallery-close]').addEventListener('click', closeModal);
    modal.querySelector('[data-room-gallery-modal-prev]').addEventListener('click', showModalPrev);
    modal.querySelector('[data-room-gallery-modal-next]').addEventListener('click', showModalNext);
    addSwipe(modal, showModalPrev, showModalNext);

    // Click on the backdrop itself (not the image, caption, or any button)
    // closes the modal.
    modal.addEventListener('click', (e) => {
      if (e.target === modal) closeModal();
    });

    document.addEventListener('keydown', (e) => {
      if (modal.classList.contains('hidden')) return;
      if (e.key === 'Escape') closeModal();
      if (e.key === 'ArrowLeft') showModalPrev();
      if (e.key === 'ArrowRight') showModalNext();
    });
  }
});
