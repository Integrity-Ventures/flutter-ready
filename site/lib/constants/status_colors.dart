import 'package:jaspr/dom.dart';

import '../data/board.dart';
import '../data/grading.dart';

/// Fixed status palette (never themed): good/warning/critical plus a muted
/// grey for "not checked". Colour is never the only signal — every use pairs
/// it with a text label.
const Color statusGreen = Color('#0ca30c');
const Color statusAmber = Color('#fab219');
const Color statusRed = Color('#d03b3b');
const Color statusGrey = Color('#898781');

/// A distinct neutral for "not affected" (SPEC: never merge it into "ready"
/// green, which is exactly the bug that made the board show a false 100%).
const Color statusNeutral = Color('#5b6b8c');

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
