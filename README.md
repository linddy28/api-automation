# API Automation — GoRest Users (Karate)

API test automation for the [GoRest](https://gorest.co.in/) users endpoints, built with the
**Karate** framework. It covers the four required operations — **List, Create, Update,
Delete** — validating the expected HTTP status code plus at least one additional assertion
on the response body for each scenario.

This project was created as part of a QA Automation technical challenge. It uses Karate
(the preferred framework in the challenge), runs on Maven + JUnit 5, ships a CI/CD pipeline
(GitHub Actions), and includes these detailed instructions.

---

## Table of contents

1. [Tech stack](#tech-stack)
2. [Project structure](#project-structure)
3. [Automated endpoints](#automated-endpoints)
4. [Prerequisites](#prerequisites)
5. [Authentication (Bearer token)](#authentication-bearer-token)
6. [Running the tests](#running-the-tests)
7. [Scenarios and assertions](#scenarios-and-assertions)
8. [Key design decisions](#key-design-decisions)
9. [CI/CD pipeline](#cicd-pipeline)
10. [Reports](#reports)
11. [Troubleshooting](#troubleshooting)

---

## Tech stack

| Tool           | Version | Purpose                              |
| -------------- | ------- | ------------------------------------ |
| Java (JDK)     | 8+ (tested on 17) | Runtime                    |
| Maven          | 3.9.x   | Build and dependency management      |
| Karate         | 1.4.1   | API automation framework             |
| JUnit 5        | 5.10.x  | Test runner                          |
| GitHub Actions | —       | CI/CD pipeline                       |

---

## Project structure

```
api-automation/
├── pom.xml                                   # Maven config + dependencies
├── .github/
│   └── workflows/
│       └── api-tests.yml                     # CI pipeline (GitHub Actions)
├── .gitignore
├── README.md
└── src/test/java/
    ├── karate-config.js                      # Global config: baseUrl, token, headers, timeouts
    ├── logback-test.xml                      # Logging configuration
    └── com/bancosol/
        ├── UsersRunner.java                  # JUnit 5 runner
        └── users.feature                     # Feature file with the 4 scenarios
```

### What lives where

- **`pom.xml`** — Declares Karate + JUnit 5, and configures Surefire so the runner and the
  `.feature` files are picked up.
- **`karate-config.js`** — Runs once before any feature. Sets the base URL, the Bearer
  token, the default headers applied to every request, and connection timeouts.
- **`UsersRunner.java`** — The JUnit 5 entry point that tells Karate which feature(s) to
  run.
- **`users.feature`** — The actual scenarios written in Gherkin using Karate's DSL.

---

## Automated endpoints

**Base URL:** `https://gorest.co.in/public/v2`

| Scenario    | Method | Path            | Expected status      |
| ----------- | ------ | --------------- | -------------------- |
| List users  | GET    | `/users`        | `200`                |
| Create user | POST   | `/users`        | `201`                |
| Update user | PATCH  | `/users/{id}`   | `200`                |
| Delete user | DELETE | `/users/{id}`   | `204` (+ `404` on GET) |

Each scenario validates the **status code and at least one additional assertion** on the
response body.

---

## Prerequisites

- **Java JDK 8 or higher** (tested with 11 / 17)
- **Maven** configured
  ([installation guide](https://www.baeldung.com/install-maven-on-windows-linux-mac))
- **Git**

Verify your setup:

```bash
java -version
mvn -version
```

---

## Authentication (Bearer token)

Every request needs a Bearer token. The token is resolved in this order of priority:

1. System property: `-Dgorest.token=YOUR_TOKEN`
2. Environment variable: `GOREST_TOKEN`
3. A default value baked into `karate-config.js` (the token provided in the challenge)

The token is applied to **all requests** using `karate.configure('headers', ...)` in
`karate-config.js`, so it persists across every step within a scenario.

> **Security note:** in CI it is recommended to provide the token via the `GOREST_TOKEN`
> secret instead of relying on the default hard-coded value.

---

## Running the tests

```bash
cd api-automation

# Run all scenarios
mvn test

# Provide your own token
mvn test -Dgorest.token=YOUR_TOKEN

# Run a single tag (example: only the Create scenario)
mvn test -Dkarate.options="--tags @create"
```

### Available tags

`@list`, `@create`, `@update`, `@delete`

> On macOS, if `java` is not found, point `JAVA_HOME` at a JDK first, for example:
> `export JAVA_HOME=$(/usr/libexec/java_home -v 17)`

---

## Scenarios and assertions

Each scenario asserts the expected status code plus at least one body assertion.

### 1. List users — `@list`
- `status 200`
- The response is an array.
- Every item contains `id`, `name`, `email`, `status` with the expected types.

### 2. Create user — `@create`
- `status 201`
- A numeric `id` is generated.
- The `name`, `email` and `status` in the response match what was sent.
- A unique email is generated per run to avoid `422 email already taken`.

### 3. Update user — `@update`
- First creates a user (dynamic id), then waits until it is queryable.
- `PATCH` returns `status 200`.
- The `name` was updated.
- The `email` was updated and the `id` is preserved.

### 4. Delete user — `@delete`
- First creates a user (dynamic id), then waits until it is queryable.
- `DELETE` returns `status 204`.
- A follow-up `GET` on the deleted id returns `status 404`.

---

## Key design decisions

- **Dynamic ids for Update/Delete.** Instead of relying on the fixed id `6940344` from the
  challenge (which may not exist), the Update and Delete scenarios **create their own user
  first**. This makes the tests deterministic and repeatable.

- **Headers configured globally.** In Karate, a header set with `header ...` only applies to
  the **next** request. GoRest responds with `404` (not `401`) to unauthenticated requests
  against a specific user id. Therefore the `Authorization: Bearer` header (and `Accept` /
  `Content-Type`) are set once via `karate.configure('headers', ...)` in `karate-config.js`
  so they persist across every request in a scenario. This was the root cause of an initial
  round of `404` failures on PATCH/DELETE and is now fixed.

- **Retry as a safety net.** A `retry until responseStatus == 200` guard (configured with
  5 attempts, 1s interval) is used before Update/Delete to absorb any propagation delay for
  a just-created resource.

- **Unique emails.** Emails are suffixed with a timestamp so re-running the suite never
  collides with an already-registered email.

---

## CI/CD pipeline

The workflow at `.github/workflows/api-tests.yml` runs on every push and pull request to
`main`/`master` (and can be triggered manually). It:

1. Checks out the repository.
2. Sets up JDK 17 (Temurin) with Maven cache.
3. Runs `mvn -B test`, passing the token from the `GOREST_TOKEN` secret.
4. Uploads the Karate HTML reports as a build artifact.

Configure the secret in GitHub: **Settings → Secrets and variables → Actions → New
repository secret**, named `GOREST_TOKEN`.

---

## Reports

After a run, Karate generates an HTML report:

```
target/karate-reports/karate-summary.html
```

Open it in a browser to see per-scenario results, request/response details and timings.

---

## Troubleshooting

**`java: command not found` / wrong Java version**
Point `JAVA_HOME` at a JDK 8+ installation. On macOS:
`export JAVA_HOME=$(/usr/libexec/java_home -v 17)`.

**`422 Unprocessable Entity` with "email has already been taken"**
This means a non-unique email reached the API. The scenarios already generate unique emails
per run; if you customize the payload, keep the email unique.

**`404 Resource not found` on PATCH/DELETE**
Ensure the `Authorization` header is being sent on every request. This project handles it
via `karate.configure('headers', ...)`; do not move the auth header back to a per-request
`header` step in the `Background`.

**Rate limiting**
GoRest applies rate limits (see the `x-ratelimit-*` response headers). If you hit them, wait
for the reset window and re-run.
