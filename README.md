cclite
======

A ComputerCraft emulator written in Lua using the [LÖVE][link-to-love] game engine

![Screenshot Demo][image-screenshot-1]

Features
--------
- Lightweight, a simplistic emulator that doesn't get in your way
- Support for _most_ apis
- Cross-platform support, works flawlessly on OSX, Windows and Linux
- Open Source!

Issues and ToDo
--------
- There are `TODO` tags amongst the source
- See issues: [https://github.com/Sorroko/cclite/issues][link-to-issues]

Installation
------------
Downloads are available for Windows and OSX
[https://github.com/Sorroko/cclite/releases][link-to-releases]

For manual installation or Linux:

1. Download the latest version of [Love2D][link-to-love]

2. Run the .love file, `love example.love`

Working with the source
------------
You will need [Apache Ant][apache-ant] in order to build from source.

Once installed execute `ant` in the root directory to see all available commands

`ant run` and `ant debug` will run the source assuming you have `love` in your path.

The ant script will build all distributions, you can run individual builds or build all with `ant all`

NOTE: In order to build an android apk you will need the android sdk and the android ndk in your path! Make sure you set all environment variables correctly. Do not use NDK version 10 as it causes the app to crash.

For more information on setting up to build an android version: [Building LÖVE for Android - Linux][https://bitbucket.org/MartinFelis/love-android-sdl2/wiki/Building%20L%C3%96VE%20for%20Android%20-%20Linux]

FAQ
------------
**Where do my files get saved?**

They are saved in the following places depending on your OS:

- Windows XP: `C:\Documents and Settings\user\Application Data\cclite` or `%appdata%\cclite`
- Windows Vista and above: `C:\Users\user\AppData\Roaming\cclite` or `%appdata%\cclite`
- Linux: `$HOME/cclite` or `~/.local/share/cclite`
- Mac OSX: `/Users/user/Library/Application Support/cclite`

NOTE: Files may be saved to `some/path/love/cclite` rather than `some/path/cclite` when running from source or the .love file. This does not apply to native builds.

License
-------
Copyright 2014 Sorroko

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

- Full license: [Apache License, Version 2][apache-license]


[image-screenshot-1]:https://dl.dropboxusercontent.com/u/53730212/cclove_demo.png
[link-to-love]:http://love2d.org/
[apache-ant]:http://ant.apache.org/
[link-to-releases]:https://github.com/Sorroko/cclite/releases
[link-to-issues]:https://github.com/Sorroko/cclite/issues
[apache-license]:http://www.apache.org/licenses/LICENSE-2.0.html
