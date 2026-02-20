# NSC Events — Product Design Document

**Repository:** [SeattleColleges/nsc-events-fullstack](https://github.com/SeattleColleges/nsc-events-fullstack)

---

## 1. Product Overview

### 1.1 Executive Summary

NSC Events is a full-stack web application built for **North Seattle College** to centralize the creation, discovery, and management of campus events. The platform serves three distinct user roles — administrators, event creators, and general users — and provides end-to-end workflows from event publishing through attendance tracking.

The system is built on a modern TypeScript stack with NestJS powering the backend API and Next.js 14 driving the frontend experience, backed by PostgreSQL for persistence and AWS S3 for media storage.

### 1.2 Product Goals

- **Centralized Discovery** — Give students and community members a single place to find campus events, filterable by tags, dates, and keywords.
- **Streamlined Event Management** — Provide organizers with rich event creation tools including cover photos, speaker lists, document attachments, and social media links.
- **Attendance Analytics** — Enable organizers to track registrations, mark attendance, and generate participation metrics.
- **Role-Based Access Control** — Enforce clear permission boundaries between administrators, event creators, and general users.

### 1.3 Target Users

| Role        | Who                            | What They Do                                                           |
| ----------- | ------------------------------ | ---------------------------------------------------------------------- |
| **Admin**   | Campus administrators          | Full platform access — manage users, assign roles, moderate all events |
| **Creator** | Faculty, staff, student clubs  | Create, edit, archive, and manage their own events                     |
| **User**    | Students and community members | Browse events, register, and track attendance                          |

---

## 2. Technical Architecture

### 2.1 Backend

| Component         | Technology                                   |
| ----------------- | -------------------------------------------- |
| Framework         | **NestJS 10.x** (Node.js)                    |
| Language          | TypeScript 5.6                               |
| Database          | **PostgreSQL**                               |
| ORM               | **TypeORM 0.3.25**                           |
| Authentication    | **JWT** (Passport.js) + **Google OAuth 2.0** |
| File Storage      | **AWS S3**                                   |
| Image Processing  | Sharp                                        |
| Email Service     | **SendGrid**                                 |
| API Documentation | Swagger / OpenAPI                            |
| Logging           | Winston (file rotation)                      |

### 2.2 Frontend

| Component        | Technology                     |
| ---------------- | ------------------------------ |
| Framework        | **Next.js 14** (App Router)    |
| Language         | TypeScript 5.6                 |
| UI Library       | **Material UI (MUI) v5**       |
| Styling          | **Tailwind CSS 3.4** + Emotion |
| State Management | **TanStack React Query 5**     |
| Date Handling    | date-fns + MUI Date Pickers    |

### 2.3 Infrastructure & Tooling

| Component    | Technology     |
| ------------ | -------------- |
| Monorepo     | npm workspaces |
| E2E Testing  | **Playwright** |
| Unit Testing | **Jest**       |
| CI/CD        | GitHub Actions |

---

## 3. Data Model

### 3.1 Entity Relationship Diagram

The full database schema is documented in an interactive ERD:

> **[View the NSC Events ERD on dbdiagram.io](https://dbdiagram.io/d/NSC-Events-ERD-696e9c7ad6e030a02480f84a)**

### 3.2 Core Entities

**Users** (`users`)
Stores all platform accounts. Each user has a role (`admin`, `creator`, or `user`) that governs their permissions. Passwords are hashed with bcrypt (12 salt rounds). Google OAuth credentials are stored as JSON for federated login. Password reset tokens are hashed and carry a 1-hour expiration window.

**Activities** (`activities`)
The central entity representing campus events. Each activity is linked to a creating user (with `SET NULL` on delete to preserve event records if the creator is removed). Timestamps use `timestamptz` for timezone-aware storage. Events support soft visibility controls through `isHidden` and `isArchived` flags — enabling organizers to unpublish events without destroying data. Social media links are stored as a JSON object, and speaker lists as an array field.

**Event Registrations** (`event_registrations`)
Joins users to activities for registration and attendance tracking. Captures the registrant's college and year of study alongside an `isAttended` boolean that is set independently of the registration itself. Both the activity and user foreign keys are configured with `CASCADE` delete to automatically clean up registrations when either parent is removed.

**Tags** (`tags`) and **Activity Tags** (`activity_tags`)
A many-to-many relationship between activities and tags enables flexible event categorization. Tags have unique names and URL-friendly slugs for clean filtering URLs.

**Media** (`media`)
Stores metadata for uploaded files (cover photos and documents). Each record tracks the original filename, MIME type, file size, and the corresponding S3 key and URL. A `type` enum distinguishes between `image` and `document` uploads.

---

## 4. Core Features

### 4.1 Event Discovery & Search

**API Endpoints:**

- `GET /api/events` — List events with pagination and filters
- `GET /api/events/search` — Full-text search across title, description, location, and host
- `GET /api/events/find/:id` — Retrieve event details by ID

**User Stories:**

> _As a student, I want to browse upcoming campus events so I can find activities that interest me._

> _As a user, I want to filter events by tags, location, and date range so I can quickly narrow down relevant results._

> _As a user, I want to search events by keyword so I can locate specific topics or activities._

**Capabilities:**

- Pagination via `page` and `numberOfEventsToGet` query parameters
- Tag-based filtering through the many-to-many `activity_tags` join
- Location and host search using `ILIKE` queries for case-insensitive matching
- Date range filtering on `startDate` and `endDate`
- Archived event viewing via `isArchived` filter toggle

---

### 4.2 Event Creation & Management

**API Endpoints:**

- `POST /api/events/new` — Create event (multipart form data)
- `PUT /api/events/update/:id` — Update event details
- `DELETE /api/events/remove/:id` — Delete event
- `PUT /api/events/archive/:id` — Archive event
- `PUT /api/events/:id/cover-image` — Update cover image

**User Stories:**

> _As an event creator, I want to create events with rich details — title, description, dates, location, capacity, and cover photo — so attendees have all the information they need._

> _As an event creator, I want to archive past events instead of deleting them so I maintain a historical record._

> _As an event creator, I want to upload cover images and documents so my events are visually appealing and informative._

**Capabilities:**

- Rich event metadata: title, description, host, location, capacity, contact info
- Timezone-aware date/time management using `timestamptz`
- Cover photo upload with automatic resizing via Sharp
- Document attachments stored on S3
- Speaker lists (array field) and social media links (JSON field)
- Accessibility information field for documenting accommodations
- Hide/unhide events as a soft visibility control separate from archiving

---

### 4.3 User Registration & Attendance Tracking

**API Endpoints:**

- `POST /api/event-registration/register` — Register for an event
- `POST /api/event-registration/attend` — Quick-attend (register + mark attended)
- `PATCH /api/event-registration/attendance/:id` — Mark attendance on existing registration
- `GET /api/event-registration/stats/:activityId` — Attendance statistics
- `GET /api/event-registration/attendees/:activityId` — List attendees

**User Stories:**

> _As a student, I want to register for events so I can reserve my spot and receive updates._

> _As an event organizer, I want to track attendance to measure event success and report participation metrics._

> _As a user, I want to view my registered events so I can manage my schedule._

**Capabilities:**

- Registration captures college and year of study for demographic reporting
- Independent attendance marking (`isAttended` boolean)
- Statistics endpoint returns total registered, attended count, and attendance rate
- Attendee list endpoint with full user details for organizer review
- Automatic cleanup of orphaned registrations

---

### 4.4 Authentication & Authorization

**API Endpoints:**

- `POST /api/auth/signup` — User registration
- `POST /api/auth/login` — User login (returns JWT)
- `POST /api/auth/forgot-password` — Initiate password reset via email
- `POST /api/auth/reset-password` — Complete password reset
- `POST /api/auth/change-password` — Change password (authenticated)

**User Stories:**

> _As a new user, I want to create an account so I can register for events and track my attendance._

> _As a user, I want to reset my password securely via email so I can regain access to my account._

> _As an admin, I want to manage user roles so I can grant event creation privileges to organizers._

**Capabilities:**

- JWT-based authentication with Bearer tokens via Passport.js
- Role-based access control enforced through `RoleGuard` at the controller level
- Secure password hashing with bcrypt (12 salt rounds)
- Password reset flow via SendGrid email with hashed tokens and 1-hour expiry
- Google OAuth 2.0 integration for federated login

---

### 4.5 Tag-Based Event Categorization

**API Endpoints:**

- `GET /api/tags` — List all tags
- `POST /api/tags` — Create a new tag
- `GET /api/tags/slug/:slug` — Retrieve tag by slug

**User Stories:**

> _As an event creator, I want to tag my events with categories so users can discover them through filtering._

> _As a user, I want to filter events by tags so I can find events that match my interests._

**Capabilities:**

- Unique tag names with auto-generated URL-friendly slugs
- Many-to-many relationship with activities via the `activity_tags` join table
- Tag-based filtering integrated into the event listing and search views

---

## 5. API Reference

| Domain         | Base Path                 | Key Operations                                                  |
| -------------- | ------------------------- | --------------------------------------------------------------- |
| Authentication | `/api/auth`               | signup, login, forgot-password, reset-password, change-password |
| Users          | `/api/users`              | CRUD operations, role management (admin only)                   |
| Events         | `/api/events`             | CRUD, search, archive, cover image upload                       |
| Registration   | `/api/event-registration` | register, attend, attendance stats, attendee list               |
| Tags           | `/api/tags`               | CRUD, lookup by slug                                            |
| Media          | `/api/media`              | upload, delete, admin cleanup                                   |
| Google Auth    | `/api/google-auth`        | OAuth flow                                                      |

**Interactive API Documentation:** Available at `/api/docs` (Swagger UI) when the backend is running.

---

## 6. Non-Functional Requirements

### 6.1 Security

- **Authentication:** JWT tokens via Passport.js with configurable expiration.
- **Password Storage:** bcrypt hashing with 12 salt rounds.
- **Authorization:** Role-based guards (`RoleGuard`) enforce permissions at the controller level.
- **CORS:** Configured allowlist restricts requests to approved frontend origins.
- **PII Protection:** Console sanitization, Winston log scrubbing, and URL sanitization middleware prevent accidental data leakage.
- **Token Security:** Password reset tokens are hashed before storage and expire after 1 hour.
- **Input Validation:** A global `ValidationPipe` with `class-validator` decorators sanitizes and validates all incoming request data.

### 6.2 Performance

- **Database:** PostgreSQL with TypeORM query builder for optimized complex queries.
- **Image Optimization:** Sharp resizes uploaded images to reduce payload sizes.
- **Pagination:** Offset-based pagination on event listings to limit query result sets.
- **Client-Side Caching:** TanStack React Query handles caching, deduplication, and background refetching.
- **Server Components:** Next.js App Router leverages React Server Components for reduced client-side JavaScript.

### 6.3 Accessibility

- **Event Metadata:** An `eventAccessibility` field lets organizers document available accommodations.
- **UI Framework:** Material UI provides ARIA-compliant components out of the box.
- **Theme Support:** Dark/light mode toggle accommodates visual preferences.
- **Semantic HTML:** Next.js App Router promotes proper document structure and heading hierarchy.

### 6.4 Observability

- **Logging:** Winston logger with file rotation produces `error.log` and `combined.log` files.
- **HTTP Logging:** Custom middleware logs response times and status codes for all requests.
- **API Documentation:** Swagger UI serves as a living reference at `/api/docs`.
- **Error Handling:** Consistent `HttpException` responses with appropriate status codes and messages.

---

## 7. Roles & Permissions Matrix

| Permission             | User | Creator | Admin |
| ---------------------- | :--: | :-----: | :---: |
| Browse events          |  ✓   |    ✓    |   ✓   |
| Register for events    |  ✓   |    ✓    |   ✓   |
| Create events          |  —   |    ✓    |   ✓   |
| Edit own events        |  —   |    ✓    |   ✓   |
| Delete own events      |  —   |    ✓    |   ✓   |
| Edit any event         |  —   |    —    |   ✓   |
| Manage user roles      |  —   |    —    |   ✓   |
| View all users         |  —   |    —    |   ✓   |
| Access admin dashboard |  —   |    —    |   ✓   |

---

## 8. Known Gaps & Recommendations

### 8.1 Feature Gaps

| Feature                  | Current Status         | Recommendation                                                              |
| ------------------------ | ---------------------- | --------------------------------------------------------------------------- |
| **Push Notifications**   | Not implemented        | Add Firebase Cloud Messaging or OneSignal for event reminders               |
| **Calendar Integration** | Partial (OAuth exists) | Complete Google Calendar sync so users can add events to personal calendars |
| **Email Notifications**  | Password reset only    | Extend to registration confirmations, event reminders, and update alerts    |
| **Real-Time Updates**    | Not implemented        | Add WebSocket or SSE for live attendance counts and event updates           |
| **QR Code Check-In**     | Not implemented        | Generate QR codes for streamlined on-site event check-in                    |
| **Event Waitlists**      | Not implemented        | Queue users when events reach capacity and auto-promote on cancellations    |
| **Recurring Events**     | Not implemented        | Support weekly/monthly recurrence patterns with series management           |
| **Offline Support**      | Not implemented        | Implement Service Worker with Workbox for PWA capabilities                  |

### 8.2 Technical Debt

| Issue                          | Risk                                                         | Recommendation                                                 |
| ------------------------------ | ------------------------------------------------------------ | -------------------------------------------------------------- |
| **localStorage JWT storage**   | XSS vulnerability — tokens accessible to malicious scripts   | Migrate to HttpOnly cookies with secure and SameSite flags     |
| **Partial next-auth adoption** | Duplicate auth logic causes confusion and maintenance burden | Either fully adopt next-auth or remove the dependency          |
| **TYPEORM_SYNCHRONIZE=true**   | Dangerous in production — schema changes can cause data loss | Switch to TypeORM migrations for all schema changes            |
| **Fallback JWT secret**        | Weak default secret in production if env var is missing      | Require `JWT_SECRET` environment variable; fail fast if absent |
| **Incomplete Google OAuth**    | `updateGoogleCredentialsByEmail` contains TODO placeholders  | Complete the implementation or remove the feature flag         |

### 8.3 Scalability Considerations

| Concern                | Current State                       | Recommendation                                                           |
| ---------------------- | ----------------------------------- | ------------------------------------------------------------------------ |
| **Database Indexing**  | Minimal indexes defined             | Add indexes on `startDate`, `isArchived`, and tag slug columns           |
| **Media Delivery**     | Direct S3 URLs served to clients    | Front with CloudFront CDN for caching and reduced latency                |
| **Search Performance** | `ILIKE` queries on multiple columns | Implement PostgreSQL full-text search or consider Elasticsearch at scale |
| **Token Management**   | Stateless JWT with no revocation    | Add Redis-backed token blacklist for logout and session invalidation     |

---

## 9. Environment Configuration

| Variable           | Required         | Description                                                      |
| ------------------ | ---------------- | ---------------------------------------------------------------- |
| `POSTGRES_*`       | Yes              | Database connection parameters (host, port, user, password, db)  |
| `JWT_SECRET`       | Yes (production) | Secret key for signing JWT tokens                                |
| `SENDGRID_API_KEY` | Yes              | API key for SendGrid email service                               |
| `AWS_*`            | Yes              | AWS credentials and S3 bucket configuration                      |
| `GOOGLE_CLIENT_*`  | Optional         | Google OAuth client ID and secret                                |
| `FRONTEND_URL`     | Yes              | Frontend origin for CORS configuration and email link generation |

---

_This document describes the NSC Events platform as implemented in v2.0.0 of the codebase. It is intended to serve as the canonical product design reference for contributors and stakeholders._
