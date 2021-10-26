# Scar - A Crystal Game Library/Engine with Batteries included

[![GitHub release](https://img.shields.io/github/release/vypxl/scar.svg?sort=semver)](https://github.com/vypxl/scar/releases)
[![Build Status](https://img.shields.io/github/workflow/status/vypxl/scar/on_push)](https://github.com/vypxl/scar/actions/workflows/on_push.yml)
[![Book OUTDATED](https://img.shields.io/badge/Documentation_OUTDATED_SEE_REFERENCE-Gitbook-blueviolet.svg)](https://vypxl.gitbook.io/scar/)
[![Reference](https://img.shields.io/badge/Reference-Crystal%20Docs-informational.svg)](https://vypxl.github.io/scar/)

A 2D game engine written in Crystal using crsfml

## Motivation

This library aims to offer a simple interface for game programming with less
boilerplate code. I mainly create it for my own games, for my own education
and of course for the fun.

## Features

- Event system
- Configurable input handling
- Universal 2D Vector class
- Entity-Component-System architecture
- Configuration manager
- Asset manager with hot-reloading
- Inbetweening
- [Tiled](https://github.com/mapeditor/tiled) map support
- Some builtin components and systems

## Planned Features

- Sound manager
- Video playback

## Examples

You can find examples in the [examples](https://github.com/vypxl/scar/tree/main/examples) directory.
To run an example, execute the following command in your terminal, while in the root directory of this repo:

```bash
crystal run examples/<example-name>/main.cr

# e. g.
crystal run examples/hello_world/main.cr
```

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  scar:
    github: vypxl/scar
    branch: main
```

If you run into build/linking problems, please check if you have SFML installed properly, as described in the
[CrSFML Guide](https://github.com/oprypin/crsfml/blob/master/README.md#Installation). You **do not** need to add
CrSFML as a dependency!

## Feature Requests

Feature requests are welcome, just open an issue!

## Contributing

1. Create an [Feature Request] Issue
2. Fork it ( https://github.com/vypxl/scar/fork )
3. (optional) Create the git hook checks via `$ scripts/create-git-hooks`
4. Create your feature branch (git checkout -b my-new-feature)
5. Commit your changes (git commit -am 'Add some feature')
6. Push to the branch (git push origin my-new-feature)
7. Create a new Pull Request and mention your issue

You have to ensure that `crystal spec` and `crystal tool format --check ./src ./spec` return 0.

## Contributors

- [vypxl](https://github.com/vypxl) vypxl - creator, maintainer
