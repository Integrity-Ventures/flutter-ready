# site

The Flutter Ready board: a static [Jaspr](https://jaspr.site/) site, one row
per plugin plus one page per plugin at `/p/<name>/`. See `../SPEC.md` §3.2 and
`../10xs/workflow/instructions/20260927_05_architect-notes-e2-e6.md`
("e3-s1: Board rendering") for the source of truth.

It reads `../data/latest.json`, `../data/snapshots/`, and
`../data/deadlines.json` at build time — run the nightly job (`snapshot_job`)
first if those are stale.

## Running the project

Run your project using `jaspr serve`. The development server will be
available on `http://localhost:8080`.

## Building the project

Build your project using `jaspr build`. The output will be located inside
the `build/jaspr/` directory — static HTML/CSS, deployable anywhere.
