# Black Eye

**Privacy screening for the things you share.**

We share screenshots, IDs, bank letters and PDFs every day, and it is far too
easy to leave a card number, an address or a passport ID sitting in plain
sight. Black Eye fixes that in one step: point it at an image or PDF and it
finds the sensitive parts and covers them before the file ever leaves your
hands.

Everything runs on the device. Nothing is uploaded, nothing is stored in the
cloud, and the confidential data never touches a server.

---

## What it does

- Reads the text in a photo, screenshot or PDF and locates private data by its
  position on the page.
- Detects credit and debit card numbers, IBAN / bank details, email addresses,
  phone numbers, and ID / passport numbers.
- Detects QR codes, which often hide links or payment data.
- Covers each match tightly, word by word, so only the private value is hidden
  and the rest of the image stays readable.
- Lets you add your own keywords (a name, a project, an address) to hide.
- Works in **English and German**, and reads German text out of the box.

## Built for a real workflow

- **Choose how to hide it:** blur, pixelate, or a solid black box.
- **Missed something?** Drag a box over any area to hide it by hand.
- **Send it anywhere:** save the clean copy straight to your gallery or share it
  to WhatsApp, email or anywhere through the system share sheet.
- **PDFs too:** every page is screened and you get back a new, protected PDF.
- **Privacy stats:** see how many files you have screened and how much has been
  hidden. Only the counts are stored, never the data.

## How it works

1. Pick an image or PDF.
2. On-device OCR (Google ML Kit) reads the text and where it sits.
3. Pattern rules and your keywords decide what is sensitive.
4. Each sensitive word is covered with your chosen style.
5. Save or share the protected result.

## Tech

Flutter and Dart, with Google ML Kit for on-device text and barcode
recognition, the `image` package for masking, and `pdfx` / `pdf` for document
handling. No backend, no accounts, no tracking.

## Project layout

```
lib/
  main.dart              startup + language handling
  theme.dart             brand colours (from the logo)
  l10n/                  English / German text
  models/                categories, matches, mask styles
  services/              OCR + detection, masking, PDF, settings
  screens/               onboarding, home, settings, manual blur, stats, PDF
  widgets/               logo, image preview
```

## Running it

```bash
flutter pub get
flutter run
```

The detection uses ML Kit, which runs on **Android and iOS**. Build for other
targets with `flutter build web`, `flutter build macos`, or
`flutter build windows`.

## Team

Add your names here before handing in.
