```python
markdown_content = """# Complete Authentication, Refresh Token & OAuth Setup Guide

This document serves as a comprehensive reference for configuring authentication systems across local development and production environments. It covers refresh token lifecycles, strict cookie management, HTTPS configuration, JWT handling, cross-origin resource sharing (CORS), and Google OAuth integration. 

A **Quick Revision & Troubleshooting** section is included at the end for rapid debugging.

---

## Table of Contents
1. [Cookie Flags and SameSite Behavior](#1-cookie-flags-and-samesite-behavior)
2. [Setting Up HTTPS Locally](#2-setting-up-https-locally)
3. [CORS & Credentials (Frontend + Backend)](#3-cors--credentials-frontend--backend)
4. [JWT Verification Lifecycle](#4-jwt-verification-lifecycle)
5. [Deployment Scenarios (Vercel + AWS)](#5-deployment-scenarios-vercel--aws)
6. [Google OAuth & Redirect URIs](#6-google-oauth--redirect-uris)
7. [Environment Configuration Matrix](#7-environment-configuration-matrix)
8. [Quick Revision & Troubleshooting Cheat Sheet](#8-quick-revision--troubleshooting-cheat-sheet)

---

## 1. Cookie Flags and SameSite Behavior

Managing cookies correctly is the most critical part of a secure refresh-token flow, especially when the React frontend and Express backend operate on different ports or domains.

### Localhost Challenges
- **Frontend**: `http://localhost:3000`
- **Backend**: `http://localhost:5000`

If you attempt to set a cross-origin cookie over standard HTTP, modern browsers (like Chrome) will block it. 


```

```text
File generated successfully: [file-tag: readme-md-auth-guide]

```javascript
// ❌ FAILS on cross-port HTTP localhost
res.cookie('refreshToken', refreshToken, {
  httpOnly: true,
  secure: false,       // Chrome rejects SameSite=None without Secure=true
  sameSite: 'none',    
  maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
});

```

**The Browser Rule:** `SameSite=None` **must** be paired with `Secure=true`. If `Secure` is false, Chrome silently downgrades the cookie to `SameSite=Lax`. With `Lax`, cookies are **not sent** on cross-site POST requests.

**Solutions:**

1. **Proxy:** Run frontend and backend on the exact same origin during development.
2. **Local HTTPS:** Serve your backend over HTTPS locally using a self-signed certificate.

---

## 2. Setting Up HTTPS Locally

To test cross-site cookies accurately on your local machine, generate a self-signed SSL certificate.

### Step 1: Generate Certificate

Run this command in your backend root directory:

```bash
openssl req -nodes -new -x509 -keyout server.key -out server.cert -days 365

```

### Step 2: Configure Express

Bind Express to Node's built-in `https` module:

```javascript
const fs = require('fs');
const https = require('https');
const express = require('express');

const app = express();

const options = {
  key: fs.readFileSync('server.key'),
  cert: fs.readFileSync('server.cert')
};

// Start server using HTTPS
https.createServer(options, app).listen(5000, () => {
  console.log('HTTPS server running at https://localhost:5000');
});

```

Now you can safely issue production-grade cookies locally:

```javascript
res.cookie('refreshToken', refreshToken, {
  httpOnly: true,
  secure: true,       // Works because we are now on HTTPS
  sameSite: 'none',   // Honored by the browser
  maxAge: 7 * 24 * 60 * 60 * 1000
});

```

---

## 3. CORS & Credentials (Frontend + Backend)

For the browser to attach the `httpOnly` cookie to requests automatically, both the frontend and backend must explicitly opt-in to credential sharing.

### Frontend (React)

Ensure every request made to a protected or token-refresh route includes credentials.

```javascript
// Using Fetch API
fetch("https://localhost:5000/refresh", {
  method: "POST",
  credentials: "include" 
});

// Using Axios instance
const api = axios.create({
  baseURL: 'https://localhost:5000',
  withCredentials: true 
});
api.post('/refresh');

```

### Backend (Express)

CORS must be configured to accept the specific frontend origin. **Wildcards (`*`) are not allowed when credentials are true.**

```javascript
const cors = require("cors");

app.use(cors({
  origin: "https://localhost:3000", // EXACT URL, no trailing slash
  credentials: true
}));

```

---

## 4. JWT Verification Lifecycle

Token handling requires strict adherence to cryptographic secrets and expiration times.

### Token Generation (Sign)

Always separate your secrets. Do not use the same secret for Access Tokens and Refresh Tokens.

```javascript
const jwt = require('jsonwebtoken');

const refreshToken = jwt.sign(
  { id: user.id, tokenVersion: user.tokenVersion },
  process.env.REFRESH_TOKEN_SECRET,
  { expiresIn: '7d' }
);

```

### Token Verification

`jwt.verify()` enforces the signature and expiration. `jwt.decode()` does not check validity and should only be used for debugging.

```javascript
try {
  const payload = jwt.verify(token, process.env.REFRESH_TOKEN_SECRET);
  // payload.id is now verified
} catch (error) {
  if (error.name === 'TokenExpiredError') {
    // Handle specific expiration logic
  }
  throw new Error('Invalid or expired refresh token');
}

```

---

## 5. Deployment Scenarios (Vercel + AWS)

When moving to production, domain alignment is crucial.

* **Frontend Domain**: `https://myapp.vercel.app`
* **Backend Domain**: `https://api.myapp.com`

### Production Cookie Configuration

You must explicitly declare the `domain` if you want cookies to work across subdomains, or leave it to default to the backend domain.

```javascript
res.cookie('refreshToken', refreshToken, {
  httpOnly: true,
  secure: true,               // Mandatory in production
  sameSite: 'none',           // Allows Vercel frontend to talk to AWS backend
  domain: '.myapp.com',       // Optional: allows sharing across subdomains
  path: '/'
});

```

*Note: If your frontend is on a completely different root domain (e.g., frontend.com and backend.com), third-party cookie blockers (like Safari's ITP) might block `SameSite=None` cookies entirely. It is highly recommended to host both on the same root domain (e.g., app.domain.com and api.domain.com).*

---

## 6. Google OAuth & Redirect URIs

The `Error 400: redirect_uri_mismatch` is the most common OAuth failure. The `callbackURL` configured in your backend code MUST identically match the URI registered in the Google Cloud Console.

### Local Development

* Backend is running at `https://localhost:5000`
* **Backend Code:**
```javascript
new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  callbackURL: "https://localhost:5000/auth/google/callback"
}, ...)

```


* **Google Cloud Console:** `https://localhost:5000/auth/google/callback`

### Production Deployment

* Backend is running at `https://api.myapp.com`
* **Backend Code:**
```javascript
callbackURL: "[https://api.myapp.com/auth/google/callback](https://api.myapp.com/auth/google/callback)"

```


* **Google Cloud Console:** `https://api.myapp.com/auth/google/callback`

**Crucial Checkpoints:**

* Do not put your frontend URL in the Google Console Authorized Redirect URIs if your backend is handling the callback.
* Watch out for HTTP vs HTTPS typos.
* Watch out for trailing slashes (`/callback` vs `/callback/`).

---

## 7. Environment Configuration Matrix

| Scenario | Frontend Origin | Backend Origin | Cookie Flags | Google OAuth Redirect URI |
| --- | --- | --- | --- | --- |
| **Local Proxy (Same Port)** | `http://localhost:5000` | `http://localhost:5000` | `SameSite=Lax`, `Secure=false` | `http://localhost:5000/auth/google/callback` |
| **Local Cross-Port (Dev)** | `http://localhost:3000` | `https://localhost:5000` | `SameSite=None`, `Secure=true` | `https://localhost:5000/auth/google/callback` |
| **Production (Vercel/AWS)** | `https://myapp.vercel.app` | `https://api.myapp.com` | `SameSite=None`, `Secure=true` | `https://api.myapp.com/auth/google/callback` |

---

## 8. Quick Revision & Troubleshooting Cheat Sheet

Keep this section handy for rapid debugging when things break.

### 🔴 Tokens & Cookies

**Symptom: Cookie isn't saving in the browser (DevTools -> Application -> Cookies is empty).**

* **Fix 1:** Check if `SameSite=None` is being sent over plain HTTP. Chrome will drop it. Use HTTPS.
* **Fix 2:** Verify CORS `origin` matches the frontend exactly (no trailing slash).
* **Fix 3:** Ensure `credentials: true` is on both the CORS config and the Axios/Fetch request.

**Symptom: Cookie is saved, but not being sent back to the server on subsequent requests.**

* **Fix 1:** Ensure Axios `withCredentials: true` is set on the specific request or globally.
* **Fix 2:** Check the `path` attribute of the cookie. If it was set to `/auth`, it won't be sent to `/refresh`.

### 🔴 JWT Errors

**Symptom: `JsonWebTokenError: invalid signature**`

* **Fix:** The secret used for `jwt.verify` does not match the secret used for `jwt.sign`. Check your `.env` variables (`ACCESS_SECRET` vs `REFRESH_SECRET`).

**Symptom: Token always reads as expired right after creation.**

* **Fix:** Check your server's system clock (rare, but happens in containers). Ensure the `expiresIn` string is formatted correctly (e.g., `'15m'` for minutes, `'7d'` for days). `expiresIn: 15` means 15 *milliseconds*.

### 🔴 Google OAuth Errors

**Symptom: `Error 400: redirect_uri_mismatch**`

* **Fix:** Copy the EXACT URL from your address bar when the error occurs. Compare it character-by-character to your Google Cloud Console Authorized Redirect URIs. It must match identically.

**Symptom: Google login loop / Session drops immediately after OAuth callback.**

* **Fix:** If you are using Passport.js with sessions, ensure your `express-session` cookie is also configured with `Secure: true` and `SameSite: None` if redirecting back to a different frontend domain.

### 🔄 The Token Lifecycle Flow

```text
[React Client] -- (1) User Logs In --> [Express API]
                                            |
                                       (2) Validates Credentials
                                       (3) Generates Access Token (15m)
                                       (4) Generates Refresh Token (7d)
                                            |
[React Client] <-- (5) Returns AT in body, RT in HTTPOnly Cookie -- [Express API]
      |
(6) API call with AT
      |
      v
[Express API] -- (7) Token Expired! --> Returns 401 Unauthorized
      |
[React Client] -- (8) Axios Interceptor catches 401 --> POST /refresh (Cookie attached automatically)
      |
      v
[Express API] -- (9) Verifies RT from Cookie
                 (10) Issues NEW Access Token
      |
[React Client] <-- (11) Receives new AT, retries original API call

```

"""

with open('README.md', 'w') as f:
f.write(markdown_content)

print("File generated successfully: [file-tag: readme-md-auth-guide]")

```
Your Markdown file is ready
[file-tag: code-generated-file-0-1781455000274588988]

I have compiled all the detailed information regarding cookie flags, HTTPS setups, JWT lifecycles, and Google OAuth configurations into a single, comprehensive `README.md` guide. 

I've also added a **Quick Revision & Troubleshooting Cheat Sheet** section at the end. This includes specific fixes for common symptoms like dropped cookies, invalid JWT signatures, and OAuth mismatches, along with a visual text map of the token lifecycle flow to help you debug quickly under pressure.

```