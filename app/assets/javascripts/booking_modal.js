// "Book Now" modal — collects check-in/check-out dates, a contact (phone
// with country code, or email), and the channel the guest wants to be
// contacted back on. That channel also decides how the form itself reaches
// the hotel: WhatsApp/SMS/iMessage/Messenger hand off to the matching app
// addressed to the hotel, and "Call" — which has no app of its own to hand
// off to — is relayed by email like a written note instead of dialing.
// Triggers may carry data-book-channel to preselect a channel (e.g. the
// CTA section's "Send WhatsApp"/"Send Email" buttons open straight into
// their matching channel instead of the default).
document.addEventListener('DOMContentLoaded', function () {
  const modal = document.querySelector('[data-booking-modal]');
  if (!modal) return;

  const openTriggers = document.querySelectorAll('[data-book-modal-open]');
  const form = modal.querySelector('[data-booking-form]');
  const checkinInput = form.querySelector('#booking-checkin');
  const checkoutInput = form.querySelector('#booking-checkout');
  const countryCodeSelect = form.querySelector('#booking-country-code');
  const phoneInput = form.querySelector('#booking-contact-phone');
  const emailInput = form.querySelector('#booking-contact-email');
  const phoneGroup = form.querySelector('[data-booking-phone-group]');
  const emailGroup = form.querySelector('[data-booking-email-group]');
  const callNote = modal.querySelector('[data-booking-call-note]');
  const channelInputs = form.querySelectorAll('input[name="channel"]');

  const phone = modal.dataset.phone || '';
  const email = modal.dataset.email || '';
  const emailSubject = modal.dataset.emailSubject || '';
  const messengerUsername = modal.dataset.messengerUsername || '';
  const messageTemplate = modal.dataset.messageTemplate || '';
  const locale = modal.dataset.locale === 'en' ? 'en-US' : 'es-MX';

  const today = new Date().toISOString().slice(0, 10);
  checkinInput.min = today;

  function openModal(preselectChannel) {
    if (preselectChannel) {
      const match = form.querySelector(`input[name="channel"][value="${preselectChannel}"]`);
      if (match) match.checked = true;
    }
    syncFieldsForChannel();
    modal.classList.remove('hidden');
    modal.classList.add('flex');
    document.body.style.overflow = 'hidden';
  }

  function closeModal() {
    modal.classList.add('hidden');
    modal.classList.remove('flex');
    document.body.style.overflow = '';
  }

  function selectedChannel() {
    const checked = form.querySelector('input[name="channel"]:checked');
    return checked ? checked.value : null;
  }

  function selectedChannelLabel() {
    const checked = form.querySelector('input[name="channel"]:checked');
    if (!checked) return '';
    const label = checked.closest('label').querySelector('span');
    return label ? label.textContent.trim() : checked.value;
  }

  function syncFieldsForChannel() {
    const channel = selectedChannel();
    const isEmail = channel === 'email';

    phoneGroup.classList.toggle('hidden', isEmail);
    phoneInput.required = !isEmail;

    emailGroup.classList.toggle('hidden', !isEmail);
    emailInput.required = isEmail;

    callNote.classList.toggle('hidden', channel !== 'call');
  }

  function formatDate(value) {
    if (!value) return value;
    const [year, month, day] = value.split('-').map(Number);
    const date = new Date(year, month - 1, day);
    return new Intl.DateTimeFormat(locale, { day: 'numeric', month: 'long', year: 'numeric' }).format(date);
  }

  function currentContact() {
    if (selectedChannel() === 'email') return emailInput.value.trim();
    return `${countryCodeSelect.value} ${phoneInput.value.trim()}`.trim();
  }

  function buildMessage() {
    return messageTemplate
      .replace('{{checkin}}', formatDate(checkinInput.value))
      .replace('{{checkout}}', formatDate(checkoutInput.value))
      .replace('{{channel}}', selectedChannelLabel())
      .replace('{{contact}}', currentContact());
  }

  openTriggers.forEach((trigger) => {
    trigger.addEventListener('click', () => openModal(trigger.dataset.bookChannel));
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

  channelInputs.forEach((input) => {
    input.addEventListener('change', syncFieldsForChannel);
  });
  syncFieldsForChannel();

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    if (!form.checkValidity()) {
      form.reportValidity();
      return;
    }

    const channel = selectedChannel();
    const message = encodeURIComponent(buildMessage());
    let url;
    let target = '_self';

    switch (channel) {
      case 'whatsapp':
        url = `https://wa.me/${phone}?text=${message}`;
        target = '_blank';
        break;
      case 'email':
      case 'call':
        url = `mailto:${email}?subject=${encodeURIComponent(emailSubject)}&body=${message}`;
        break;
      case 'imessage':
      case 'sms':
        url = `sms:${phone}?&body=${message}`;
        break;
      case 'messenger':
        url = `https://m.me/${messengerUsername}?text=${message}`;
        target = '_blank';
        break;
      default:
        return;
    }

    if (target === '_blank') {
      window.open(url, '_blank', 'noopener');
    } else {
      window.location.href = url;
    }

    closeModal();
    form.reset();
    syncFieldsForChannel();
  });
});
