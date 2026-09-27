import 'package:jaspr/dom.dart';

import '../data/board.dart';
import '../data/grading.dart';

/// Fixed status palette (never themed): good/warning/critical plus a muted
/// grey for "not checked". Colour is never the only signal — every use pairs
/// it with a text label. Each shade is darkened from the obvious
/// red/amber/green/grey so that, as text, it clears WCAG AA (>= 4.5:1) on
/// both white and the tinted `*Bg` pairing below — a plain amber in
/// particular (e.g. `#fab219`) cannot pass at any normal text size.
const Color statusGreen = Color('#0f7a0f');
const Color statusAmber = Color('#9a6300');
const Color statusRed = Color('#c02f2f');
const Color statusGrey = Color('#6b6963');

/// A distinct neutral for "not affected" (SPEC: never merge it into "ready"
/// green, which is exactly the bug that made the board show a false 100%).
const Color statusNeutral = Color('#5b6b8c');

/// Light tints for status pills (tiles, chips): each keeps its paired
/// foreground color above AA at normal text sizes.
const Color statusGreenBg = Color('#e6f4e6');
const Color statusAmberBg = Color('#fdf3e0');
const Color statusRedBg = Color('#fbe9e9');
const Color statusGreyBg = Color('#eeede9');
const Color statusNeutralBg = Color('#e9edf5');

Color colorForStatus(Status status) {
  switch (status) {
    case Status.green:
      return statusGreen;
    case Status.amber:
      return statusAmber;
    case Status.red:
      return statusRed;
    case Status.notChecked:
      return statusGrey;
  }
}

Color bgColorForStatus(Status status) {
  switch (status) {
    case Status.green:
      return statusGreenBg;
    case Status.amber:
      return statusAmberBg;
    case Status.red:
      return statusRedBg;
    case Status.notChecked:
      return statusGreyBg;
  }
}

String labelForStatus(Status status) {
  switch (status) {
    case Status.green:
      return 'Ready';
    case Status.amber:
      return 'Caution';
    case Status.red:
      return 'Blocked';
    case Status.notChecked:
      return 'Not checked';
  }
}

Color colorForCategory(BoardCategory category) {
  switch (category) {
    case BoardCategory.blocked:
      return statusRed;
    case BoardCategory.unclear:
      return statusAmber;
    case BoardCategory.ready:
      return statusGreen;
    case BoardCategory.notAffected:
      return statusNeutral;
    case BoardCategory.notChecked:
      return statusGrey;
  }
}

Color bgColorForCategory(BoardCategory category) {
  switch (category) {
    case BoardCategory.blocked:
      return statusRedBg;
    case BoardCategory.unclear:
      return statusAmberBg;
    case BoardCategory.ready:
      return statusGreenBg;
    case BoardCategory.notAffected:
      return statusNeutralBg;
    case BoardCategory.notChecked:
      return statusGreyBg;
  }
}

String labelForCategory(BoardCategory category) {
  switch (category) {
    case BoardCategory.blocked:
      return 'Blocked';
    case BoardCategory.unclear:
      return 'Unclear';
    case BoardCategory.ready:
      return 'Ready';
    case BoardCategory.notAffected:
      return 'Not affected';
    case BoardCategory.notChecked:
      return 'Not checked';
  }
}
