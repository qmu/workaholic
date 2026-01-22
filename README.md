# cc-market-place-internal

Private marketplace for internal team.

## Installation

```bash
claude
```

```bash
/plugin marketplace add qmu/cc-market-place-internal
```

Choose user scope, and better enable auto-updates.

## Structure

```
cc-market-place-internal/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── core/              # Core development commands
│   │   ├── commands/      # branch, commit, pull-request
│   │   ├── skills/        # refer-cc-document
│   │   ├── agents/        # discover-project, discover-claude-dir
│   │   └── rules/         # general, typescript
│   └── tdd/               # Ticket-driven development
│       ├── commands/      # ticket, drive
│       └── skills/        # archive-ticket
└── README.md
```

## Author

tamurayoshiya <a@qmu.jp>
