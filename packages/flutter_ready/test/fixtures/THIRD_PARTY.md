# Third-party files in these test fixtures

Some fixtures are copies of files from real, openly licensed Flutter
plugins, kept so the checker can be tested against real-world shapes. They
are used only by this package's tests and are left out of the pub.dev
upload (see `../../.pubignore`).

## url_launcher_android and url_launcher_ios

Files: `sources/url_launcher_android/*`, `sources/url_launcher_ios/*`,
`archives/url_launcher_android.tar.gz`, `archives/url_launcher_ios.tar.gz`.
From https://github.com/flutter/packages (packages/url_launcher), under the
BSD 3-Clause licence:

> Copyright 2013 The Flutter Authors
>
> Redistribution and use in source and binary forms, with or without
> modification, are permitted provided that the following conditions are
> met: (1) redistributions of source code must retain the above copyright
> notice, this list of conditions and the following disclaimer;
> (2) redistributions in binary form must reproduce the above copyright
> notice, this list of conditions and the following disclaimer in the
> documentation and/or other materials provided with the distribution;
> (3) neither the name of the copyright holder nor the names of its
> contributors may be used to endorse or promote products derived from this
> software without specific prior written permission.
>
> THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
> IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
> THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
> PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
> CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
> EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
> PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
> PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
> LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
> NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
> SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## flutter_barcode_scanner

Files: `sources/flutter_barcode_scanner/*`,
`archives/flutter_barcode_scanner.tar.gz`. From
https://github.com/AmolGangadhare/flutter_barcode_scanner, under the MIT
licence:

> Copyright (c) 2019 Amol Gangadhare
>
> Permission is hereby granted, free of charge, to any person obtaining a
> copy of this software and associated documentation files (the
> "Software"), to deal in the Software without restriction, including
> without limitation the rights to use, copy, modify, merge, publish,
> distribute, sublicense, and/or sell copies of the Software, and to permit
> persons to whom the Software is furnished to do so, subject to the
> following conditions:
>
> The above copyright notice and this permission notice shall be included
> in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
> OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
> MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
> NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
> DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
> OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
> USE OR OTHER DEALINGS IN THE SOFTWARE.

All other fixtures are synthetic (`fixture_*`) or recorded pub.dev API
responses.
