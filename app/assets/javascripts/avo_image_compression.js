// Client-side image compression for Avo's admin file inputs — re-encodes
// large JPEG/WEBP photos (and PNGs with no real transparency, e.g. a photo
// exported as PNG) down to a much smaller file before it ever leaves the
// browser, at the same resolution and a high-quality setting. This is what
// actually fixes slow/failing uploads over a weak connection: by the time
// Rails' direct-upload JS or the plain multipart form reads `input.files`,
// the bytes are already small. (A CompressImageJob also runs server-side as
// a safety net for anything that slips past this, e.g. HEIC photos a
// browser can't decode into a canvas — see app/jobs/compress_image_job.rb.)
//
// Intercepts every file input's 'change' event at the document's capturing
// phase — which the DOM spec guarantees runs before any listener bound
// directly to the input itself (Avo's gallery-accumulation script, the
// clear-input Stimulus controller, Rails' direct-upload listener) — swaps
// in compressed File objects, then re-dispatches a fresh 'change' event so
// those other listeners see the smaller files. A `data-image-compressed`
// flag on the input marks that redispatched event so it isn't reprocessed.
(function () {
  const MIN_BYTES_TO_COMPRESS = 400 * 1024;
  const JPEG_QUALITY = 0.85;
  const COMPRESSIBLE_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

  function hasRealTransparency(bitmap) {
    const maxDim = 200;
    const scale = Math.min(1, maxDim / Math.max(bitmap.width, bitmap.height));
    const w = Math.max(1, Math.round(bitmap.width * scale));
    const h = Math.max(1, Math.round(bitmap.height * scale));

    const canvas = document.createElement('canvas');
    canvas.width = w;
    canvas.height = h;
    canvas.getContext('2d').drawImage(bitmap, 0, 0, w, h);

    const { data } = canvas.getContext('2d').getImageData(0, 0, w, h);
    for (let i = 3; i < data.length; i += 4) {
      if (data[i] < 255) return true;
    }
    return false;
  }

  async function compressImageFile(file) {
    if (!COMPRESSIBLE_TYPES.includes(file.type)) return file;
    if (file.size < MIN_BYTES_TO_COMPRESS) return file;

    let bitmap;
    try {
      bitmap = await createImageBitmap(file, { imageOrientation: 'from-image' });

      if (file.type !== 'image/jpeg' && hasRealTransparency(bitmap)) {
        return file; // keep logos/icons with an alpha channel untouched
      }

      const canvas = document.createElement('canvas');
      canvas.width = bitmap.width;
      canvas.height = bitmap.height;
      canvas.getContext('2d').drawImage(bitmap, 0, 0);

      const blob = await new Promise((resolve) => canvas.toBlob(resolve, 'image/jpeg', JPEG_QUALITY));
      if (!blob || blob.size >= file.size) return file;

      const newName = file.name.replace(/\.\w+$/, '') + '.jpg';
      return new File([blob], newName, { type: 'image/jpeg', lastModified: file.lastModified });
    } catch (e) {
      return file; // undecodable in-browser (e.g. HEIC) — leave it, the server-side pass will handle it
    } finally {
      bitmap?.close?.();
    }
  }

  // Compress one at a time rather than Promise.all — three full-size photos
  // decoded into canvases simultaneously is a real memory spike on a phone or
  // an older laptop, and sequential lets us report honest "2 / 3" progress.
  async function compressFileList(fileList, onProgress) {
    const input = Array.from(fileList);
    const out = [];
    for (let i = 0; i < input.length; i++) {
      onProgress(i, input.length);
      out.push(await compressImageFile(input[i]));
    }
    const transfer = new DataTransfer();
    out.forEach((file) => transfer.items.add(file));
    return transfer.files;
  }

  // While compression is in flight the file input still holds the ORIGINAL
  // files, so a guest-speed "pick photos, immediately hit Guardar" would post
  // the full uncompressed batch — the exact slow upload this script exists to
  // prevent. Disable the form's submit buttons (a disabled button cannot
  // submit) and belt-and-suspenders block the submit event itself until every
  // pending compression on that form has settled.
  const busyForms = new Set();

  function setFormBusy(form, busy) {
    if (!form) return;
    if (busy) busyForms.add(form);
    else busyForms.delete(form);

    form.querySelectorAll('button[type="submit"], input[type="submit"]').forEach((button) => {
      button.disabled = busy;
      button.style.opacity = busy ? '0.5' : '';
      button.style.cursor = busy ? 'progress' : '';
    });
  }

  document.addEventListener(
    'submit',
    (event) => {
      if (!busyForms.has(event.target)) return;
      event.preventDefault();
      event.stopImmediatePropagation();
    },
    true
  );

  // Without this the admin sees nothing at all for several seconds after
  // picking files — the thumbnail previews only render once we re-dispatch
  // 'change' — which reads as "it didn't take" and invites a second click.
  function statusElementFor(input) {
    const host = input.closest('[data-gallery-upload]') || input.parentElement;
    let el = host.querySelector('[data-compression-status]');
    if (!el) {
      el = document.createElement('p');
      el.setAttribute('data-compression-status', '');
      el.style.cssText = 'margin-top:0.5rem;font-size:0.8rem;font-weight:600;';
      host.appendChild(el);
    }
    return el;
  }

  document.addEventListener(
    'change',
    (event) => {
      const input = event.target;
      if (!(input instanceof HTMLInputElement) || input.type !== 'file') return;

      if (input.dataset.imageCompressed) {
        delete input.dataset.imageCompressed;
        return;
      }
      if (!input.files || !input.files.length) return;
      const needsCompression = Array.from(input.files).some(
        (f) => COMPRESSIBLE_TYPES.includes(f.type) && f.size >= MIN_BYTES_TO_COMPRESS
      );
      if (!needsCompression) return;

      event.stopImmediatePropagation();

      const form = input.form;
      const status = statusElementFor(input);
      setFormBusy(form, true);

      compressFileList(input.files, (done, total) => {
        status.textContent = `Optimizando imágenes para subirlas más rápido… (${done + 1} de ${total})`;
      })
        .then((compressed) => {
          input.files = compressed;
          input.dataset.imageCompressed = 'true';
          input.dispatchEvent(new Event('change', { bubbles: true }));
          status.textContent = 'Imágenes optimizadas. Ya puedes guardar.';
        })
        .catch(() => {
          status.textContent = '';
        })
        .finally(() => {
          setFormBusy(form, false);
        });
    },
    true
  );
})();
