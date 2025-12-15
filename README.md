# Chorus Box For Apple

SwiftUI-first clients for Chorus Box across iOS, macOS, tvOS, widgets, intents, and system extensions. Ships a shared app shell with thin platform wrappers so features and runtime boot code stay unified.

## Architecture
- Shared runtime: `AppRuntime` bootstraps `LibboxBootstrapper` + `ChorusBoxConfiguration` exactly once per process; platform hooks only override configuration/paths (`FilePath`) before boot.
- State: `AppShellState` composes `ProfileStore` (profile load/register/update) and `LogStreamStore` (log client lifecycle) so views stay decoupled from command clients.
- Navigation: `NavigationFeatureRegistry` holds page metadata/builders; hosts (app shells, widgets, intents, menu bar) query descriptors instead of hardcoding pages.
- UI: SwiftUI by default with thin UIKit/AppKit wrappers only when required by platform APIs.

## Profile Bootstrapping
- Profiles live in the shared App Group DB (`settings.db`, GRDB-backed) under `Library/Database`.
- At launch, `AppRuntime` configures `ChorusBoxConfiguration` and `FilePath` overrides; `ProfileStore` loads/updates `ExtensionProfile` and triggers `LogStreamStore` to connect/disconnect logs as profiles change.
- Background tasks (e.g., `ProfileUpdateTask`, `UIProfileUpdateTask`) refresh auto-update profiles and keep widgets/intents in sync.

## Project Structure
- `Library/` — Shared Swift modules (Database, Network, Shared utilities, Navigation registry).
- `ApplicationLibrary/` — Reusable SwiftUI views, services, and app delegates (`ChorusBoxMobileAppDelegate`, `ChorusBoxMacAppDelegate`).
- Platform targets — `SFI` (iOS), `SFM` (macOS), `SFT` (tvOS), `WidgetExtension`, `IntentsExtension`, `SystemExtension`, `Extension`, `TVExtension`, `MacLibrary`.
- `openspec/` — Spec-driven change tracking (proposals, tasks, spec deltas).

## Documentation
[SFI](https://sing-box.sagernet.org/installation/clients/sfi/) | [SFM](https://sing-box.sagernet.org/installation/clients/sfm/)

## Development
- Test suite: none (all test targets removed); rely on manual smoke tests per platform/extension.

## License

```
Copyright (C) 2022 by nekohasekai <contact-sagernet@sekai.icu>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
```1
