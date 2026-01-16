## TypeScript Coding Conventions

- **Use path aliases for imports** - Use path aliases (e.g., `@lib/*`, `@utils/*`) instead of relative imports (`../`). Only use `./` for same-directory imports.
- **Avoid `any`** - Use `unknown` instead of `any` as the first option
- **Avoid `as` type assertions** - Prefer type guards, type narrowing, or proper typing over `as` keyword
- **Use `type` over `interface`** - Prefer `type` keyword for type definitions instead of `interface`
- **Use `undefined` over `null`** - Prefer `undefined` to express emptiness or absence of a value
- **Inline single-use types** - If a type is not exported and only used once, inline it in the function signature instead of declaring separately
- **Avoid unnecessary optionals** - Do not make arguments or properties optional (`?`) without a concrete reason; optional properties are a common source of bugs
- **Avoid unused arguments** - Do not add underscore-prefixed arguments (`_arg`) just to silence compilation errors; fix the underlying type issue instead
- **Delete dead code immediately** - When you find unused exports, components, or functions, delete them right away; always grep for usage before editing code
