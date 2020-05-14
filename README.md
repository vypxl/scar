# Scar - A Crystal Game Library/Engine with Batteries included

[![GitHub release](https://img.shields.io/github/release/vypxl/scar.svg)](https://github.com/vypxl/scar/releases)
[![Build Status](https://travis-ci.org/vypxl/scar.svg?branch=master)](https://travis-ci.org/vypxl/scar)

A 2D game engine written in Crystal using crsfml

[![Book](https://img.shields.io/badge/Documentation-Gitbook-blueviolet.svg)](https://vypxl.gitbook.io/scar/)
[![Reference](https://img.shields.io/badge/Reference-Crystal%20Docs-informational.svg)](https://vypxl.github.io/scar/)

Examples can be found [here](https://github.com/vypxl/scar_examples)

**Until version 1.0, everything is subject to change!**

## Motivation

This library aims to offer a simple interface for game programming with less
boilerplate code. I mainly create it for my own games, for my own education
and of course for the fun.

## Features

- Event system
- Configurable input handling
- Universal 2D Vector class
- Entity-Component-System
- Configuration manager
- Tween
- Asset manager
- Some Builtin Components and Systems, will be expanded in the future

## Not yet implemented features

- Sound Manager
- Video playback
- More features I cannot think of right now but will in my dev process ^^ + your proposals/contributions

## Installation

Use the `scripts/crsfml` script to install crsfml into `lib/`

OR

Follow the [Crsfml](https://github.com/oprypin/crsfml) manual installation instructions.

Then add this to your application's `shard.yml`:

```yaml
dependencies:
  scar:
    github: vypxl/scar
```

To run your application, you have to make voidcsfml visible to ld.
To do that, you can either manually export the environment variables as
described in the crsfml guide or prepend the `scripts/run` command to
everything you want to run. You can just copy the scripts from the folder
inside this repo

```sh
# no
crystal run src/main.cr

# yes
scripts/run crystal run src/main.cr
```

## Feature Requests

Feature requests are welcome, just open an issue!

## Contributing

1. Create an [Feature Request] Issue
2. Fork it ( https://github.com/vypxl/scar/fork )

Then create the git hook checks via `$ scripts/create-git-hooks`.
You have to ensure that `crystal spec` and `crystal tool format [./src / ./spec]`
return 0.

3. Create your feature branch (git checkout -b my-new-feature)
4. Commit your changes (git commit -am 'Add some feature')
5. Push to the branch (git push origin my-new-feature)
6. Create a new Pull Request and mention your issue

## Contributors

- [vypxl](https://github.com/vypxl) vypxl - creator, maintainer
