# cc-market-place-internal

Private marketplace for internal team.

## Installation

```bash
claude /install workaholic --marketplace tamurayoshiya/cc-market-place-internal
```

Or add to `~/.claude/settings.json` for global use:

```json
{
  "plugins": ["tamurayoshiya/cc-market-place-internal:workaholic"]
}
```

## Structure

```
cc-market-place-internal/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   └── workaholic/
│       ├── .claude-plugin/plugin.json
│       ├── skills/
│       ├── agents/
│       ├── commands/
│       └── rules/
└── README.md
```

## Author

tamurayoshiya <a@qmu.jp>
