---
name: javascript
description: Read when working with *.js files
---

# JavaScript Rules

## Do's
- Be ruthless with typos, don't let them slip
- Prefer native functions over custom or Lodash's
- Use Lodash helpers instead of custom solutions: `_.isObject()`, `_.omitBy()`
- Maintain consistency in naming and problem-solving
- Write simple, and clean code that is indistinguishable from the existing one
- Use modern (ES6) solutions, e.g. Object destructuring
- Use `async`/`await` instead of callbacks or `.then()` Promises
- Use early returns to avoid deep nesting
- Prefer arrow functions for simple expressions: `exports.int = num => parseInt(num)`
- Use parentheses for arrow function parameters even when single: `(ctx, next) => {}`
- Prefer `for...of` over traditional for loops: `for (const item of list)`
- Use `Object.entries()` for object iteration: `for (const [key, value] of Object.entries(obj))`
- Prefer native array methods: `.map()`, `.filter()`, `.find()`, `.includes()`
- Use spread operator for copying: `{ ...options }`
- Use object destructuring: `const { schema, ...opts } = options`
- Use template literals for interpolation: \`Result: ${value}\`
- Use single quotes for simple strings: 'Hello world'
- Use ternary for simple conditions: `const result = condition ? valueA : valueB`
- Use logical operators for defaults: `const name = user.name || 'Unknown'`
- Prefer explicit comparisons: `if (value === null)` not `if (!value)`
- Include context in error messages
- Use custom error classes when appropriate: `IgnoreError`
- Attach additional context to errors: `err.response = rawResponse`
- Group requires at the top in logical order (Node.js built-ins, third-party, local)

## Don'ts
- Never use ES6 modules, always use CommonJS require/exports
- Avoid callbacks or `.then()` Promises
- Avoid deep nesting (use early returns instead)
- Avoid traditional for loops (use `for...of` instead)
- Avoid implicit truthiness checks when checking for null/undefined

## Naming

- Use simple, consistent names. When in doubt, name by type (e.g., `user`, `task`)
- Generally name variables with a single word unless too ambiguous
- Always camelCase for variables and functions, never snake_case
- Use PascalCase for constructors and classes
- Use UPPER_SNAKE_CASE for constants
- Error variables must be called `err`
- Event variables must be called `e`

## Module structure
- Use CommonJS require/exports (not ES6 modules)
- Group requires at the top in logical order (Node.js built-ins, third-party, local)
- Commands: Export `handler`, `description`, `role`
- Controllers: Export multiple related functions
- Integrations: Export client instance and helper functions
- Middlewares: Export `handler`, `description`, optionally `order`
- Utils: Export multiple utility functions as properties

## Comments
- Use JSDoc comments for complex functions: `/** Convert timestamps to milliseconds */`
- TODO comments: `// TODO: Description`
- FIXME comments: `// FIXME: This is not the logic`
