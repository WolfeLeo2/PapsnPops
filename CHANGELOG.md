# Changelog

## [1.7.0](https://github.com/WolfeLeo2/PapsnPops/compare/v1.6.0...v1.7.0) (2026-06-09)


### Features

* auto update support for Android via apk ([61dc7eb](https://github.com/WolfeLeo2/PapsnPops/commit/61dc7eb1091f08384ca2b64ec611af50a7183a6a))


### Bug Fixes

* restrict auto updater banner to windows only ([905ba13](https://github.com/WolfeLeo2/PapsnPops/commit/905ba13363ece06924cc30aedc3cf8be5bdfb8de))

## [1.6.0](https://github.com/WolfeLeo2/PapsnPops/compare/v1.5.0...v1.6.0) (2026-06-09)


### Features

* user and staff deletion + text qtystepper ([9bdf383](https://github.com/WolfeLeo2/PapsnPops/commit/9bdf3836933c3ce7a7b479a6c3035a75a6082ede))

## [1.5.0](https://github.com/WolfeLeo2/PapsnPops/compare/v1.4.0...v1.5.0) (2026-06-07)


### Features

* change default reorder level from 10 to 5 ([1c036d3](https://github.com/WolfeLeo2/PapsnPops/commit/1c036d3b290c4114628eeb4ced0d7d3387b61267))

## [1.4.0](https://github.com/WolfeLeo2/PapsnPops/compare/v1.3.2...v1.4.0) (2026-06-07)


### Features

* implement auto updater and tweak variant decommission UI ([a59abf3](https://github.com/WolfeLeo2/PapsnPops/commit/a59abf33be721aa9c61a81810453f53a1a798850))

## [1.3.2](https://github.com/WolfeLeo2/PapsnPops/compare/v1.3.1...v1.3.2) (2026-06-07)


### Bug Fixes

* add missing app_config.dart that was untracked ([f6bf4ba](https://github.com/WolfeLeo2/PapsnPops/commit/f6bf4ba62277541756dec32473aad80ca6c5fdb8))
* replace dotenv with dart-define for Windows compatibility ([6feb8d5](https://github.com/WolfeLeo2/PapsnPops/commit/6feb8d59bd8c0952df6ffa9171af27c9e58fb5a6))

## [1.3.1](https://github.com/WolfeLeo2/PapsnPops/compare/v1.3.0...v1.3.1) (2026-06-07)


### Bug Fixes

* skip firebase messaging initialization on windows to prevent silent crashes ([12eff0d](https://github.com/WolfeLeo2/PapsnPops/commit/12eff0d0e6633bde2a875f286c96b4cb9c92e3fd))

## [1.3.0](https://github.com/WolfeLeo2/PapsnPops/compare/v1.2.0...v1.3.0) (2026-06-07)


### Features

* add logout button to sidebar and disconnect powersync on logout ([5d58c29](https://github.com/WolfeLeo2/PapsnPops/commit/5d58c29a5577f8f689a24d7dae16f33139d5d124))

## [1.2.0](https://github.com/WolfeLeo2/PapsnPops/compare/v1.1.0...v1.2.0) (2026-06-07)


### Features

* add 'add new category' option in product form ([c280a1d](https://github.com/WolfeLeo2/PapsnPops/commit/c280a1d12c66f120ccea6645618cc4c1d1ef4678))
* add stock validation when adding items to cart and tabs ([e83eb8b](https://github.com/WolfeLeo2/PapsnPops/commit/e83eb8b0aaf259d0f08abcc538ce34dc0f50b4cc))


### Bug Fixes

* foreground local notifications on iOS and update Android icon reference ([c3aa6f7](https://github.com/WolfeLeo2/PapsnPops/commit/c3aa6f79069143d5be00e5407c0e26d20a0a9809))
* resolve flutter analyze errors and warnings for CI ([8ee2527](https://github.com/WolfeLeo2/PapsnPops/commit/8ee2527d4595cc9128973607179836f9e555828f))

## [1.1.0](https://github.com/WolfeLeo2/PapsnPops/compare/v1.0.3...v1.1.0) (2026-06-07)


### Features

* setup app icon, name, and enforce payment references ([a7e6d45](https://github.com/WolfeLeo2/PapsnPops/commit/a7e6d452247f8cadbd306bac2cc9eca98467f8c5))


### Bug Fixes

* resolve failing tests and CI analyze errors ([7b3c5df](https://github.com/WolfeLeo2/PapsnPops/commit/7b3c5df500e0cab8691ec85fa667c5b7381c69cb))

## [1.0.3](https://github.com/WolfeLeo2/PapsnPops/compare/v1.0.2...v1.0.3) (2026-06-06)


### Bug Fixes

* updated inno setup for actions ([358d9d9](https://github.com/WolfeLeo2/PapsnPops/commit/358d9d903f0af36b06d935021166ff791a448c17))

## [1.0.2](https://github.com/WolfeLeo2/PapsnPops/compare/v1.0.1...v1.0.2) (2026-06-06)


### Bug Fixes

* github actions pipeline config ([56cfc5b](https://github.com/WolfeLeo2/PapsnPops/commit/56cfc5bb37ba5b1c7afb4bdbe8d7c8177fbb12e5))

## [1.0.1](https://github.com/WolfeLeo2/PapsnPops/compare/v1.0.0...v1.0.1) (2026-06-06)


### Bug Fixes

* fixed github actions ([db32645](https://github.com/WolfeLeo2/PapsnPops/commit/db326450960d9cbae3f330e48d1c8c1e972fb7fa))

## 1.0.0 (2026-06-06)


### Features

* added fully automated CI/CD pipeline ([269378a](https://github.com/WolfeLeo2/PapsnPops/commit/269378a0b158e2e87250e05c1986310dfefc8841))
* **database:** Task 1 - Supabase schema migration and PowerSync schema updates for Phase 2 ([8ca9424](https://github.com/WolfeLeo2/PapsnPops/commit/8ca94246e8c0163a45db444263c84f97d21101fb))
* **data:** Task 3 - Implement repositories and variant-aware Postgres stock decrement trigger ([8bd1d81](https://github.com/WolfeLeo2/PapsnPops/commit/8bd1d81ad3d4b328bb39fa77bc126b1cd6a6906e))
* **domain:** Task 2 - Add domain models for Sale, SaleItem, OpenTab, TabItem, Customer, Invoice, and CartItem ([c6cb400](https://github.com/WolfeLeo2/PapsnPops/commit/c6cb4004bc5b151fc21f129fb07054102db4343d))
* implement comprehensive product management, POS, auth features, and PowerSync integration while updating phosphor_flutter dependencies. ([cda3d36](https://github.com/WolfeLeo2/PapsnPops/commit/cda3d361ab57fed372c321233a4100e51411ee0c))
* **pos:** Task 4 - Implement client-side promotion engine and POS providers with Riverpod ([f01252d](https://github.com/WolfeLeo2/PapsnPops/commit/f01252d1cf3ae55d23a5d0371913aacde5dd85da))
* **pos:** Task 5 - Implement responsive POS Screen, Product Grid, Cart Panel, Cart Item Row, and Payment Method Selector ([366b576](https://github.com/WolfeLeo2/PapsnPops/commit/366b5760fe65ac96d4e4a78227a8e4987d6f43cb))
* **pos:** Task 6 - Implement B2B Invoice Sheet and post-checkout Receipt Screen with print/share ([d3cbc2f](https://github.com/WolfeLeo2/PapsnPops/commit/d3cbc2f3d66c85bef745cd60e1365d4161c97981))
* **pos:** Tasks 7, 8, 9 - Implement Tabs Management, Sales History, navigation, and sidebar integration ([adc650f](https://github.com/WolfeLeo2/PapsnPops/commit/adc650f8fd0d005f0bdb474393929f54405a140a))


### Bug Fixes

* added packages folder ([a9b1135](https://github.com/WolfeLeo2/PapsnPops/commit/a9b113567e15df67385d9c15e9995a63bccf684a))
* edited dart analyze ([ac590ef](https://github.com/WolfeLeo2/PapsnPops/commit/ac590efb856407912bf93a26e07c1d8f2491306f))
