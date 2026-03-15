#!/usr/bin/env node
/**
 * Updates _prisma_migrations checksum after manually editing a migration file.
 * Run from project root. Delegates to execute-sql skill's sql.sh.
 *
 * Usage: node ~/.cursor/skills/prisma/scripts/update-hash.js [migration_name]
 * If no name given, uses the latest migration folder.
 */

const crypto = require('crypto')
const fs = require('fs')
const path = require('path')
const { execFileSync } = require('child_process')

const sqlSh = path.join(path.dirname(__dirname), '..', 'execute-sql', 'scripts', 'sql.sh')

function findProjectDir() {
  let dir = process.cwd()
  while (dir !== '/') {
    if (fs.existsSync(path.join(dir, 'prisma', 'migrations'))) {
      return dir
    }
    dir = path.dirname(dir)
  }
  throw new Error('prisma/migrations not found (run from project root)')
}

function main() {
  const projectDir = findProjectDir()
  const migrationsDir = path.join(projectDir, 'prisma', 'migrations')

  let name = process.argv[2] || ''
  if (!name) {
    const entries = fs.readdirSync(migrationsDir, { withFileTypes: true })
    const migrations = entries.filter(e => e.isDirectory()).map(e => e.name).sort()
    name = migrations[migrations.length - 1]
    console.log(`Using last migration: ${name}`)
  }

  const migrationPath = path.join(migrationsDir, name, 'migration.sql')
  if (!fs.existsSync(migrationPath)) {
    throw new Error(`Migration not found: ${migrationPath}`)
  }

  const content = fs.readFileSync(migrationPath, 'utf8')
  const checksum = crypto.createHash('sha256').update(content).digest('hex')
  const sql = `UPDATE "_prisma_migrations" SET checksum = '${checksum}' WHERE migration_name = '${name}'`

  execFileSync('bash', [sqlSh, sql], { cwd: projectDir, stdio: 'inherit' })
  console.log(`Updated migration ${name} to checksum: ${checksum}`)
}

main()
