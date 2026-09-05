// Easy Edit: click a pencil icon anywhere on the live site (only rendered
// when session[:easy_edit] is on — see ApplicationHelper#easy_edit_mode?)
// to open a modal with a small form for that record's text/photo fields.
// Saving posts via fetch (multipart, so photo uploads work) and reloads the
// page on success so every place that value appears (e.g. a page_content
// key reused in both the hero and the footer) stays in sync. The modal also
// carries a red trash button for deletable resources — same fetch-and-reload
// flow, behind a confirm().
document.addEventListener('DOMContentLoaded', function () {
  const modal = document.querySelector('[data-easy-edit-modal]');
  if (!modal) return;

  const modalBody = modal.querySelector('[data-easy-edit-modal-body]');
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

  function openModal() {
    modal.classList.remove('hidden');
    modal.classList.add('flex');
    document.body.style.overflow = 'hidden';
  }

  function closeModal() {
    modal.classList.add('hidden');
    modal.classList.remove('flex');
    document.body.style.overflow = '';
    modalBody.innerHTML = '';
  }

  async function loadForm(url) {
    modalBody.innerHTML = '<p class="text-sm text-slate-500 py-8 text-center">Cargando…</p>';
    openModal();

    try {
      const response = await fetch(url, { headers: { Accept: 'text/html' } });
      if (!response.ok) throw new Error('load failed');
      modalBody.innerHTML = await response.text();
    } catch (e) {
      modalBody.innerHTML = '<p class="text-sm text-red-600 py-8 text-center">No se pudo cargar el formulario.</p>';
    }
  }

  async function submitForm(form) {
    const submitBtn = form.querySelector('[data-easy-edit-submit]');
    const errorEl = form.querySelector('[data-easy-edit-error]');
    errorEl.classList.add('hidden');
    submitBtn.disabled = true;
    submitBtn.textContent = 'Guardando…';

    try {
      const response = await fetch(form.action, { method: 'POST', body: new FormData(form), headers: { 'X-CSRF-Token': csrfToken } });
      const data = await response.json();

      if (response.ok && data.ok) {
        window.location.reload();
        return;
      }

      errorEl.textContent = (data.errors || [data.error]).filter(Boolean).join(', ') || 'No se pudo guardar.';
      errorEl.classList.remove('hidden');
    } catch (e) {
      errorEl.textContent = 'No se pudo guardar. Revisa tu conexión.';
      errorEl.classList.remove('hidden');
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Guardar';
    }
  }

  // Deleting only appears for resources flagged `deletable: true` server-side
  // (EasyEditController::MODELS), and the controller re-checks that flag — the
  // confirm() here is the guard rail for the admin, not the security boundary.
  async function deleteRecord(button) {
    const form = button.closest('[data-easy-edit-form]');
    const errorEl = form.querySelector('[data-easy-edit-error]');
    if (!window.confirm(button.dataset.easyEditDeleteConfirm || '¿Eliminar este elemento?')) return;

    errorEl.classList.add('hidden');
    button.disabled = true;

    try {
      const response = await fetch(button.dataset.easyEditDeleteUrl, {
        method: 'DELETE',
        headers: { 'X-CSRF-Token': csrfToken, Accept: 'application/json' }
      });
      const data = await response.json();

      if (response.ok && data.ok) {
        window.location.reload();
        return;
      }

      errorEl.textContent = (data.errors || [data.error]).filter(Boolean).join(', ') || 'No se pudo eliminar.';
      errorEl.classList.remove('hidden');
    } catch (e) {
      errorEl.textContent = 'No se pudo eliminar. Revisa tu conexión.';
      errorEl.classList.remove('hidden');
    } finally {
      button.disabled = false;
    }
  }

  document.addEventListener('click', (e) => {
    const trigger = e.target.closest('[data-easy-edit-trigger]');
    if (trigger) {
      e.preventDefault();
      const resource = trigger.dataset.easyEditResource;
      const id = trigger.dataset.easyEditId;
      loadForm(`/easy_edit/${resource}/${encodeURIComponent(id)}/edit`);
    }
  });

  modal.addEventListener('click', (e) => {
    const deleteButton = e.target.closest('[data-easy-edit-delete]');
    if (deleteButton) {
      deleteRecord(deleteButton);
      return;
    }

    if (e.target === modal || e.target.closest('[data-easy-edit-modal-close]')) {
      closeModal();
    }
  });

  modal.addEventListener('submit', (e) => {
    if (e.target.matches('[data-easy-edit-form]')) {
      e.preventDefault();
      submitForm(e.target);
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !modal.classList.contains('hidden')) closeModal();
  });
});
