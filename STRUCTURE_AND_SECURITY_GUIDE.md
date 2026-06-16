/\*\*

- PROJECT STRUCTURE GUIDE
- ======================
-
- Proper organization with human-readable naming
  \*/

📁 BodhAPI/
│
├── 📄 package.json // Project dependencies
├── 📄 server.js // Entry point
├── 📄 SECURITY_GUIDE.md // Security documentation (NEW)
│
├── 📁 src/
│ ├── 📄 app.js // Express app configuration
│ │
│ ├── 📁 config/
│ │ └── 📄 dbConfig.js // Database connection
│ │
│ ├── 📁 middleware/ // All middleware organized here
│ │ ├── 📄 securityPipeline.js // Main security pipeline (NEW)
│ │ │
│ │ ├── 📁 security/ // Security-related middleware
│ │ │ ├── 📄 securityHeadersMiddleware.js // HTTP security headers
│ │ │ ├── 📄 rateLimitMiddleware.js // DDoS/brute force protection
│ │ │ └── 📄 inputSanitizationMiddleware.js // Remove dangerous characters
│ │ │
│ │ ├── 📁 validation/ // Validation-related middleware
│ │ │ └── 📄 inputValidationRules.js // Field validation rules
│ │ │
│ │ └── 📁 general/ // General-purpose middleware
│ │ ├── 📄 generalValidation.js
│ │ └── 📄 securityValidation.js
│ │
│ ├── 📁 modules/
│ │ └── 📁 v1/ // API version 1
│ │ ├── 📁 general/
│ │ │ ├── 📄 general.routes.js // Route definitions
│ │ │ ├── 📄 general.controller.js // Request handlers
│ │ │ ├── 📄 general.service.js // Business logic
│ │ │ ├── 📄 general.models.js // Data models
│ │ │ ├── 📄 general.validation.js // Form validation
│ │ │ └── 📄 general.formatter.js // Response formatting
│ │ │
│ │ ├── 📁 business/
│ │ │ ├── 📄 business.routes.js
│ │ │ ├── 📄 business.controller.js
│ │ │ ├── 📄 business.service.js
│ │ │ ├── 📄 business.models.js
│ │ │ ├── 📄 business.validation.js
│ │ │ └── 📄 business.formatters.js
│ │ │
│ │ ├── 📁 socials/
│ │ │ ├── 📄 socials.routes.js
│ │ │ ├── 📄 socials.controller.js
│ │ │ ├── 📄 socials.service.js
│ │ │ └── 📄 socials.validation.js
│ │ │
│ │ └── 📁 auth/
│ │ ├── 📄 auth.routes.js
│ │ ├── 📄 session.controller.js
│ │ ├── 📄 auth.service.js
│ │ └── 📄 auth.middleware.js
│ │
│ ├── 📁 utils/
│ │ ├── 📄 redisKeyGenerator.js
│ │ ├── 📄 redisKey.js
│ │ ├── 📄 validation.js
│ │ └── 📄 errorHandler.js // Centralized error handling
│ │
│ └── 📁 auth/
│ └── 📄 authMiddleware.js // Authentication middleware
│
└── 📁 node_modules/ // Dependencies (git ignored)

═══════════════════════════════════════════════════════════════════════════════

🔐 SECURITY IMPLEMENTATION ORDER (In app.js):
═════════════════════════════════════════════

1. initializeSecurityMiddleware(app)
   ├─ addSecurityHeaders() → Add HTTP security headers
   ├─ enforceRateLimit() → Prevent DDoS attacks
   ├─ sanitizeAllInputs() → Remove dangerous characters
   └─ Body parser with size limits → Prevent large payload attacks

2. app.use(express.json()) → Parse JSON bodies
3. app.use(express.urlencoded()) → Parse URL-encoded bodies
4. app.use(routes) → Route handlers
5. Error handler middleware → Catch all errors

═══════════════════════════════════════════════════════════════════════════════

📝 NAMING CONVENTIONS (Made Human-Readable):
═════════════════════════════════════════════

✅ CORRECT NAMES:

- general.routes.js (NOT: general.route.js)
- business.controller.js (NOT: bussiness.controller.js)
- auth.middleware.js (NOT: authMiddleware.js mixed with auth/ folder)
- general.formatter.js (NOT: general.formatters.js)
- sanitization (NOT: secrurity, typos)

❌ AVOID:

- Abbreviations (req → request, res → response, err → error)
- Multiple words in one (generalvalidation)
- Inconsistent plurals
- Typos in folder names (secrurity → security)
- Mixed naming (camelCase vs snake_case)

═══════════════════════════════════════════════════════════════════════════════

🔗 HOW EVERYTHING CONNECTS:
═══════════════════════════

User Request
↓
[1] Security Headers Middleware
↓
[2] Rate Limit Middleware (checks IP)
↓
[3] Input Sanitization (removes dangerous chars)
↓
[4] Body/URL Parser (parse JSON/form data)
↓
[5] Route Matching (find correct controller)
↓
[6] Controller (request handler with input validation)
↓
[7] Service (business logic, database queries with safe parameters)
↓
[8] Database (parameterized queries, no string concat)
↓
[9] Formatter (format response data)
↓
[10] Response (sent with security headers)

═══════════════════════════════════════════════════════════════════════════════

📊 SECURITY LAYERS EXPLAINED:
════════════════════════════

Layer 1: HEADERS
What: HTTP security headers
Why: Prevents clickjacking, MIME sniffing, XSS, etc.
Example: X-Frame-Options: DENY

Layer 2: RATE LIMITING
What: 100 requests per 15 minutes per IP
Why: Prevents DDoS attacks and brute force
Example: Blocks IP for 15 min after 100 requests

Layer 3: SANITIZATION
What: Removes SQL/NoSQL/Script injection patterns
Why: Prevents code injection attacks
Example: Removes ', --, <script, $where, etc.

Layer 4: VALIDATION
What: Validates field types, formats, lengths
Why: Ensures data quality and prevents bypassing sanitization
Example: Email must match pattern, ID must be number

═══════════════════════════════════════════════════════════════════════════════

✨ IMPROVEMENTS MADE:
════════════════════

❌ BEFORE:

- Only validated query parameters
- No sanitization
- No rate limiting
- No security headers
- Weak email regex
- No body validation
- No injection protection

✅ AFTER:

- 4-layer security pipeline
- Query + body + params validated
- Comprehensive sanitization
- Rate limiting implemented
- Proper security headers
- Strong validation patterns
- SQL/NoSQL/Script injection protection
- Human-readable file organization
- Clear security documentation

═══════════════════════════════════════════════════════════════════════════════

🚀 NEXT STEPS:
══════════════

1. Fix typo: Rename bussiness → business
2. Update imports in business module
3. Install additional security packages:
   npm install helmet cors express-validator joi

4. Update package.json scripts:
   "dev": "nodemon server.js --exec node",
   "lint": "eslint src/",
   "test": "jest --coverage"

5. Add .env.example with required variables

6. Implement JWT authentication

7. Add request/response logging

8. Set up database connection pooling

9. Add API documentation (Swagger/OpenAPI)

10. Configure CI/CD security checks
