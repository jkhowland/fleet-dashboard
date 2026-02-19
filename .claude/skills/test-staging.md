---
name: test-staging
description: Run health checks and tests against the staging environment to verify deployment. Use when asked to 'test staging', 'verify staging', or 'check staging deployment'.
---

# Test Staging Skill

Verify the staging deployment is healthy by running health checks and tests against the staging environment.

## How to Use

This skill runs automated verification against the staging environment:

1. Health check - verifies the app is running
2. Smoke tests - verifies basic functionality works

## When to Use This Skill

Use this skill when:
- After merging a PR to the `staging` branch
- Before promoting staging to main
- When asked to "test staging" or "verify staging"
- To check if staging is ready for production

**Do NOT use this skill when:**
- Testing local development
- Running full test suite (use `test-all` skill)

## Test Process

### Phase 1: Health Check

First, verify the deployment is healthy.

```bash
# Check health endpoint (adjust URL for your setup)
STAGING_URL="https://your-staging-url.com"
HEALTH_RESPONSE=$(curl -s "${STAGING_URL}/api/health" || echo '{"status":"error"}')

STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.status // "unknown"')

if [ "$STATUS" = "healthy" ] || [ "$STATUS" = "ok" ]; then
  echo "Health check passed"
else
  echo "Health check failed"
  echo "$HEALTH_RESPONSE"
  exit 1
fi
```

### Phase 2: Smoke Tests

Run basic tests against staging:

```bash
# Run smoke tests against staging
STAGING_URL=https://your-staging-url.com npm run test:smoke

# Parse results
if [ $? -eq 0 ]; then
  TEST_STATUS="PASSED"
else
  TEST_STATUS="FAILED"
fi
```

### Phase 3: Report Results

**Success Report**:
```
Staging Verification Passed

Health Check:
  App: Running
  Database: Connected (if applicable)

Smoke Tests:
  X/X tests passed

Staging is ready for promotion to main.
```

**Failure Report**:
```
Staging Verification Failed

Health Check:
  App: Not responding

Error: [error details]

Please investigate before promoting to main.
```

## Quick Health Check Only

For a quick check without running full tests:

```bash
curl -s https://your-staging-url.com/api/health | jq '.'
```

## Troubleshooting

### Health Check Fails

**App not responding**:
- Check deployment logs
- Verify deployment completed
- Check for runtime errors

**Database error**:
- Check database connection
- Verify environment variables

### Smoke Tests Fail

**Pages don't load**:
- Check build errors in deployment
- Verify deployment completed successfully

**Timeouts**:
- Cold start can be slow
- Retry after a minute
- Check deployment logs

## Integration with Workflow

This skill is typically used in the staging-first workflow:

```
1. PR merged to staging
2. Deployment completes
3. Run test-staging skill <- YOU ARE HERE
4. If passed, promote to main
5. Deploy to production
```

## Example Invocations

**Full verification**:
```
User: "Test staging"
-> Run health check, run smoke tests, report results
```

**Quick check**:
```
User: "Is staging healthy?"
-> Run health check only, report status
```

**Before promotion**:
```
User: "Can we promote staging to main?"
-> Run full verification, recommend yes/no
```

## Success Criteria

A successful staging verification should show:
- Health endpoint returns healthy status
- All smoke tests pass
- No 5xx errors from any endpoint

Only recommend promotion to main if all criteria are met.
