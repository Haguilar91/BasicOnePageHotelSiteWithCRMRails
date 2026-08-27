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

  async function compressFileList(fileList) {
    const files = await Promise.all(Array.from(fileList).map(compressImageFile));
    const transfer = new DataTransfer();
    files.forEach((file) => transfer.items.add(file));
    return transfer.files;
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

      compressFileList(input.files).then((compressed) => {
        input.files = compressed;
        input.dataset.imageCompressed = 'true';
        input.dispatchEvent(new Event('change', { bubbles: true }));
      });
    },
    true
  );
})();
