# Task report: Discover plugins via pub.dev search, reds first

Card: `added-discover-plugins-via-pub-dev-search-reds-first-dad732db`
Instruction executed: `10xs/workflow/instructions/20260927_14_discover-via-pubdev-search.md`
Lane branch: `feature/discover-via-search`
Commits: `9594846` (discovery rework), `a6fd7c7` (fix + live data)

## What changed

- **Discovery** (`packages/readiness_check/lib/src/plugin_discovery.dart`,
  rewritten): candidates now come from two pub.dev searches, sorted by
  downloads, 10 pages each (`PubDevClient.searchPackages`, new):
  - `no-swiftpm`: `is:plugin platform:ios -is:swiftpm-plugin`
  - `top-downloads`: `is:plugin`

  Results are merged and deduped. Federated platform packages fold into
  their app-facing plugin two ways: (a) fetch each raw candidate's
  `PackageInfo` and drop any name another candidate declares as a
  `default_package`; (b) a naming-suffix fallback (`_ios`, `_android`,
  `_foundation`, `_macos`, `_windows`, `_linux`, `_web`, `_darwin`) for
  cases (a) doesn't catch, e.g. `path_provider_foundation` folding into
  `path_provider`. Each surviving candidate records which query found it
  (`sources`, alphabetical — `["no-swiftpm", "top-downloads"]`).
  `mapWithConcurrency` moved from `snapshot_job` into `readiness_check` so
  discovery's own page/fold fetches can use concurrency 4, same as the
  deep check.

- **Deep check made failure-proof**: `snapshot_job/lib/src/snapshot_assembler.dart`
  previously called `listArchiveEntryPaths`/`extractArchiveEntries` (gzip
  + tar decode) outside any `try`/`catch`. A corrupt or truncated archive
  threw synchronously, which rejected that plugin's `Future` unwrapped —
  crashing the whole `assembleSnapshot` run (this is the `--top 1000`
  crash the instruction cites: `FormatException: Filter error, bad data`).
  Both call sites are now wrapped in the existing `_safeCall`, so a decode
  failure is recorded in that plugin's `errors` and grading treats it as
  "no archive," same as any other per-plugin failure. **This is not
  theoretical**: the live run below hit it for real, twice (see Errors).

- **Snapshot contract**: `topN` replaced with
  `discovery: {method, queries, resultsPerQuery}`; `plugins` sorted by
  `downloadCount30Days` descending; each plugin gained a `search` field.
  `Snapshot`/`PluginEntry` (readiness_check), `buildSnapshotJson`/
  `PluginSnapshot` (snapshot_job), and the two site strings that printed
  `topN` were all updated. `bin/snapshot.dart --top` keeps its old meaning
  (results per query, rounded up to pages of 10); the GitHub Action
  invocation is unchanged.

- **Found during the live run, fixed same-commit**: `PluginEntry.fromJson`
  cast `json['swiftpm']`/`alignment`/`android` straight to
  `Map<String, dynamic>` and `version` straight to `String`. Every
  snapshot ever committed before this run happened to have zero plugins
  with a non-empty `errors` list, so the `null` those fields legitimately
  carry for a failed plugin (SPEC §3.1.2-3: "never omitted") never hit
  this cast — until the live run below produced 3 such plugins and the
  site-side parser crashed on them. Fixed by parsing a null
  swiftpm/alignment/android as an all-null sentinel (every grading
  function already checks `errors.isNotEmpty` first, before touching
  those fields) and falling back to `'unknown'` for a null version. Added
  `packages/readiness_check/test/snapshot_model_test.dart` and verified
  the fix against the real generated `data/latest.json` (parses cleanly,
  146/146 plugins, grading runs over all of them without exception).

- **SPEC.md §3.1** item 1 ("Pick the plugins") rewritten to describe the
  two searches, the 100-result-per-query cap, and the fold rule, dated
  2026-09-27.

- `data/snapshots/2026-09-26.json` deleted (graded with rules fixed
  after it was taken; kept in git history).

## Gates

`dart analyze --fatal-infos` and `dart test` pass in all four packages
(`readiness_check`, `snapshot_job`, `flutter_ready`, `site`) — run
individually right before each commit and again after the final fix.

New/changed tests: `plugin_discovery_test.dart` (rewritten for
search-based discovery: merge/dedupe, both fold paths, source labels,
page-count rounding), `pub_dev_client_test.dart` (`searchPackages`),
`package_archive_test.dart` + `snapshot_assembler_test.dart` (corrupt
`.tar.gz` isolation — the regression test for the crash this card fixes),
`snapshot_model_test.dart` (new, for the null-cast fix).

## Live run (foreground, on the fleetbox)

```
cd packages/snapshot_job
dart run bin/snapshot.dart --top 100 --out ../../data/snapshots/
```

- Exit code 0. Wall time 44.9s (`time`); the job's own stopwatch (search +
  fold + deep check, excluding Dart VM/pub startup): **28.4s** for 146
  candidates -> 146 plugins.
- Output: `data/snapshots/2026-09-27.json` + `data/latest.json`,
  `generatedAt` 2026-09-27T10:01:56Z, `discovery.resultsPerQuery` 100.

### Counts (146 plugins total)

| Blocked | Unclear | Ready | Not affected | Errors |
|---:|---:|---:|---:|---:|
| 81 | 8 | 45 | 9 | 3 |

(Blocked = SwiftPM red; Unclear = tag/archive disagree; Ready = ships
SwiftPM and has native iOS code; Not affected = no native iOS code or not
an iOS plugin; Errors = a check couldn't run, per-plugin, recorded and
never aborting the run — same categories as the e3-s1-rework instruction's
board tiles.)

### Errors (3) — proof the non-abort fix matters on real data

| Plugin | Error |
|---|---|
| `flutter_widgetkit` | `flutter_widgetkit archive decode: FormatException: Filter error, bad data` (×2 — swiftpm + android archive decode, same underlying archive) |
| `ios_insecure_screen_detector` | `ios_insecure_screen_detector archive decode: FormatException: Filter error, bad data` (×2) |
| `media_kit_video` | `package info: type 'Null' is not a subtype of type 'Map<String, dynamic>' in type cast` (pre-existing edge case in `fetchPackageInfo`'s own JSON, already caught by the pre-existing `_safeCall` around that fetch — not something this card touched) |

Before this card's archive-decode fix, either of the first two would have
raised an unhandled `FormatException` inside `mapWithConcurrency`'s
`Future.wait` and aborted the entire 146-plugin run, exactly as the
instruction's `--top 1000` incident describes.

### Full red list (81), sorted by downloads (30-day), with evidence

| Plugin | Downloads/30d | Evidence |
|---|---:|---|
| flutter_inappwebview | 1,197,182 | No Package.swift in the flutter_inappwebview_ios archive. |
| google_maps_flutter | 959,251 | No Package.swift in the google_maps_flutter_ios archive. |
| open_filex | 636,709 | No Package.swift in the open_filex archive. |
| google_mlkit_commons | 487,064 | No Package.swift in the google_mlkit_commons archive. |
| flutter_tts | 416,839 | No Package.swift in the flutter_tts archive. |
| google_mlkit_text_recognition | 282,562 | No Package.swift in the google_mlkit_text_recognition archive. |
| video_compress | 179,462 | No Package.swift in the video_compress archive. |
| video_thumbnail | 178,448 | No Package.swift in the video_thumbnail archive. |
| objectbox_flutter_libs | 168,765 | No Package.swift in the objectbox_flutter_libs archive. |
| flutter_downloader | 156,521 | No Package.swift in the flutter_downloader archive. |
| google_mlkit_barcode_scanning | 128,329 | No Package.swift in the google_mlkit_barcode_scanning archive. |
| get_thumbnail_video | 126,847 | No Package.swift in the get_thumbnail_video archive. |
| google_mlkit_face_detection | 108,710 | No Package.swift in the google_mlkit_face_detection archive. |
| flutter_js | 108,619 | No Package.swift in the flutter_js archive. |
| isar_community_flutter_libs | 103,864 | No Package.swift in the isar_community_flutter_libs archive. |
| store_redirect | 90,842 | No Package.swift in the store_redirect archive. |
| share_handler | 89,438 | No Package.swift in the share_handler_ios archive. |
| sqflite_sqlcipher | 88,152 | No Package.swift in the sqflite_sqlcipher archive. |
| flutter_background_service | 87,813 | No Package.swift in the flutter_background_service_ios archive. |
| flutter_compass | 84,884 | No Package.swift in the flutter_compass archive. |
| super_keyboard | 84,751 | No Package.swift in the super_keyboard archive. |
| device_calendar | 78,677 | No Package.swift in the device_calendar archive. |
| fk_user_agent | 78,649 | No Package.swift in the fk_user_agent archive. |
| flutter_sound | 75,493 | No Package.swift in the flutter_sound archive. |
| audio_waveforms | 69,615 | No Package.swift in the audio_waveforms archive. |
| device_region | 68,547 | No Package.swift in the device_region archive. |
| daily_flutter | 64,540 | No Package.swift in the daily_flutter archive. |
| tflite_flutter | 61,560 | No Package.swift in the tflite_flutter archive. |
| pinwheel | 60,325 | No Package.swift in the pinwheel archive. |
| flutter_network_capabilities | 60,202 | No Package.swift in the flutter_network_capabilities archive. |
| super_editor_clipboard | 58,200 | No Package.swift in the super_editor_clipboard archive. |
| segment_analytics | 57,354 | No Package.swift in the segment_analytics archive. |
| desktop_webview_auth | 56,593 | No Package.swift in the desktop_webview_auth archive. |
| image_editor | 56,541 | No Package.swift in the image_editor_common archive. |
| onetrust_publishers_native_cmp | 51,219 | No Package.swift in the onetrust_publishers_native_cmp archive. |
| disk_space_plus | 51,169 | No Package.swift in the disk_space_plus archive. |
| flutter_aepcore | 50,646 | No Package.swift in the flutter_aepcore archive. |
| flutter_jailbreak_detection_plus | 46,580 | No Package.swift in the flutter_jailbreak_detection_plus archive. |
| flutter_aepedge | 43,058 | No Package.swift in the flutter_aepedge archive. |
| flutter_aepedgeidentity | 43,011 | No Package.swift in the flutter_aepedgeidentity archive. |
| push | 40,109 | No Package.swift in the push archive. |
| apple_maps_flutter | 39,072 | No Package.swift in the apple_maps_flutter archive. |
| flutter_exif_rotation | 35,828 | No Package.swift in the flutter_exif_rotation archive. |
| memory_info | 33,431 | No Package.swift in the memory_info archive. |
| terminate_restart | 32,960 | No Package.swift in the terminate_restart archive. |
| gallery_saver_plus | 32,495 | No Package.swift in the gallery_saver_plus archive. |
| flutter_dynamic_icon_plus | 32,034 | No Package.swift in the flutter_dynamic_icon_plus archive. |
| flutter_usabilla | 31,585 | No Package.swift in the flutter_usabilla archive. |
| google_mlkit_translation | 31,281 | No Package.swift in the google_mlkit_translation archive. |
| flutter_aepassurance | 30,322 | No Package.swift in the flutter_aepassurance archive. |
| otp_autofill | 29,084 | No Package.swift in the otp_autofill archive. |
| flutter_idensic_mobile_sdk_plugin | 27,596 | No Package.swift in the flutter_idensic_mobile_sdk_plugin archive. |
| flutter_icmp_ping | 27,480 | No Package.swift in the flutter_icmp_ping archive. |
| flutter_jailbreak_detection | 27,165 | No Package.swift in the flutter_jailbreak_detection archive. |
| country_codes | 26,422 | No Package.swift in the country_codes archive. |
| ably_flutter | 26,336 | No Package.swift in the ably_flutter archive. |
| unity_kit | 25,261 | No Package.swift in the unity_kit archive. |
| root_jailbreak_sniffer | 25,249 | No Package.swift in the root_jailbreak_sniffer archive. |
| fast_image_editor | 24,962 | No Package.swift in the fast_image_editor archive. |
| google_mlkit_language_id | 24,071 | No Package.swift in the google_mlkit_language_id archive. |
| http_proxy | 23,582 | No Package.swift in the http_proxy archive. |
| flutter_aepedgeconsent | 23,514 | No Package.swift in the flutter_aepedgeconsent archive. |
| flutter_logs | 23,308 | No Package.swift in the flutter_logs archive. |
| flutter_google_places_sdk | 22,455 | No Package.swift in the flutter_google_places_sdk_ios archive. |
| google_mlkit_image_labeling | 22,381 | No Package.swift in the google_mlkit_image_labeling archive. |
| flutter_aepedgebridge | 22,035 | No Package.swift in the flutter_aepedgebridge archive. |
| flutter_vibrate | 21,822 | No Package.swift in the flutter_vibrate archive. |
| google_mlkit_object_detection | 20,970 | No Package.swift in the google_mlkit_object_detection archive. |
| flutter_native_video_trimmer | 20,939 | No Package.swift in the flutter_native_video_trimmer archive. |
| opus_flutter | 20,932 | No Package.swift in the opus_flutter_ios archive. |
| onfido_sdk | 20,875 | No Package.swift in the onfido_sdk archive. |
| image_gallery_saver | 20,780 | No Package.swift in the image_gallery_saver archive. |
| reshub_flutter | 20,571 | No Package.swift in the reshub_flutter archive. |
| screen_capture_event | 20,501 | No Package.swift in the screen_capture_event archive. |
| store_checker | 20,237 | No Package.swift in the store_checker archive. |
| flutter_pcm_sound | 20,231 | No Package.swift in the flutter_pcm_sound archive. |
| secure_application | 19,855 | No Package.swift in the secure_application archive. |
| open_mail | 19,666 | No Package.swift in the open_mail archive. |
| flutter_aepuserprofile | 19,402 | No Package.swift in the flutter_aepuserprofile archive. |
| flutter_isolate | 19,034 | No Package.swift in the flutter_isolate archive. |
| apptentive_flutter | 18,081 | No Package.swift in the apptentive_flutter archive. |

All 81 grade red on the same signal: the pub.dev `is:swiftpm-plugin` tag
and the archive both say no `Package.swift` (`agrees: true`, both false)
— none of the 81 are tag/archive disagreements (those are the 8 "Unclear"
rows, not counted here).

Sanity check against the instruction's "Why" list: `google_maps_flutter`,
`open_filex`, `flutter_tts`, `flutter_downloader` and `video_compress` are
all in this red list, now with real evidence and download counts.
`flutter_native_splash` and `flutter_facebook_auth` are discovered (both
carry `search` tags) but grade differently — `flutter_native_splash` has
no native iOS code at all (a build-time asset generator, correctly
"Not affected"), and `flutter_facebook_auth`'s tag and archive disagree
(graded "Unclear," not red). Both are now visible to the board either
way, which is what the "isn't 'most used'" complaint was about — the old
source didn't discover them at all.

## Follow-ups for the architect

- The board layout (reds-on-top headline, four count tiles, the "Not
  checked" tile for errors) is explicitly out of scope here per the
  instruction — that's `20260927_13_e3-s1-rework-reds-on-top.md`. This
  run's data is ready for it: 3 real error rows, 81 real red rows.
- Both `PluginEntry.fromJson` fixes above are narrow and don't touch any
  UI/grading code, but they're worth a second look given they change how
  the shared snapshot contract's reader behaves for any future snapshot
  that (correctly) contains a per-plugin failure.
