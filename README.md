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
Executables are available for Windows and OSX

For manual installation (Linux):

1. Download the latest version of [Love2D][link-to-love]

2. Run the .love file available

Building from source
------------
Windows:

1. Create a directory called `love-dist/` and another called `build/`

2. Place the latest version of love for Windows, (love.exe and dlls) into the `love-dist/windows/` folder

3. Place the latest version of love for OSX, (love.app) into the `love-dist/macosx/` folder

4. Run the `build_src.bat` script.

FAQ
------------
**Where do my files get saved?**

They are saved in the following places depending on your OS:

- Windows XP: `C:\Documents and Settings\user\Application Data\LOVE\cclite` or `%appdata%\LOVE\cclite`
- Windows Vista and above: `C:\Users\user\AppData\Roaming\LOVE\cclite` or `%appdata%\LOVE\cclite`
- Linux: `$HOME/love/cclite` or `~/.local/share/love/cclite`
- Mac OSX: `/Users/user/Library/Application Support/LOVE/cclite`

License
-------
- [Apache License, Version 2][apache-license]


[image-screenshot-1]:https://dl.dropboxusercontent.com/u/53730212/cclove_demo.png
[link-to-love]:http://love2d.org/
[link-to-issues]:https://github.com/Sorroko/cclite/issues
[apache-license]:http://www.apache.org/licenses/LICENSE-2.0.html
