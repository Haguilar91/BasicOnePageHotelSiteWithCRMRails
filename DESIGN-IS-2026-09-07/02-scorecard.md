# Scorecard

1. Good design is innovative — Score: 1/3
   Evidence: standard hero→rooms→offers→gallery→services→activities→location→CTA
   single-page hotel template (01-evidence §1); the one genuinely novel piece
   (admin-editable theme with auto-computed contrast) is invisible to the visitor.
   Justification: imitates the category's conventions competently but introduces
   nothing a visitor would recognize as new.

2. Good design makes a product useful — Score: 3/3
   Evidence: the booking action is reachable from 6 distinct points on the page
   regardless of scroll position (01-evidence §1); the modal asks only for what it
   needs before handing off to WhatsApp/email.
   Justification: primary task completes in the fewest possible steps from anywhere
   on the page, with no decoy actions.

3. Good design is aesthetic — Score: 1/3
   Evidence: disciplined 5-color palette and consistent spacing/type scale
   (01-evidence §2), undercut by every primary CTA button visibly cycling through a
   mismatched dusty-pink phase every 3 seconds (`audit_rooms.png`, `audit_contact.png`).
   Justification: one jarring, continuously-visible violation outweighs an otherwise
   consistent system — scored on the worst instance, not the average.

4. Good design makes a product understandable — Score: 3/3
   Evidence: plain-language nav labels, icon+text pairing throughout, and the
   booking-modal phone-contact copy this session specifically reworked for clarity
   (01-evidence §2, §3).
   Justification: a first-time visitor would correctly name every primary control.

5. Good design is unobtrusive — Score: 1/3
   Evidence: 7 elements animate continuously and indefinitely at idle — 5 buttons'
   gradient "shine" plus 3 testimonial cards' "floating" motion — with no
   `prefers-reduced-motion` gate (01-evidence §2, §4).
   Justification: decoration that never stops moving competes for attention rather
   than receding behind the content.

6. Good design is honest — Score: 3/3
   Evidence: the copy actually live on the site is factual and unembellished
   (01-evidence §3); no dark patterns found anywhere in the booking/pricing flow.
   Justification: scoring what ships, not the codebase's unused fallback strings —
   every claim on the live page maps to real content or behavior.

7. Good design is long-lasting — Score: 2/3
   Evidence: warm terracotta/cream palette and serif/sans pairing read as timeless;
   the infinite decorative "shine"/"floating" animations read as a dated
   mid-2010s CSS-showcase flourish (01-evidence §2).
   Justification: one dated stylistic marker (gratuitous perpetual motion) against an
   otherwise era-neutral visual language.

8. Good design is thorough down to the last detail — Score: 1/3
   Evidence: `accent_soft` was never paired to the new `accent` (01-evidence §2), the
   Maps embed renders blank in at least one capture, and there is no `<main>` landmark
   or skip-link (01-evidence §5).
   Justification: three separate finishing details left incomplete on the audited
   surface.

9. Good design is environmentally friendly — Score: 0/3
   Evidence: 47.86MB total page weight, 95% of it unoptimized images (one alone at
   8.1MB), plus two infinite animation loops with no motion-preference gate
   (01-evidence §4).
   Justification: total weight is roughly 24× the rubric's 2MB failing threshold —
   this is the floor of the scale, not a borderline case.

10. Good design is as little design as possible — Score: 1/3
    Evidence: two purely decorative animation systems that add no task value, one
    orphaned `.orig` file, and one Avo field (`text_muted`) left live after this
    session's own fix made it functionally dead (01-evidence §1, §2).
    Justification: several concrete, independently removable elements — none of which
    would be missed if deleted — without touching the repeated booking-CTA pattern,
    which earns its place under principle #2.

**Total: 16/30** (1+3+1+3+1+3+2+1+0+1)
