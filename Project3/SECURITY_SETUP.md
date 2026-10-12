# SIBS — Security setup after fixes

## Database
- Credentials live in `src/main/java/db.properties` (add to `.gitignore` if you change the password).
- All DAOs use `DBConnection` — do not hardcode passwords in Java.

## Razorpay
Configure **one** of:
1. Environment variables: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`
2. `src/main/java/razorpay.properties` (copy from `razorpay.properties.example`)
3. `WEB-INF/web.xml` context parameters `razorpay.key.id` / `razorpay.key.secret`

Payment signature verification is always enforced (no test-key bypass).

## Admin registration
- `POST /register` requires an **existing admin** session.
- Use `admin-register.jsp` only while logged in as admin.

## Existing users with broken passwords (double-hashed)
Customers/staff registered before this fix may need a password reset in the database or a “forgot password” flow.

## Re-hash migration
Users with legacy SHA-256 passwords are upgraded to BCrypt on next successful login.
