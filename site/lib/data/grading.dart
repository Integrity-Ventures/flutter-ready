/// Colour rules now live in `readiness_check`, shared with the CLI
/// (`flutter_ready`) so the board and the CLI can't disagree (SPEC §2).
/// Re-exported here so every existing relative import in `site/lib` and
/// `site/test/grading_test.dart` keeps working.
library;

export 'package:readiness_check/readiness_check.dart'
    show
        Status,
        alignmentEvidence,
        alignmentStatus,
        isBlocked,
        swiftPmEvidence,
        swiftPmGreenSharePercent,
        swiftPmStatus;
