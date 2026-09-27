import 'package:jaspr/dom.dart';

/// Brand tokens, taken from the new HireFlutter site
/// (https://next-dev.d17nrypcqry4ka.amplifyapp.com/, checked 2026-09-27):
/// Inter type, a navy ink on off-white paper, and one accent blue. That site
/// has no separate logomark of its own — its "HireFlutter.dev" brand is a
/// bold text wordmark — so there is no image to source; `web/images/logo.svg`
/// (the existing mascot, already in a compatible blue) is kept as-is.
/// The global 'html, body' and 'h1' rules live once, on the Document in
/// main.server.dart — this file holds every other shared value, so no
/// component needs a stray hex value of its own.
const fontFamilyName = 'Inter';

/// Ink and accent.
const Color brandNavy = Color('#0f1932');
const Color brandBlue = Color('#2b5ff3');
const Color brandBlueDark = Color('#1c3fae');

/// Surfaces.
const Color surfacePage = Color('#f3f7fd');
const Color surfaceCard = Color('#ffffff');
const Color borderSubtle = Color('#e3e8f2');

/// Secondary text, everywhere a component previously hard-coded a grey.
const Color textMuted = Color('#475569');
