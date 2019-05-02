# Scar - A Crystal Game Library/Engine with Batteries included [WIP - expect breaking changes]

[![GitHub release](https://img.shields.io/github/release/vypxl/scar.svg)](https://github.com/vypxl/scar/releases)
[![Build Status](https://travis-ci.org/vypxl/scar.svg?branch=master)](https://travis-ci.org/vypxl/scar)

A 2D game engine written in Crystal using crsfml; inspired by Glove

[Reference](https://vypxl.github.io/scar/)
[Book](https://vypxl.gitbook.io/scar/)

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

- All Physics related stuff
- Video playback
- More features I cannot think of right now but will in my dev process ^^ + your proposals/contributions

## Installation

Follow [Crsfml](https://github.com/oprypin/crsfml).
YOU HAVE TO INSTALL CRSFML MANUALLY.

Then add this to your application's `shard.yml`:

```yaml
dependencies:
  scar:
    github: vypxl/scar
```

Documentation is coming soon.

## Feature Requests

Feature requests are welcome, just open an issue!

## Contributing

1. Create an [Feature Request] Issue
2. Fork it ( https://github.com/vypxl/scar/fork )
3. Create your feature branch (git checkout -b my-new-feature)
4. Commit your changes (git commit -am 'Add some feature')
5. Push to the branch (git push origin my-new-feature)
6. Create a new Pull Request and mention your issue

## Contributors

- [vypxl](https://github.com/vypxl) vypxl - creator, maintainer
