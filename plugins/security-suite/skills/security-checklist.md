---
name: security-checklist
description: Comprehensive security checklist for web applications
effort: medium
---

# Security Checklist Skill

## Quick Security Audit

### Authentication
- [ ] Passwords hashed with bcrypt/argon2 (cost factor >= 10)
- [ ] Session tokens are cryptographically random
- [ ] JWT tokens have short expiry (15min access, 7d refresh)
- [ ] Rate limiting on login endpoints
- [ ] Account lockout after failed attempts

### Authorization
- [ ] Every API endpoint checks permissions
- [ ] No IDOR (Insecure Direct Object References)
- [ ] Role-based access control implemented
- [ ] Sensitive operations require re-authentication

### Input Validation
- [ ] All user input validated server-side
- [ ] File uploads restricted by type and size
- [ ] SQL queries use parameterized statements
- [ ] HTML output encoded to prevent XSS

### Data Protection
- [ ] Sensitive data encrypted at rest
- [ ] HTTPS enforced everywhere
- [ ] Secure cookies (HttpOnly, Secure, SameSite)
- [ ] No sensitive data in URLs or logs

### Headers & CORS
- [ ] Content-Security-Policy header set
- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options: DENY (or SAMEORIGIN)
- [ ] Strict-Transport-Security enabled
- [ ] CORS properly restricted

## Code Patterns

### SQL Injection Prevention
```javascript
// VULNERABLE
db.query(`SELECT * FROM users WHERE id = ${userId}`);

// SECURE
db.query('SELECT * FROM users WHERE id = $1', [userId]);
```

### XSS Prevention
```javascript
// VULNERABLE
element.innerHTML = userInput;

// SECURE
element.textContent = userInput;

// SECURE (with sanitization)
element.innerHTML = DOMPurify.sanitize(userInput);
```

### CSRF Protection
```javascript
// Generate token
const csrfToken = crypto.randomBytes(32).toString('hex');
session.csrfToken = csrfToken;

// Validate on POST
if (req.body.csrf !== session.csrfToken) {
  throw new ForbiddenError('Invalid CSRF token');
}
```

### Secrets Management
```javascript
// NEVER in code
const API_KEY = 'sk-abc123...';

// Environment variables
const API_KEY = process.env.API_KEY;

// Secrets manager (production)
const secret = await secretsManager.getSecret('api-key');
```

## Security Headers Example

```javascript
// Express middleware
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('Content-Security-Policy', "default-src 'self'");
  next();
});
```

## Dependency Security

```bash
# Check for vulnerabilities
npm audit

# Auto-fix what's possible
npm audit fix

# Check outdated packages
npm outdated

# Update dependencies
npm update
```

## Logging Security Events

```javascript
// Events to log
logger.security({
  event: 'login_failed',
  ip: req.ip,
  email: req.body.email,
  reason: 'invalid_password',
  timestamp: new Date().toISOString()
});

// Never log
// - Passwords
// - Full credit card numbers
// - Session tokens
// - Personal data (in production)
```

## Pre-Deployment Checklist

1. [ ] Run `npm audit` - no critical vulnerabilities
2. [ ] All secrets in environment variables
3. [ ] Debug mode disabled
4. [ ] Error messages don't expose internals
5. [ ] HTTPS only (HTTP redirects to HTTPS)
6. [ ] Database credentials rotated
7. [ ] Logging configured (no sensitive data)
8. [ ] Backup strategy tested
