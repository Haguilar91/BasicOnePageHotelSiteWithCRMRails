// Wires up the "Translate" buttons on the Translations admin panel. Each
// click posts the visible Spanish text to /translations/translate and fills
// the adjacent English field — it never saves by itself, the admin still
// has to review and hit the page's own Save button.
document.addEventListener('DOMContentLoaded', function () {
  const form = document.querySelector('[data-translations-form]');
  if (!form) return;

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

  async function translateText(text, multiline) {
    const response = await fetch('/translations/translate', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        Accept: 'application/json'
      },
      body: JSON.stringify({ text, multiline })
    });

    const data = await response.json();
    if (!response.ok) throw new Error(data.error || 'translate failed');
    return data.translated;
  }

  function setButtonState(button, state) {
    if (state === 'loading') {
      button.dataset.originalText = button.dataset.originalText || button.textContent;
      button.textContent = '…';
      button.disabled = true;
    } else if (state === 'error') {
      button.textContent = '⚠';
      button.disabled = false;
      setTimeout(() => {
        button.textContent = button.dataset.originalText;
      }, 2000);
    } else {
      button.textContent = button.dataset.originalText || button.textContent;
      button.disabled = false;
    }
  }

  async function translateField(button) {
    const row = button.closest('[data-translate-row]');
    const source = row.querySelector('[data-translate-source]');
    const target = row.querySelector('[data-translate-target]');
    const text = source.value;
    if (!text.trim()) return;

    setButtonState(button, 'loading');
    try {
      target.value = await translateText(text, button.dataset.multiline === 'true');
      setButtonState(button, 'done');
    } catch (e) {
      setButtonState(button, 'error');
    }
  }

  form.addEventListener('click', (e) => {
    const fieldButton = e.target.closest('[data-translate-field]');
    if (fieldButton) {
      translateField(fieldButton);
      return;
    }

    const sectionButton = e.target.closest('[data-translate-section]');
    if (sectionButton) {
      // Nested inside <summary> — stop it from also toggling the
      // <details> open/closed state.
      e.preventDefault();
      e.stopPropagation();

      const details = sectionButton.closest('details');
      const emptyFieldButtons = Array.from(details.querySelectorAll('[data-translate-field]')).filter((btn) => {
        const target = btn.closest('[data-translate-row]').querySelector('[data-translate-target]');
        return !target.value.trim();
      });
      emptyFieldButtons.forEach(translateField);
    }
  });
});
