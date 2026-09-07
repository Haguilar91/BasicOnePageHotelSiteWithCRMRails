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
  const roomTypeLabel = form.querySelector('[data-booking-room-label]');
  const offerBox = form.querySelector('[data-booking-offer-box]');
  const offerTitleEl = form.querySelector('[data-booking-offer-title]');
  const offerDescriptionEl = form.querySelector('[data-booking-offer-description]');
  const offerContextInput = form.querySelector('#booking-offer-context');
  const wantsPhoneCheckbox = form.querySelector('#booking-wants-phone-contact');
  const phoneFields = form.querySelector('[data-booking-phone-fields]');
  const countryCodeSelect = form.querySelector('#booking-country-code');
  const phoneInput = form.querySelector('#booking-contact-phone');
  const sendButtons = form.querySelectorAll('[data-booking-send]');
  const sendButtonsRow = form.querySelector('[data-booking-send-row]');
  const whatsappButton = form.querySelector('[data-booking-send="whatsapp"]');
  const emailButton = form.querySelector('[data-booking-send="email"]');
  const phoneToggleLabelEl = form.querySelector('[data-booking-phone-toggle-label]');
  const phoneToggleHintEl = form.querySelector('[data-booking-phone-toggle-hint]');

  const phone = modal.dataset.phone || '';
  const email = modal.dataset.email || '';
  const emailSubject = modal.dataset.emailSubject || '';
  const messageTemplate = modal.dataset.messageTemplate || '';
  const roomTypeAny = modal.dataset.roomTypeAny || '';
  const roomTypeLabelText = modal.dataset.roomTypeLabel || '';
  const offerLabelText = modal.dataset.offerLabel || '';
  const contactNotProvidedText = modal.dataset.contactNotProvided || '';
  const phoneToggleLabelText = modal.dataset.phoneToggleLabel || '';
  const phoneToggleHintText = modal.dataset.phoneToggleHint || '';
  const phoneToggleLabelWhatsapp = modal.dataset.phoneToggleLabelWhatsapp || phoneToggleLabelText;
  const phoneToggleHintWhatsapp = modal.dataset.phoneToggleHintWhatsapp || phoneToggleHintText;
  const phoneToggleLabelEmail = modal.dataset.phoneToggleLabelEmail || phoneToggleLabelText;
  const phoneToggleHintEmail = modal.dataset.phoneToggleHintEmail || phoneToggleHintText;
  const locale = modal.dataset.locale === 'en' ? 'en-US' : 'es-MX';

  const today = new Date().toISOString().slice(0, 10);
  checkinInput.min = today;

  // Toggles the "want a callback number?" checkbox: the phone fields (and
  // their required-ness) only exist while it's checked, since WhatsApp
  // already shares the guest's number and email guests may not want to
  // leave one at all.
  function updatePhoneVisibility() {
    const show = wantsPhoneCheckbox.checked;
    phoneFields.classList.toggle('hidden', !show);
    phoneInput.required = show;
    if (!show) phoneInput.value = '';
  }

  wantsPhoneCheckbox.addEventListener('change', updatePhoneVisibility);
  updatePhoneVisibility();

  // When the guest arrives via a channel-specific trigger (e.g. the CTA
  // section's dedicated "Send WhatsApp"/"Send Email" buttons), only that
  // channel's send button stays visible and the phone-contact copy adapts:
  // for WhatsApp it's framed as an alternate number (WhatsApp already
  // shares theirs); for Email — which carries no phone at all — it's framed
  // as a direct ask. Falls back to showing both buttons with the generic
  // copy when no channel was specified (nav, room cards, offer cards).
  function updateChannelContext(requestedChannel) {
    const targetButton = requestedChannel === 'whatsapp' ? whatsappButton
      : requestedChannel === 'email' ? emailButton
      : null;
    const channel = targetButton ? requestedChannel : null;

    if (whatsappButton) whatsappButton.classList.toggle('hidden', channel === 'email');
    if (emailButton) emailButton.classList.toggle('hidden', channel === 'whatsapp');
    if (sendButtonsRow) sendButtonsRow.classList.toggle('sm:grid-cols-2', !channel);

    phoneToggleLabelEl.textContent = channel === 'whatsapp' ? phoneToggleLabelWhatsapp
      : channel === 'email' ? phoneToggleLabelEmail
      : phoneToggleLabelText;
    phoneToggleHintEl.textContent = channel === 'whatsapp' ? phoneToggleHintWhatsapp
      : channel === 'email' ? phoneToggleHintEmail
      : phoneToggleHintText;
  }

  function openModal({ channel, room, offerTitle, offerDescription } = {}) {
    updateChannelContext(channel);

    if (offerTitle) {
      // Opened from an Offer card: show its title/description instead of
      // asking the guest to pick a room off the full list again.
      offerTitleEl.textContent = offerTitle;
      offerDescriptionEl.textContent = offerDescription || '';
      offerDescriptionEl.classList.toggle('hidden', !offerDescription);
      offerBox.classList.remove('hidden');
      roomTypeSelect.classList.add('hidden');
      roomTypeSelect.value = '';
      roomTypeLabel.textContent = offerLabelText;
      offerContextInput.value = offerDescription ? `${offerTitle} — ${offerDescription}` : offerTitle;
    } else {
      offerBox.classList.add('hidden');
      roomTypeSelect.classList.remove('hidden');
      roomTypeLabel.textContent = roomTypeLabelText;
      offerContextInput.value = '';

      const roomMatch = room
        ? Array.from(roomTypeSelect.options).find((option) => option.value === room)
        : null;
      roomTypeSelect.value = roomMatch ? roomMatch.value : '';
    }

    modal.classList.remove('hidden');
    modal.classList.add('flex');
    document.body.style.overflow = 'hidden';

    const focusButton = channel
      ? form.querySelector(`[data-booking-send="${channel}"]`)
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
    if (!wantsPhoneCheckbox.checked) return contactNotProvidedText;
    return `${countryCodeSelect.value} ${phoneInput.value.trim()}`.trim();
  }

  function buildMessage() {
    const roomType = offerContextInput.value || roomTypeSelect.value || roomTypeAny;

    return messageTemplate
      .replace('{{guestName}}', guestNameInput.value.trim())
      .replace('{{checkin}}', formatDate(checkinInput.value))
      .replace('{{checkout}}', formatDate(checkoutInput.value))
      .replace('{{guests}}', guestsSelect.value)
      .replace('{{roomType}}', roomType)
      .replace('{{contact}}', currentContact());
  }

  openTriggers.forEach((trigger) => {
    trigger.addEventListener('click', () => openModal({
      channel: trigger.dataset.bookChannel,
      room: trigger.dataset.bookRoom,
      offerTitle: trigger.dataset.bookOfferTitle,
      offerDescription: trigger.dataset.bookOfferDescription
    }));
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
      updatePhoneVisibility();
    });
  });
});
