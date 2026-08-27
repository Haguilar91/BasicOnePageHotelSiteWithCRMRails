// "Book Now" modal — collects guest name, stay dates, guests/room
// preference, and a callback phone number, then hands that off as a single
// message to whichever channel the guest picks: WhatsApp (opens a chat to
// the hotel's number) or Email (opens a mailto to the hotel's stored
// contact_email). Triggers may carry data-book-channel to focus the
// matching send button when the modal opens (e.g. the CTA section's "Send
// WhatsApp"/"Send Email" buttons).
document.addEventListener('DOMContentLoaded', function () {
  const modal = document.querySelector('[data-booking-modal]');
  if (!modal) return;

  const openTriggers = document.querySelectorAll('[data-book-modal-open]');
  const form = modal.querySelector('[data-booking-form]');
  const guestNameInput = form.querySelector('#booking-guest-name');
  const checkinInput = form.querySelector('#booking-checkin');
  const checkoutInput = form.querySelector('#booking-checkout');
  const guestsSelect = form.querySelector('#booking-guests');
  const roomTypeSelect = form.querySelector('#booking-room-type');
  const countryCodeSelect = form.querySelector('#booking-country-code');
  const phoneInput = form.querySelector('#booking-contact-phone');
  const sendButtons = form.querySelectorAll('[data-booking-send]');

  const phone = modal.dataset.phone || '';
  const email = modal.dataset.email || '';
  const emailSubject = modal.dataset.emailSubject || '';
  const messageTemplate = modal.dataset.messageTemplate || '';
  const roomTypeAny = modal.dataset.roomTypeAny || '';
  const locale = modal.dataset.locale === 'en' ? 'en-US' : 'es-MX';

  const today = new Date().toISOString().slice(0, 10);
  checkinInput.min = today;

  function openModal(preselectChannel, preselectRoom) {
    const roomMatch = preselectRoom
      ? Array.from(roomTypeSelect.options).find((option) => option.value === preselectRoom)
      : null;
    roomTypeSelect.value = roomMatch ? roomMatch.value : '';

    modal.classList.remove('hidden');
    modal.classList.add('flex');
    document.body.style.overflow = 'hidden';

    const focusButton = preselectChannel
      ? form.querySelector(`[data-booking-send="${preselectChannel}"]`)
      : null;
    (focusButton || guestNameInput).focus();
  }

  function closeModal() {
    modal.classList.add('hidden');
    modal.classList.remove('flex');
    document.body.style.overflow = '';
  }

  function formatDate(value) {
    if (!value) return value;
    const [year, month, day] = value.split('-').map(Number);
    const date = new Date(year, month - 1, day);
    return new Intl.DateTimeFormat(locale, { day: 'numeric', month: 'long', year: 'numeric' }).format(date);
  }

  function currentContact() {
    return `${countryCodeSelect.value} ${phoneInput.value.trim()}`.trim();
  }

  function buildMessage() {
    return messageTemplate
      .replace('{{guestName}}', guestNameInput.value.trim())
      .replace('{{checkin}}', formatDate(checkinInput.value))
      .replace('{{checkout}}', formatDate(checkoutInput.value))
      .replace('{{guests}}', guestsSelect.value)
      .replace('{{roomType}}', roomTypeSelect.value || roomTypeAny)
      .replace('{{contact}}', currentContact());
  }

  openTriggers.forEach((trigger) => {
    trigger.addEventListener('click', () => openModal(trigger.dataset.bookChannel, trigger.dataset.bookRoom));
  });

  modal.addEventListener('click', (e) => {
    if (e.target === modal || e.target.closest('[data-booking-modal-close]')) closeModal();
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !modal.classList.contains('hidden')) closeModal();
  });

  checkinInput.addEventListener('change', () => {
    checkoutInput.min = checkinInput.value;
    if (checkoutInput.value && checkoutInput.value <= checkinInput.value) {
      checkoutInput.value = '';
    }
  });

  sendButtons.forEach((button) => {
    button.addEventListener('click', () => {
      if (!form.checkValidity()) {
        form.reportValidity();
        return;
      }

      const channel = button.dataset.bookingSend;
      const message = encodeURIComponent(buildMessage());
      let url;
      let target = '_self';

      if (channel === 'whatsapp') {
        url = `https://wa.me/${phone}?text=${message}`;
        target = '_blank';
      } else if (channel === 'email') {
        url = `mailto:${email}?subject=${encodeURIComponent(emailSubject)}&body=${message}`;
      } else {
        return;
      }

      if (target === '_blank') {
        window.open(url, '_blank', 'noopener');
      } else {
        window.location.href = url;
      }

      closeModal();
      form.reset();
    });
  });
});
