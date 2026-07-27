# CHANGELOG (v0.2.x)

## 0.2.5 🚀 (2026-07-27)

### Backwards incompatible changes for 0.2.4
 * None

### Bug fixes
 * [`PULL-8`](https://github.com/thiagoesteves/jellyfish/pull/8) Fixed a crash (`MatchError`) in the appup compiler tasks when generation or copying hit an error; they now return a proper compiler diagnostic instead of crashing the release build
 * [`PULL-12`](https://github.com/thiagoesteves/jellyfish/pull/12) Fixed an incorrect `@spec` on `Jellyfish.Cache.store_app_version/2`
 * [`PULL-13`](https://github.com/thiagoesteves/jellyfish/pull/13) Fixed `mix hex.build`/`mix hex.publish` failing due to an empty, untracked `priv/` directory listed in the package files

### Enhancements
 * [`PULL-11`](https://github.com/thiagoesteves/jellyfish/pull/11) Removed `Jellyfish.Releases.Appup.make/6` (the unused `transforms` argument was dropped); use `make/5`
 * [`PULL-9`](https://github.com/thiagoesteves/jellyfish/pull/9) Added a project logo and fixed a copy-pasted license attribution in the README
 * [`PULL-10`](https://github.com/thiagoesteves/jellyfish/pull/10) Increased test coverage from ~43% to ~80%
 * [`PULL-12`](https://github.com/thiagoesteves/jellyfish/pull/12) Documented `Jellyfish.generate/1` and added missing `@typedoc`s across `Jellyfish.Releases.Appup`
 * [`PULL-13`](https://github.com/thiagoesteves/jellyfish/pull/13) Added `mix_audit` dependency vulnerability scanning and an enforced coverage threshold to CI

# 🚀 Previous Releases
 * [0.2.4 🚀 (2025-12-18)](https://github.com/thiagoesteves/jellyfish/blob/v0.2.4/CHANGELOG.md)
 * [0.2.3 🚀 (2025-11-12)](https://github.com/thiagoesteves/jellyfish/blob/v0.2.3/CHANGELOG.md)
 * [0.2.2 🚀 (2025-04-08)](https://github.com/thiagoesteves/jellyfish/blob/v0.2.2/CHANGELOG.md)
 * [0.2.1 🚀 (2025-04-07)](https://github.com/thiagoesteves/jellyfish/blob/v0.2.1/CHANGELOG.md)
 * [0.2.0 🚀 (2025-04-05)](https://github.com/thiagoesteves/jellyfish/blob/v0.2.0/CHANGELOG.md)
 * [0.1.4 🚀 (2024-10-10)](https://github.com/thiagoesteves/jellyfish/blob/0.1.4/CHANGELOG.md)