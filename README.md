# Attention!
As I did not have that much time the past weeks, the development came to a halt for this library. I already started to build some components and spent some time with my other library https://github.com/colonlc/serialize.cr which will cover the full serialization feature I planned. But I will not be here to develop anything for the next month or so, so please have patience. After that I will finish this and write documentation. Nothing is forgotten or cancelled.

# Scar - A Crystal Game Library/Engine with Batteries included [WIP - expect breaking changes]

[![GitHub release](https://img.shields.io/github/release/colonlc/scar.svg)](https://github.com/colonlc/scar/releases)
[![Build Status](https://travis-ci.org/colonlc/scar.svg?branch=master)](https://travis-ci.org/colonlc/scar)

A 2D game engine written in Crystal using crsfml, crystal-chipmunk and
msgpack-crystal; inspired by Glove

## Motivation

This library aims to offer a simple interface for game programming with less
boilerplate code. I mainly create it for my own games, for my own educational
purpose and of course for the fun.

## Features

- Event system
- Configurable input handling
- Universal 2D Vector class
- Entity-Component-System
- Configuration manager
- Tween
- Asset manager
- Easy to use scene/game state serialization for savegames. - Will be outsourced into https://github.com/colonlc/serialize.cr

## Not yet implemented features

- Builtin Components and Systems e.g. position, drawable, physics, etc.
- More features I cannot think of right now but will in my dev process ^^ + your proposals/contributions

## Installation

Follow [Crsfml](https://github.com/oprypin/crsfml) and
[crystal-chipmunk](https://github.com/oprypin/crystal-chipmunk)'s install guides
(they are dependencies).

Then add this to your application's `shard.yml`:

```yaml
dependencies:
  scar:
    github: colonlc/scar
```

Documentation is coming when I finished the library core.

## Feature Requests

Feature requests are welcome, just open an issue!

## Contributing

1. Create an [Feature Request] Issue
2. Fork it ( https://github.com/colonlc/scar/fork )
3. Create your feature branch (git checkout -b my-new-feature)
4. Commit your changes (git commit -am 'Add some feature')
5. Push to the branch (git push origin my-new-feature)
6. Create a new Pull Request and mention your issue

## Contributors

- [colonlc](https://github.com/colonlc) colonlc - creator, maintainer
