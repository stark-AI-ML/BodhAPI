/\*\*

- ⚡ QUICK REFERENCE: Security Implementation Checklist
- ===================================================
  \*/

## 📋 For Every New Endpoint:

- [ ] **Define Validation Rules**

  ```javascript
  const validationRules = {
    fieldName: FIELD_VALIDATION_RULES.ruleType,
    // OR create custom rule
    customField: { type: "string", pattern: /regex/, required: true },
  };
  ```

- [ ] **Validate Input**

  ```javascript
  const result = validateQueryParameters(request.query, validationRules);
  if (result.hasErrors) return response.status(400).json({...});
  ```

- [ ] **Use Validated Data**

  ```javascript
  const { fieldName } = result.validatedData;
  // fieldName is now safe to use
  ```

- [ ] **Use Parameterized Queries**

  ```javascript
  // ✅ CORRECT
  database.query("SELECT * FROM users WHERE id = $1", [userId]);

  // ❌ WRONG
  database.query(`SELECT * FROM users WHERE id = ${userId}`);
  ```

- [ ] **Handle Errors Properly**

  ```javascript
  try {
    // business logic
  } catch (error) {
    console.error("[ERROR]", error);
    return response.status(500).json({
      success: false,
      error: "User-friendly message",
    });
  }
  ```

- [ ] **Return Formatted Response**
  ```javascript
  return response.status(200).json({
    success: true,
    data: formattedData,
    timestamp: new Date().toISOString(),
  });
  ```

---

## 🔒 Security Checklist:

### Input Handling

- [ ] All inputs from request.query are validated
- [ ] All inputs from request.body are validated
- [ ] All inputs from request.params are validated
- [ ] File uploads have size limits
- [ ] File types are verified

### Database

- [ ] All database queries use parameterized values
- [ ] No string concatenation in queries
- [ ] Sensitive data is encrypted at rest
- [ ] Database credentials in environment variables

### Authentication & Authorization

- [ ] User identity is verified (JWT/Session)
- [ ] User has permission for action (authorization)
- [ ] API keys are rotated regularly
- [ ] Sensitive operations require additional verification

### Response Security

- [ ] No sensitive data in error messages
- [ ] Response headers include security headers
- [ ] Large responses are paginated
- [ ] No stack traces exposed to users

### Logging & Monitoring

- [ ] Failed validation attempts are logged
- [ ] Security events are logged
- [ ] No passwords/secrets in logs
- [ ] Logs are monitored for anomalies

---

## 📝 Available Validation Rules:

```javascript
// Pagination
pageNumber; // Integer 1-10000
itemsPerPage; // Integer 1-500 (default 10)

// Contact Info
emailAddress; // Valid email
userName; // 3-30 alphanumeric + _-
phoneNumber; // +1-15 digits (if added)

// IDs & Numbers
numericId; // Integer 1-9999999

// Text
searchQuery; // Alphanumeric + spaces/special
textContent; // Any text up to 5000 chars

// Dates (if added)
dateString; // YYYY-MM-DD format
```

---

## 🎯 Common Patterns:

### Pattern 1: Simple GET with Pagination

```javascript
export const getItems = async (req, res) => {
  const rules = {
    pageNumber: FIELD_VALIDATION_RULES.pageNumber,
    itemsPerPage: FIELD_VALIDATION_RULES.itemsPerPage,
  };

  const validation = validateQueryParameters(req.query, rules);
  if (validation.hasErrors)
    return res.status(400).json({ errors: validation.errors });

  const data = await service.getItems(validation.validatedData);
  res.json({ success: true, data });
};
```

### Pattern 2: Search with Filters

```javascript
export const searchItems = async (req, res) => {
  const rules = {
    keyword: { ...FIELD_VALIDATION_RULES.searchQuery, required: true },
    category: { type: "string", pattern: /^[a-z]+$/, required: false },
  };

  const validation = validateQueryParameters(req.query, rules);
  if (validation.hasErrors)
    return res.status(400).json({ errors: validation.errors });

  const results = await service.search(validation.validatedData);
  res.json({ success: true, data: results });
};
```

### Pattern 3: ID from URL Parameter

```javascript
export const getItemById = async (req, res) => {
  const rules = {
    id: FIELD_VALIDATION_RULES.numericId,
  };

  const validation = validateQueryParameters({ id: req.params.id }, rules);
  if (validation.hasErrors)
    return res.status(400).json({ errors: validation.errors });

  const item = await service.getById(validation.validatedData.id);
  if (!item)
    return res.status(404).json({ success: false, error: "Not found" });

  res.json({ success: true, data: item });
};
```

---

## ⚠️ Red Flags (Things to Fix):

- [ ] Query parameters used directly in database queries
- [ ] User input in error messages
- [ ] API keys or passwords in code
- [ ] No validation on user input
- [ ] Catching all errors but doing nothing
- [ ] Large responses returned without pagination
- [ ] No rate limiting on login/sensitive endpoints
- [ ] Files uploaded without verification
- [ ] Sensitive data logged to console
- [ ] CORS allowing all origins (\*:)

---

## 🚀 Performance Tips:

- Validate early (fail fast)
- Use indexes on frequently queried fields
- Cache non-sensitive data
- Implement pagination for large datasets
- Use connection pooling for databases
- Add response compression (gzip)
- Monitor query performance

---

## 📚 Resource Links:

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Node.js Security: https://nodejs.org/en/docs/guides/security/
- Express Security: https://expressjs.com/en/advanced/best-practice-security.html
- SQL Injection Prevention: https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html

---

## 🔄 Update Cycle:

- [ ] Review security monthly
- [ ] Update dependencies monthly (`npm audit`)
- [ ] Rotate API keys quarterly
- [ ] Penetration test annually
- [ ] Update this checklist as you learn

---

## 📞 Questions?

If unsure about security:

1. Check SECURITY_GUIDE.md
2. Review STRUCTURE_AND_SECURITY_GUIDE.md
3. Look at EXAMPLE_SECURE_CONTROLLER.js
4. Check OWASP documentation

When in doubt, ask before deploying.

---

Last Updated: ${new Date().toISOString()}
