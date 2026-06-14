# rovetia-app

Web + mobile: Vite 7, React 19, Apollo Client 4, Zustand, Tailwind 4, Radix UI.

- Forms: Formik + Zod
- Routing: React Router v7
- Mobile: Capacitor 8, Capgo (OTA, push)
- Native: Camera, document scanner, contacts, speech recognition, share, haptics, toast, splash, status bar, deep links
- OCR: Tesseract (all platforms), pdfjs, mammoth, xlsx
- Audio: @capgo/capacitor-audio-recorder + Whisper
- Dictation: Web Speech (web), @capgo/capacitor-speech-recognition (native)
- Calendar: FullCalendar (interaction/timegrid)
- Deploy: S3 + CloudFront (app.rovetia.com, dev.rovetia.com); SPA routing (403/404→index.html)
- Platforms: Android native (Play Store approved), iOS on hold (requires org account/LLC/SRL), PWA on iOS (mic permission asks on reload)
