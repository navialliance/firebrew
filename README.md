## firebrew
Self-maintained [Homebrew](https://brew.sh/) repository.

`tree`
```
.
├── audit_exceptions
│   └── github_prerelease_allowlist.json
├── Casks
│   ├── aya.rb
│   ├── pcsx2.rb
│   ├── rquickshare.rb
│   ├── uad-ng.rb
│   └── vencordinstaller.rb
├── README.md
└── scripts
    ├── casks-config.sh
    ├── process-casks.sh
    └── update-cask.sh
```

### Adding the Tap

To add this tap to your Homebrew installation:

```bash
brew tap navialliance/firebrew https://github.com/navialliance/firebrew
```

### App Installation

```bash
brew install --cask navialliance/firebrew/appname
```
or
```
brew install --cask appname #if there's no duplicate casks
```

### Removing the Tap

> [!NOTE]
> You should remove any installed apps from this tap before removing the tap.

To remove this tap from your Homebrew installation:
```bash
brew untap navialliance/firebrew
```
