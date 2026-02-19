---
name: supabase
description: Manage Supabase database migrations, schema changes, and CLI operations. Use when creating tables, modifying schema, or running database commands.
---

# Supabase Skill

Manage Supabase database operations including migrations, schema changes, and CLI commands.

## When to Use

- Creating new database tables
- Modifying existing schema
- Adding RLS policies
- Running migrations
- Generating TypeScript types
- Managing local Supabase instance

## Prerequisites

Ensure Supabase CLI is installed:
```bash
# Check if installed
supabase --version

# Install if needed (macOS)
brew install supabase/tap/supabase
```

## Creating Migrations

### Step 1: Create Migration File

```bash
# Create a new migration
supabase migration new <migration_name>

# Example
supabase migration new add_captures_table
```

This creates a file at `supabase/migrations/<timestamp>_<migration_name>.sql`

### Step 2: Write Migration SQL

```sql
-- Example: Create a new table
CREATE TABLE captures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  user_role TEXT NOT NULL,
  platform TEXT NOT NULL
);

-- Always enable RLS on new tables
ALTER TABLE captures ENABLE ROW LEVEL SECURITY;

-- Add appropriate policies
CREATE POLICY "Allow anonymous read" ON captures
  FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert" ON captures
  FOR INSERT WITH CHECK (true);
```

### Step 3: Apply Migration

```bash
# Apply to local Supabase
supabase db push

# Or reset and replay all migrations
supabase db reset
```

## Common Operations

### Start Local Supabase

```bash
# Start local instance
supabase start

# Stop local instance
supabase stop
```

### Generate TypeScript Types

```bash
# Generate types from remote database
supabase gen types typescript --project-id <project-id> > src/types/database.ts

# Generate types from local database
supabase gen types typescript --local > src/types/database.ts
```

### Check Migration Status

```bash
# List migrations
supabase migration list

# Check diff between local and remote
supabase db diff
```

### Link to Remote Project

```bash
# Link to existing Supabase project
supabase link --project-ref <project-id>
```

## Migration Best Practices

### DO

1. **Always enable RLS** on new tables
2. **Add appropriate policies** for security
3. **Use descriptive migration names** (`add_user_profiles`, `create_captures_table`)
4. **Keep migrations small** and focused
5. **Test locally first** before pushing to remote

### DON'T

1. **Don't modify existing migrations** that have been applied
2. **Don't use `DROP TABLE`** without careful consideration
3. **Don't forget RLS policies** - tables are public by default without them

## RLS Policy Patterns

### Public Read, Authenticated Write

```sql
-- Anyone can read
CREATE POLICY "Public read" ON table_name
  FOR SELECT USING (true);

-- Only authenticated users can insert
CREATE POLICY "Authenticated insert" ON table_name
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');
```

### User Owns Row

```sql
-- Users can only see their own rows
CREATE POLICY "Users see own rows" ON table_name
  FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert rows for themselves
CREATE POLICY "Users insert own rows" ON table_name
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own rows
CREATE POLICY "Users update own rows" ON table_name
  FOR UPDATE USING (auth.uid() = user_id);
```

### Anonymous Access (Development/Demo Only)

```sql
-- Allow all operations for anonymous users (use cautiously!)
CREATE POLICY "Allow anonymous access" ON table_name
  FOR ALL USING (true) WITH CHECK (true);
```

## Autonomous Implementation Pattern

When implementing features that need database changes:

### 1. Create Migration

```bash
supabase migration new <feature_name>
```

### 2. Write SQL

Add the migration SQL to the generated file.

### 3. Update TypeScript Types

After migration, regenerate types:
```bash
supabase gen types typescript --local > src/types/database.ts
```

Or manually update `src/types/database.ts` to match the new schema.

### 4. Document in PR

Include the migration SQL in the PR description so reviewers can:
- Review the schema changes
- Run the migration manually if needed

### 5. Commit Migration File

```bash
git add supabase/migrations/
git commit -m "Add migration for <feature>"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `supabase: command not found` | Install CLI: `brew install supabase/tap/supabase` |
| Migration fails locally | Check SQL syntax, run `supabase db reset` |
| Types out of sync | Regenerate: `supabase gen types typescript --local` |
| Can't connect to local | Run `supabase start` first |
| Permission denied | Check RLS policies are correctly set |

## Environment Variables

Ensure these are set in `.env.local`:

```bash
EXPO_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# For local development
# EXPO_PUBLIC_SUPABASE_URL=http://localhost:54321
# EXPO_PUBLIC_SUPABASE_ANON_KEY=<local-anon-key-from-supabase-start>
```

## Project Structure

```
supabase/
├── config.toml          # Supabase configuration
├── migrations/          # SQL migration files
│   ├── 20240101000000_initial.sql
│   └── 20240102000000_add_captures.sql
└── seed.sql             # Optional seed data
```

## Quick Reference

| Command | Description |
|---------|-------------|
| `supabase start` | Start local Supabase |
| `supabase stop` | Stop local Supabase |
| `supabase migration new <name>` | Create migration |
| `supabase db push` | Apply migrations |
| `supabase db reset` | Reset and replay all migrations |
| `supabase gen types typescript` | Generate TS types |
| `supabase link --project-ref <id>` | Link to remote project |
