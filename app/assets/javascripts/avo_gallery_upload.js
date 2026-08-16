// Lets an Avo admin pick (or drag-and-drop) files across multiple rounds —
// e.g. one folder at a time — and have them all accumulate into a single
// pending batch that gets submitted together on save, instead of each new
// pick silently replacing the last (the native behavior of
// <input type="file" multiple">). Paired with RoomPhotosUploadEditComponent.
//
// Native file inputs already accept drag-and-drop on their own (no custom
// dragover/drop wiring needed): Avo's file-upload-input markup covers the
// whole dropzone with an invisible <input type="file">, so a drop lands
// straight on the input and fires the same `change` event as picking via
// the dialog.
(function () {
  function initGalleryUpload(container) {
    if (container.dataset.galleryUploadReady) return;
    container.dataset.galleryUploadReady = 'true';

    const input = container.querySelector('[data-gallery-input]');
    const pendingEl = container.querySelector('[data-gallery-pending]');
    const clearBtn = container.querySelector('[data-gallery-clear]');
    if (!input || !pendingEl) return;

    let files = []; // [{ file, url }]

    function render() {
      pendingEl.innerHTML = '';

      files.forEach(({ file, url }, index) => {
        const item = document.createElement('div');
        item.className = 'gallery-upload__pending-item';

        if (url) {
          const img = document.createElement('img');
          img.src = url;
          img.alt = file.name;
          item.appendChild(img);
        }

        const name = document.createElement('span');
        name.className = 'gallery-upload__pending-name';
        name.textContent = file.name;
        item.appendChild(name);

        const removeBtn = document.createElement('button');
        removeBtn.type = 'button';
        removeBtn.className = 'gallery-upload__pending-remove';
        removeBtn.setAttribute('aria-label', `Quitar ${file.name}`);
        removeBtn.textContent = '×';
        removeBtn.addEventListener('click', () => removeFile(index));
        item.appendChild(removeBtn);

        pendingEl.appendChild(item);
      });

      if (clearBtn) clearBtn.classList.toggle('hidden', files.length === 0);
    }

    function syncInput() {
      const transfer = new DataTransfer();
      files.forEach(({ file }) => transfer.items.add(file));
      input.files = transfer.files;
    }

    function removeFile(index) {
      const [removed] = files.splice(index, 1);
      if (removed && removed.url) URL.revokeObjectURL(removed.url);
      syncInput();
      render();
    }

    function addFiles(fileList) {
      Array.from(fileList).forEach((file) => {
        const isDuplicate = files.some(
          ({ file: existing }) =>
            existing.name === file.name &&
            existing.size === file.size &&
            existing.lastModified === file.lastModified
        );
        if (isDuplicate) return;
        const url = file.type.startsWith('image/') ? URL.createObjectURL(file) : null;
        files.push({ file, url });
      });
      syncInput();
      render();
    }

    input.addEventListener('change', () => {
      if (input.files.length) addFiles(input.files);
    });

    if (clearBtn) {
      clearBtn.addEventListener('click', () => {
        files.forEach(({ url }) => { if (url) URL.revokeObjectURL(url); });
        files = [];
        syncInput();
        render();
      });
    }
  }

  function initAll() {
    document.querySelectorAll('[data-gallery-upload]').forEach(initGalleryUpload);
  }

  // Avo navigates with Turbo Drive, which replaces the document without
  // firing DOMContentLoaded again — turbo:load covers every navigation
  // (including the first). DOMContentLoaded stays as a fallback.
  document.addEventListener('DOMContentLoaded', initAll);
  document.addEventListener('turbo:load', initAll);
})();
