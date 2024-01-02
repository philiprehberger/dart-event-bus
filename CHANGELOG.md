# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-04-03

### Added
- Initial release
- `EventBus` class for typed, decoupled event communication
- `fire<T>()` to dispatch events by type
- `on<T>()` to subscribe to events via typed `Stream<T>`
- `fireSticky<T>()` to dispatch sticky events that replay to new subscribers
- `lastSticky<T>()` to retrieve the last sticky event of a given type
- `clearSticky<T>()` to remove a stored sticky event
- `dispose()` to close the bus and release resources
- Zero external dependencies
