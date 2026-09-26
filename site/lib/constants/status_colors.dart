import 'package:jaspr/dom.dart';

import '../data/grading.dart';

/// Fixed status palette (never themed): good/warning/critical plus a muted
/// grey for "not checked". Colour is never the only signal — every use pairs
/// it with a text label.
const Color statusGreen = Color('#0ca30c');
const Color statusAmber = Color('#fab219');
const Color statusRed = Color('#d03b3b');
const Color statusGrey = Color('#898781');

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
