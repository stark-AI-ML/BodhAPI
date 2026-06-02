/\*\*

- Security Best Practices Guide
- =============================
-
- This document outlines all security measures implemented in the API
- and provides guidance for maintaining security standards.
  \*/

## 1. Middleware Security Pipeline

Your API now implements a 4-layer security pipeline (in order):

### Layer 1: Security Headers

- X-Frame-Options: Prevents clickjacking
- X-Content-Type-Options: Prevents MIME sniffing
- Content-Security-Policy: Restricts resource loading
- Strict-Transport-Security: Enforces HTTPS
- Cache-Control: Prevents caching sensitive data

### Layer 2: Rate Limiting

- 100 requests per 15 minutes per IP
- Prevents DDoS and brute force attacks
- Automatically cleans up old entries

### Layer 3: Input Sanitization

- Removes SQL injection patterns (', --, ;, /_, _/, xp*, sp*)
- Removes script injection patterns (<script, javascript:, onerror=, onload=)
- Removes NoSQL injection patterns ($where, $regex, ../)
- Limits string length to 5000 characters
- Limits array length to 100 items
- Detects and prevents deeply nested objects (max 10 levels)

### Layer 4: Input Validation

- Field-level validation with configurable rules
- Type checking (integer, string, etc.)
- Min/max bounds validation
- Pattern/regex validation for format
- Required field checking
- Default value handling

---

## 2. Using Validation in Controllers

Example controller using proper validation:

```javascript
import {
  validateQueryParameters,
  FIELD_VALIDATION_RULES,
} from "../middleware/validation/inputValidationRules.js";

export const getNewsWithPagination = async (request, response) => {
  try {
    // Define what fields you expect and how to validate them
    const validationRules = {
      pageNumber: FIELD_VALIDATION_RULES.pageNumber,
      itemsPerPage: FIELD_VALIDATION_RULES.itemsPerPage,
      searchQuery: FIELD_VALIDATION_RULES.searchQuery, // optional
    };

    // Validate incoming query parameters
    const validationResult = validateQueryParameters(
      request.query,
      validationRules,
    );

    // Check for validation errors
    if (validationResult.hasErrors) {
      return response.status(400).json({
        success: false,
        errors: validationResult.errors,
      });
    }

    // Use validated data safely
    const {
      pageNumber = 1,
      itemsPerPage = 10,
      searchQuery,
    } = validationResult.validatedData;

    // Query database with safe, validated data
    const newsArticles = await getNewsFromDatabase({
      page: pageNumber,
      limit: itemsPerPage,
      search: searchQuery,
    });

    response.status(200).json({
      success: true,
      data: newsArticles,
      pagination: {
        currentPage: pageNumber,
        itemsPerPage: itemsPerPage,
      },
    });
  } catch (error) {
    console.error("[ERROR]", error);
    response.status(500).json({
      success: false,
      error: "Failed to retrieve news",
    });
  }
};
```

---

## 3. Available Validation Rules

Pre-configured validation rules in FIELD_VALIDATION_RULES:

- **pageNumber**: Integer 1-10000
- **itemsPerPage**: Integer 1-500
- **emailAddress**: Valid email format (RFC 5322)
- **searchQuery**: Alphanumeric + spaces + special chars (., \_, -, &, ')
- **numericId**: Integer 1-9999999
- **userName**: Alphanumeric + underscore/dash (3-30 chars)
- **textContent**: Any text up to 5000 chars

---

## 4. Creating Custom Validation Rules

Add new rules to FIELD_VALIDATION_RULES:

```javascript
const customRules = {
  phoneNumber: {
    type: "string",
    pattern: /^\+?1?\d{9,15}$/,
    fieldName: "Phone number",
  },
  zipCode: {
    type: "string",
    pattern: /^\d{5}(-\d{4})?$/,
    fieldName: "ZIP code",
  },
  dateString: {
    type: "string",
    pattern: /^\d{4}-\d{2}-\d{2}$/,
    fieldName: "Date (YYYY-MM-DD)",
  },
};
```

---

## 5. Required Security Checklist

- [x] Security headers configured
- [x] Rate limiting enabled
- [x] Input sanitization active
- [x] Input validation implemented
- [ ] Environment variables secured (no secrets in code)
- [ ] Database connection uses parameterized queries
- [ ] Authentication middleware implemented
- [ ] Authorization checks added to sensitive routes
- [ ] HTTPS enabled in production
- [ ] Regular security audits scheduled
- [ ] Dependency vulnerabilities monitored (npm audit)

---

## 6. Common Security Mistakes to Avoid

### ❌ DON'T:

- Store passwords as plain text
- Use string concatenation for database queries
- Log sensitive data (passwords, API keys)
- Trust client-side validation alone
- Skip input sanitization
- Allow unlimited request rates
- Store secrets in environment files committed to git
- Use eval() or new Function() with user input

### ✅ DO:

- Use parameterized queries / prepared statements
- Hash passwords with bcrypt
- Implement server-side validation
- Always sanitize and validate user input
- Implement rate limiting
- Use environment variables for secrets
- Keep dependencies updated
- Log security events

---

## 7. Database Security

Always use parameterized queries:

```javascript
// ✅ CORRECT - Safe from SQL/NoSQL injection
const result = await database.query("SELECT * FROM users WHERE email = $1", [
  userEmail,
]);

// ❌ WRONG - Vulnerable to injection
const result = await database.query(
  `SELECT * FROM users WHERE email = '${userEmail}'`,
);
```

---

## 8. Monitoring and Response

When security is triggered:

- Rate limit exceeded (429): Automatic - returns after window expires
- Invalid input (400): Detailed error message to help fix request
- Server error (500): Generic message, detailed error logged

Check server logs for:

- Repeated failed validation attempts
- Rate limit violations from same IP
- Patterns that might indicate attacks

---

## 9. Future Enhancements

Consider adding:

1. **JWT Authentication** - Secure token-based authentication
2. **CORS Configuration** - Control cross-origin requests
3. **API Key Management** - Restrict API access
4. **Request Logging** - Track all requests
5. **Honeypot Fields** - Detect bots
6. **Two-Factor Authentication** - Enhanced user security
7. **Database Encryption** - Encrypt sensitive data at rest
8. **API Rate Limiting Per User** - Fine-grained control
9. **Incident Response Plan** - Handle security breaches
10. **Security Testing** - Penetration testing

---

Generated: ${new Date().toISOString()}
