import 'package:jaspr/dom.dart';

/// Brand tokens, taken from the new HireFlutter site
/// (https://next-dev.d17nrypcqry4ka.amplifyapp.com/, checked 2026-09-27):
/// Inter type, a navy ink on off-white paper, and one accent blue. That site
/// has no separate logomark of its own — its "HireFlutter.dev" brand is a
/// bold text wordmark, so this board's header uses the same text wordmark
/// rather than an image.
/// The global 'html, body' and 'h1' rules live once, on the Document in
/// main.server.dart — this file holds every other shared value, so no
/// component needs a stray hex value of its own.
const fontFamilyName = 'Inter';

/// Ink and accent.
const Color brandNavy = Color('#0f1932');
const Color brandBlue = Color('#2b5ff3');
const Color brandBlueDark = Color('#1c3fae');

/// Background for the "Powered by 10xs" pill, matching next-dev's blue-50.
/// Paired with [brandBlueDark] (not next-dev's lighter blue-500) because
/// blue-500-on-blue-50 is only ~3.4:1; brandBlueDark on this background is
/// ~8.1:1, comfortably past WCAG AA's 4.5:1 for small text.
const Color pillBackground = Color('#eff6ff');

/// Surfaces.
const Color surfacePage = Color('#f3f7fd');
const Color surfaceCard = Color('#ffffff');
const Color borderSubtle = Color('#e3e8f2');

/// Secondary text, everywhere a component previously hard-coded a grey.
const Color textMuted = Color('#475569');
