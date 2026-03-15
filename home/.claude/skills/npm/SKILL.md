---
name: npm
description: Read when running npm commands
---

# NPM Rules

- **Use the install script instead of `npm install`**: When installing packages, use `node ~/.cursor/skills/npm/scripts/install.js [--dev] <package1> [package2] ...` instead of `npm install`. This script automatically:
  - Checks for `.nvmrc` and runs `nvm use` if present
  - Gets the latest versions of packages (if no version/tag specified)
  - Automatically installs `@types/*` packages when available
  - Installs all packages in a single call
  - Works relative to the current working directory (where you call it from)
- **Package versioning**: Do NOT include version tags like `@latest` or `@^1.0.0` in package names. The script will automatically fetch and add the latest version. However, if you do include a version/tag (e.g., `package@latest` or `package@^1.0.0`), the script will use it as-is without adding another version specifier.
- Never ever change code inside node_modules

This file is in `~/.cursor/skills/npm/` - take all paths as relative to it. Script: [scripts/install.js](./scripts/install.js)
