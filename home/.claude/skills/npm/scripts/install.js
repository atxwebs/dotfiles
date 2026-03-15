#!/usr/bin/env node
/* Install NPM dependencies to their latest versions */
const { execSync } = require('child_process');
const { existsSync } = require('fs');
const { join } = require('path');

// Format: node install.js [--dev] <package1> [package2] ...
// Example: node install.js --dev vitest
// Example: node install.js react react-dom

function main() {
  const args = process.argv.slice(2);
  const isDev = args[0] === '--dev';
  const packages = isDev ? args.slice(1) : args;

  if (!packages.length) {
    console.error('Usage: node install.js [--dev] <package1> [package2] ...');
    process.exit(1);
  }

  // Get the current working directory (where the script is called from)
  const cwd = process.cwd();
  
  // Check for .nvmrc and run nvm use if it exists
  const nvmrcPath = join(cwd, '.nvmrc');
  if (existsSync(nvmrcPath)) {
    console.log('Found .nvmrc, running nvm use...');
    try {
      execSync('source ~/.nvm/nvm.sh && nvm use', { 
        cwd,
        stdio: 'inherit',
        shell: '/bin/bash'
      });
    } catch (err) {
      console.error('Failed to run nvm use:', err.message);
      process.exit(1);
    }
  }

  const deps = [];
  const devDeps = [];

  for (const pkg of packages) {
    try {
      // Check if package already has a version/tag specified (e.g., package@latest, package@^1.0.0)
      // For scoped packages: @scope/name has 1 @, @scope/name@version has 2 @
      // For unscoped packages: name has 0 @, name@version has 1 @
      const atCount = (pkg.match(/@/g) || []).length;
      const hasVersion = pkg.startsWith('@') ? atCount >= 2 : atCount >= 1;
      let fullPkg;
      
      if (hasVersion) {
        // Use the package as-is if version/tag is already specified
        fullPkg = pkg;
      } else {
        // Get latest version and add it
        const version = execSync(`npm view ${pkg} version`, { 
          encoding: 'utf8',
          cwd 
        }).trim();
        fullPkg = `${pkg}@^${version}`;
      }
      
      if (isDev) {
        devDeps.push(fullPkg);
      } else {
        deps.push(fullPkg);
      }

      // For scoped packages like @faker-js/faker, use @types/faker-js__faker
      // For unscoped packages like lodash, use @types/lodash
      // Extract base package name (without version/tag) for @types lookup
      // Split by @ and take first part(s): @scope/name@version -> @scope/name, name@version -> name
      const parts = pkg.split('@');
      const basePkg = pkg.startsWith('@') 
        ? `@${parts[1]}` // @scope/name@version -> @scope/name
        : parts[0];      // name@version -> name
      const typesPkg = basePkg.startsWith('@')
        ? `@types/${basePkg.slice(1).replace('/', '__')}`
        : `@types/${basePkg}`;
      try {
        execSync(`npm view ${typesPkg} version`, { 
          encoding: 'utf8', 
          stdio: 'ignore',
          cwd 
        });
        const typesVersion = execSync(`npm view ${typesPkg} version`, { 
          encoding: 'utf8',
          cwd 
        }).trim();
        devDeps.push(`${typesPkg}@^${typesVersion}`);
        console.log(`Found types: ${typesPkg}@^${typesVersion}`);
      } catch {
        // No @types package exists, skip
      }
    } catch (err) {
      console.error(`Failed to get version for ${pkg}:`, err.message);
      process.exit(1);
    }
  }

  // Install all packages in a single call
  // If --dev flag, all packages (including @types) go to devDeps
  // Otherwise, regular packages go to deps, @types go to devDeps
  if (isDev) {
    // All packages as devDeps in one call
    const allPackages = [...devDeps];
    if (allPackages.length) {
      console.log(`Installing dev dependencies: ${allPackages.join(' ')}`);
      execSync(`npm install --save-dev ${allPackages.join(' ')}`, { 
        stdio: 'inherit',
        cwd 
      });
    }
  } else {
    // Regular deps and devDeps (@types) - install user packages in one call, @types separately if needed
    if (deps.length) {
      console.log(`Installing dependencies: ${deps.join(' ')}`);
      execSync(`npm install ${deps.join(' ')}`, { 
        stdio: 'inherit',
        cwd 
      });
    }
    if (devDeps.length) {
      console.log(`Installing dev dependencies: ${devDeps.join(' ')}`);
      execSync(`npm install --save-dev ${devDeps.join(' ')}`, { 
        stdio: 'inherit',
        cwd 
      });
    }
  }
}

main();
