# Data Model

## Marketplace

```
Marketplace
├── name: string
├── version: semver
├── description: string
├── owner: Owner
└── plugins: Plugin[]

Owner
├── name: string
└── email: string
```

## Plugin

```
Plugin
├── name: string
├── version: semver
├── description: string
├── author: Author
├── source: path
├── category: string
├── commands: Command[]
├── skills: Skill[]
└── agents: Agent[]

Author
├── name: string
└── email: string
```

## Skill

```
Skill
├── name: string
├── description: string
├── topics: Topic[]
└── templates: Template[]

Topic
├── name: string
├── content: markdown
└── customization: Option[]

Template
├── name: string
└── content: markdown
```

## Documentation

```
Documentation
├── index: README.md
├── user: UserDoc[]
└── developer: DevDoc[]

UserDoc (3 types)
├── GETTING_STARTED.md
├── USER_GUIDE.md
└── FAQ.md

DevDoc (9 types)
├── FEATURES.md
├── ARCHITECTURE.md
├── NFR.md
├── API.md
├── DATA_MODEL.md
├── CONFIGURATION.md
├── SECURITY.md
├── TESTING.md
└── DEPENDENCIES.md
```
