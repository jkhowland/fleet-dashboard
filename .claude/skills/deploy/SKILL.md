---
name: deploy
description: Deploy the app to staging or production. Use when asked to 'deploy', 'deploy to staging', or 'release'.
---

# Deploy Skill

Deploy the app to staging or production environments.

## How to Use

The user will ask to deploy, or you should invoke this skill when code is ready to go to staging/production. You should:

1. Verify prerequisites (clean git state, tests pass)
2. Run typecheck
3. Build the app
4. Deploy to the target environment
5. Verify deployment
6. Report results

## When to Use This Skill

Use this skill when:
- User asks to "deploy" or "deploy to staging"
- User wants to "push changes to staging"
- After completing a feature that's ready for deployment

**Do NOT use this skill when:**
- User is still implementing changes
- There are uncommitted changes
- Tests are failing

## Prerequisites

Before running this skill, verify:

```bash
# Check for uncommitted changes
git status --porcelain

if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Uncommitted changes detected"
    echo "Please commit all changes before deploying"
    exit 1
fi

# Run typecheck
npm run typecheck

# Verify tests pass
npm test
```

## Deploy Process

### Phase 1: Verify Environment

```bash
# Ensure we're on the correct branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# For staging deploys, should be on staging or a feature branch
# For production deploys, should be on main
```

### Phase 2: Run Pre-Deploy Checks

```bash
# Run typecheck
npm run typecheck

if [ $? -ne 0 ]; then
  echo "Error: TypeScript type errors detected"
  exit 1
fi

# Run tests
npm test

if [ $? -ne 0 ]; then
  echo "Error: Tests failing"
  exit 1
fi
```

### Phase 3: Build the App

```bash
# For Expo/React Native
npx expo export --platform ios
npx expo export --platform android

# Or for web
npm run build
```

### Phase 4: Deploy

The deployment method depends on your setup:

**For Expo (EAS Build):**
```bash
# Deploy to staging
eas build --profile staging --platform all

# Deploy to production
eas build --profile production --platform all
```

**For Vercel/Railway/etc:**
```bash
# Push to trigger deployment
git push origin staging

# Or use CLI
vercel --prod
```

### Phase 5: Verify Deployment

```bash
# Check deployment status
# This depends on your deployment platform

# For Expo
eas build:list --limit 1

# For web apps, check health endpoint
curl -s https://your-staging-url.com/api/health
```

### Phase 6: Report Results

```
Deploy Summary
==============

Environment: staging
Branch: feature-branch
Commit: abc1234

Pre-deploy checks:
- Typecheck: Passed
- Tests: Passed
- Build: Succeeded

Deployment Status: Success

Next Steps:
1. Verify on staging
2. Test key functionality
3. When ready: promote to production
```

## Error Handling

### Uncommitted Changes

```bash
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Uncommitted changes"
    echo "Please commit or stash changes before deploying"
    exit 1
fi
```

### Build Fails

```bash
if ! npm run build; then
    echo "Error: Build failed"
    echo "Please fix build errors before deploying"
    exit 1
fi
```

### Tests Failing

```bash
if ! npm test; then
    echo "Error: Tests failing"
    echo "Please fix failing tests before deploying"
    exit 1
fi
```

## Best Practices

### DO

1. **Always verify tests pass locally first**
2. **Run typecheck before deploying**
3. **Verify on staging before production**
4. **Keep track of what's being deployed**

### DON'T

1. **Don't deploy with uncommitted changes**
2. **Don't skip tests**
3. **Don't deploy directly to production without staging verification**

## Example Invocations

### Basic Deploy

```
User: "Deploy to staging"
-> Verify prerequisites, build, deploy, verify
```

### Deploy After Feature

```
User: "The feature is done, deploy it"
-> Verify commits, run checks, deploy
```

## Success Criteria

A successful deploy should result in:
- All pre-deploy checks pass (typecheck, tests)
- Build succeeds
- Deployment completes without errors
- Verification confirms app is running
- User has deployment status and next steps
