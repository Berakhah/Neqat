# Neqat — Social Content Platform (prototype)

> Personal project, built on my own time and equipment. No employer code. An early prototype, not a production system. The dev script no longer carries real secrets. Older commits still contain the values I used for a local dev stack; they must not be reused anywhere.

**Secure-by-design backend architecture with enterprise IAM, real-time moderation telemetry, and scalable API services.**

---

## Why this project stands out
- **Production-grade system design**: DRF + SQL Server + Redis Channels + Keycloak
- **Enterprise IAM integration**: OIDC/OAuth2, JWT, role-based authorization
- **Security engineering focus**: encrypted PII, audit trails, rate limiting, moderation controls
- **Operational visibility**: real-time admin log streaming over WebSockets

---

## Architecture at a glance

```text
Flutter Web Client
   │
   ├── OIDC Login ───────────────▶ Keycloak
   │                                │
   └── JWT API Calls ─────────────▶ Django REST Backend
                                    │
                                    ├── Content + Moderation ─────────▶ SQL Server
                                    └── Real-time Admin Events ───────▶ Redis/Channels ─▶ WebSocket Clients
```

### Core components
- **Backend**: Django REST Framework (authn/authz, moderation, admin APIs)
- **Identity**: Keycloak (OIDC, JWT issuance, realm/client/role model)
- **Database**: Microsoft SQL Server (transactional persistence)
- **Real-time**: Django Channels + Redis (admin event streaming)
- **Frontend**: Flutter Web served through the platform stack
- **Infrastructure**: Docker Compose for local production-like orchestration

---

## Security architecture
- **Authentication**: JWT validation against Keycloak JWKS
- **Authorization**: RBAC enforced from token roles (`realm_access.roles`)
- **PII protection**: encrypted model fields for sensitive user data
- **Abuse prevention**: scoped API throttling (login/password-reset/flagging)
- **Auditability**: append-only logging patterns for system/admin actions
- **Web defense controls**: CSRF/XSS hardening headers and middleware

> See `docs/security.md` for full threat model and remediation plan.

---

## Key capabilities
- Keycloak-based login, refresh, and federated social auth flows
- Role-aware admin dashboard and moderation workflow
- Content lifecycle controls (pending/approved/rejected/flagged)
- Real-time monitoring via WebSocket log stream
- Multi-language support

---

## Tech stack
- **Backend**: Python, Django, Django REST Framework, Django Channels
- **Frontend**: Flutter Web
- **IAM**: Keycloak (OIDC/OAuth2/JWT)
- **Data**: Microsoft SQL Server
- **Messaging/RT**: Redis
- **Infra**: Docker Compose

---

## Quick start (Docker)

```bash
git clone https://github.com/Berakhah/Neqat.git
cd Neqat
docker compose up --build
```

### Default local endpoints
- App/API: `http://localhost:8000`
- Keycloak: `http://localhost:8080` (HTTPS available via compose)
- SQL Server: `localhost:1433`

> Configure secrets with environment variables. Do not use default credentials in shared or production environments.

---

## API overview

### Authentication
- `POST /api/register/`
- `POST /api/login/`
- `POST /api/token/refresh/`
- `POST /api/logout/`
- `POST /api/forgot-password/`
- `POST /api/reset-password/`

### Content
- `GET|POST /api/posts/`
- `GET|POST /api/comments/`
- `GET|POST /api/news/`
- `GET|POST /api/content-flags/`

### Admin / Moderation
- `GET /api/admin/dashboard/`
- `GET /api/admin/logs/`
- `GET /api/admin/moderation-history/`
- `GET|PATCH /api/admin/posts/`
- `GET|PATCH /api/admin/comments/`

### Real-time
- `WS /ws/admin/logs/`

---

## Recruiter-oriented highlights
- Designed as a **secure, scalable backend platform** rather than a basic CRUD app
- Demonstrates **enterprise IAM integration** and token-driven authorization
- Includes **moderation governance + traceability** patterns used in real systems
- Shows practical **cloud-native engineering** with containerized services

---

## Roadmap (enterprise hardening)
- Enforce strict JWT claim validation without lenient fallback
- Remove any TLS `verify=False` usage and enforce trusted CA bundles
- Eliminate hardcoded secrets; adopt managed secret storage/rotation
- Require authenticated/authorized WebSocket access for admin streams
- Add CI security gates (SAST, dependency scanning, secrets scanning)

---

## Documentation
- `docs/architecture.md` — system design and data flows
- `docs/security.md` — controls, risks, and remediation strategy
- `docs/api.md` — endpoint contracts and auth requirements
- `docs/decisions.md` — architecture decisions and trade-offs
