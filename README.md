# SIBS

A Java web application (Servlets + JSP) for online ordering and delivery management. It supports four roles: **customers**, **admin**, **staff** and **delivery partners**, with online payments through Razorpay, cash on delivery (COD) tracking and a customer wallet.

## Features

**Customer**
- Register, log in (OTP verification), manage profile and saved addresses
- Browse and search products, wishlist, cart, "Buy now" and selected-item checkout
- Pay online with Razorpay or cash on delivery; payment history and invoices
- Track orders, cancel orders, request returns, raise support complaints
- Rate delivery riders and review products
- Wallet recharge and withdrawal, coupons, notifications

**Admin**
- Manage products, users, staff and delivery partners
- Orders, returns, delivery approvals and delivery slots
- COD ledger and remittance settlement
- Staff attendance and leave
- Live delivery map, broadcast notifications, app settings, sales reports

**Staff**
- Orders and cancelled orders, coupons, reviews and support tickets
- Attendance, leave, withdrawals and notifications

**Delivery partner**
- Registration with document upload, online/offline and shift toggle
- Delivery slot booking and history, order pickup and delivery confirmation (OTP)
- Cash ledger, earnings, wallet and ratings

## Tech Stack

| Area | Technology |
|------|------------|
| Language | Java 21 |
| Web | Jakarta Servlet 6 / JSP, JSTL 3 |
| Server | Apache Tomcat 10.1 |
| Database | MySQL (database name `sibs`) with HikariCP connection pooling |
| Security | BCrypt password hashing (jBCrypt) |
| Payments | Razorpay |
| Email | Jakarta Mail (SMTP) |
| IDE | Eclipse (Dynamic Web Project) |

## Project Structure

```
Project3/
└── src/main/
    ├── java/
    │   ├── com/sibs/servlet/    # Request handlers
    │   ├── com/sibs/dao/        # Database access (DAO pattern)
    │   ├── com/sibs/model/      # Data models
    │   ├── com/sibs/service/    # Payment service
    │   ├── com/sibs/util/       # DB connection, email, Razorpay config, password utils
    │   ├── db.properties                  # (not committed) database credentials
    │   └── razorpay.properties.example    # template for Razorpay keys
    └── webapp/                  # JSP pages, images, WEB-INF
```

## Getting Started

### Prerequisites

- JDK 21
- Eclipse IDE for Enterprise Java and Web Developers
- Apache Tomcat 10.1
- MySQL 8 or later
- A Razorpay account (test-mode keys are fine)
- A Gmail account with an app password (for sending OTP and notification emails)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/upendra888/SIBS.git
   ```
2. **Import into Eclipse:** File → Import → Existing Projects into Workspace, then select the `Project3` folder. Set the server runtime to Tomcat 10.1.
3. **Create the database:** create a MySQL database named `sibs` and its tables. _(Add your schema file to the repo, for example `database/schema.sql`, and link it here.)_
4. **Create `src/main/java/db.properties`:**
   ```properties
   db.url=jdbc:mysql://localhost:3306/sibs?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true&useUnicode=true&characterEncoding=UTF-8
   db.username=YOUR_DB_USER
   db.password=YOUR_DB_PASSWORD
   ```
5. **Configure Razorpay.** Use one of:
   - Environment variables `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET`
   - Copy `razorpay.properties.example` to `razorpay.properties` and fill in your keys
6. **Configure email** with environment variables:
   ```
   SIBS_MAIL_FROM=you@gmail.com
   SIBS_MAIL_PASSWORD=your_gmail_app_password
   ```
7. **Run:** add the project to Tomcat (Servers view → Add and Remove), start the server and open `http://localhost:8080/Project3/`.

## Security

- `db.properties` and `razorpay.properties` are in `.gitignore` and must never be committed.
- Passwords are hashed with BCrypt; legacy SHA-256 hashes are upgraded on next login.
- Admin registration requires an existing admin session.
- Razorpay payment signatures are always verified.
- Keep all credentials in environment variables or ignored files, never in Java source.

See [`SECURITY_SETUP.md`](Project3/SECURITY_SETUP.md) for details.

## Author

[upendra888](https://github.com/upendra888)
