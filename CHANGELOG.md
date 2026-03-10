# Changelog

## [1.5.0](https://github.com/S1M0N38/claude.nvim/compare/v1.4.1...v1.5.0) (2026-03-10)


### Features

* **terminal:** add slot navigation and notification indicators ([d98a45e](https://github.com/S1M0N38/claude.nvim/commit/d98a45ec2d6757958af1156e3b10a6302bdea78f))


### Bug Fixes

* **send:** force terminal mode when opening after send ([84cff56](https://github.com/S1M0N38/claude.nvim/commit/84cff5661d9086c708520d4b678b269e3b8f766b))
* **types:** add diagnostic disable for closure variable usage ([44912e7](https://github.com/S1M0N38/claude.nvim/commit/44912e7a9ea140e028ebdd84b74f6ebec8a26d13))
* **types:** add param-type-mismatch to diagnostic disable comments ([f9957fc](https://github.com/S1M0N38/claude.nvim/commit/f9957fc4ee689d4fa997a5922349db0c2233da99))
* **types:** add type assertions for window handle and cursor ([4c26bfe](https://github.com/S1M0N38/claude.nvim/commit/4c26bfec58119bf275ee537629c9286f9d86e9ca))
* **types:** add type assertions in ensure_window for proper narrowing ([1ef576d](https://github.com/S1M0N38/claude.nvim/commit/1ef576de3d1084283ae24fe3d29bf86e184af853))
* **types:** correct luadoc syntax and type annotations ([677e982](https://github.com/S1M0N38/claude.nvim/commit/677e982ff5e70d7a99011c0ab7aad2df71e366ca))
* **types:** disable need-check-nil and param-type-mismatch diagnostics ([aef5a2e](https://github.com/S1M0N38/claude.nvim/commit/aef5a2ee0fca8379865591ef085e8394b84618d1))
* **types:** disable need-check-nil due to LuaLS closure limitations ([d854efb](https://github.com/S1M0N38/claude.nvim/commit/d854efb371ced6605ca026738134e7ab77624c5b))
* **types:** move diagnostic enable after variable usage ([5e07195](https://github.com/S1M0N38/claude.nvim/commit/5e07195851489fd95d444d57ca3fff68ab81b9cf))
* **types:** return window handle from ensure_window for proper typing ([11bf906](https://github.com/S1M0N38/claude.nvim/commit/11bf906c64b34f0c1d5ece92ac6826a17c645cb1))
* **types:** use [@cast](https://github.com/cast) directive for explicit type narrowing ([f554765](https://github.com/S1M0N38/claude.nvim/commit/f5547654436880fad31a3670380b4258d081a4bf))
* **types:** use assert() for proper type narrowing ([8c42f28](https://github.com/S1M0N38/claude.nvim/commit/8c42f28ad593892e7e2f716090fbff4880d92c8f))
* **types:** use assert() for type narrowing after validity checks ([7d7aaec](https://github.com/S1M0N38/claude.nvim/commit/7d7aaecdb7ee5c7edee74da047573cad0d4961d2))
* **types:** use block-style diagnostic disable ([2f90e65](https://github.com/S1M0N38/claude.nvim/commit/2f90e65ff30df9420650006f9ad2e892c2517a21))
* **types:** use diagnostic disable comments for false positives ([65cb928](https://github.com/S1M0N38/claude.nvim/commit/65cb928bebd4acf2b99163d6d8eca12ca16d1f61))
* **types:** use explicit type annotations and targeted diagnostic disable ([2d6d114](https://github.com/S1M0N38/claude.nvim/commit/2d6d114c1f1726abc45642fd044d3ac69e254519))
* **types:** use file-level diagnostic disable with explanation ([bd0c8a6](https://github.com/S1M0N38/claude.nvim/commit/bd0c8a61cce637c7ef612b467e70f3788ecf86b9))
* **types:** use inline type cast with diagnostic disable ([22c7cf1](https://github.com/S1M0N38/claude.nvim/commit/22c7cf1ddb21f44f9d99e9b406f6d3e2fc61c17c))
* **types:** use local type annotation for window narrowing ([3f04319](https://github.com/S1M0N38/claude.nvim/commit/3f0431913221780b0001bf1026aa322db657e488))
* **types:** use local variable declarations for type narrowing ([d67ac5d](https://github.com/S1M0N38/claude.nvim/commit/d67ac5d2e7f7e1261a0cff98f3bcd0db9f333ec7))
* **types:** use targeted diagnostic disable for closure limitations ([133af93](https://github.com/S1M0N38/claude.nvim/commit/133af93a80bf0032e2cce75521be1b62649f3435))


### Reverts

* restore proper typechecking ([bb2828c](https://github.com/S1M0N38/claude.nvim/commit/bb2828cbac4fcc36d8872783aae409eb32779450))

## [1.4.1](https://github.com/S1M0N38/claude.nvim/compare/v1.4.0...v1.4.1) (2026-02-13)


### Bug Fixes

* **terminal:** resolve type errors for nullable window handle ([3bbd442](https://github.com/S1M0N38/claude.nvim/commit/3bbd442b66cec5f101d4f606b91e5657326c11a9))

## [1.4.0](https://github.com/S1M0N38/claude.nvim/compare/v1.3.0...v1.4.0) (2026-02-10)


### Features

* **terminal:** auto-switch slot when displayed slot exits ([db6255b](https://github.com/S1M0N38/claude.nvim/commit/db6255b848f5c870b7b894d6f2ef5ee3ea726fc7))

## [1.3.0](https://github.com/S1M0N38/claude.nvim/compare/v1.2.0...v1.3.0) (2026-02-10)


### Features

* **terminal:** add multi-slot support for running multiple instances ([b509ee0](https://github.com/S1M0N38/claude.nvim/commit/b509ee0ab593af898f86774a7cbd81e404f2c393))


### Bug Fixes

* **types:** mark slot job field as optional to fix type error ([aa13a78](https://github.com/S1M0N38/claude.nvim/commit/aa13a7832521ba3e4e47df3dae746adf9e888b73))

## [1.2.0](https://github.com/S1M0N38/claude.nvim/compare/v1.1.0...v1.2.0) (2026-02-10)


### Features

* **explorer:** add file explorer to send references via mini.files ([8281cc2](https://github.com/S1M0N38/claude.nvim/commit/8281cc2e1d2ab17b06235a7ce4772429d461886e))
* **explorer:** integrate explorer into terminal, health, and types ([82edb59](https://github.com/S1M0N38/claude.nvim/commit/82edb598d91f0e8814a69b314bdc51f71b950cae))

## [1.1.0](https://github.com/S1M0N38/claude.nvim/compare/v1.0.0...v1.1.0) (2026-02-10)


### Features

* **picker:** add file picker to send references via snacks.nvim ([07a4e53](https://github.com/S1M0N38/claude.nvim/commit/07a4e53c49f443b61fcc75640ff348b8e0c34aa8))

## 1.0.0 (2026-02-10)


### Features

* **config:** add floating terminal configuration ([38735f7](https://github.com/S1M0N38/claude.nvim/commit/38735f78c72d485f7ab52d13491242e619246a00))
* **health:** rewrite checks for Claude Code dependencies ([d92cab0](https://github.com/S1M0N38/claude.nvim/commit/d92cab010e077d58a3ea7897e0fface086acb18e))
* **notify:** add notification forwarding and hook script ([ee15f8f](https://github.com/S1M0N38/claude.nvim/commit/ee15f8fca6783923f86dd4bacb5f02d6ba1985fa))
* **send:** add visual selection and file reference sending ([7fbecfc](https://github.com/S1M0N38/claude.nvim/commit/7fbecfc1d1e1975a5dab56544f5ea5d881437fdc))
* **terminal:** add floating terminal module ([59effad](https://github.com/S1M0N38/claude.nvim/commit/59effaddeae95f3938bd2afbf4aae80667b265d3))
* **types:** update LuaCATS definitions for new API ([ef58f89](https://github.com/S1M0N38/claude.nvim/commit/ef58f89edff367e12720e3bc8d540829e48ff44a))
* wire up public API and user commands ([7992ba0](https://github.com/S1M0N38/claude.nvim/commit/7992ba0ab713fa2ff0a8371ce7f2395e0941bcf5))
