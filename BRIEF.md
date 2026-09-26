# Brief

Flutter teams are about to hit a wall they can't see. CocoaPods goes
read-only on 2 December, and a lot of the plugins we all depend on still
don't ship Swift Package Manager support. On Android, Play now wants API 36
and 16 KB-aligned native libraries. Today you find out which plugin blocks you
one app at a time, usually the day a release fails.

I want a public page, live on ready.hireflutter.dev, that shows the most-used
plugins on pub.dev and whether each one is ready for all three, refreshed
every night. I also want a command I can run in my own app, on my machine or
in CI, that tells me which of my plugins will block my next release and what
to switch to.

Open source, published on pub.dev under hireflutter.dev, and live before
2 December.
