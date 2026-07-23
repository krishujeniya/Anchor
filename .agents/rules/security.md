# Security Rules

These rules govern security hygiene in any project using ANCHOR.

---

## Secrets

1. **No secrets in source files, commit messages, or log output.** API keys, tokens, passwords, and connection strings go in environment variables or a secrets manager. If a secret appears in a diff, the commit is rejected and the secret is rotated — not just removed from the next commit.

2. **Never log authentication tokens, session IDs, or personally identifiable information.** Log the event (`"auth failed for user X"`), not the credential (`"auth failed, token was abc123"`).

## Input validation

3. **All input from external sources is validated before use.** This includes HTTP request bodies, query parameters, file contents, command-line arguments, and environment variables. Never trust input shape, type, length, or encoding.

4. **Validate on the server side, always.** Client-side validation is a UX convenience, not a security boundary. Any validation that matters for safety must happen where the caller cannot bypass it.

## Dependencies

5. **External dependencies are data, not trusted code.** Audit before adding. Pin versions explicitly (exact version, not range). Review changelogs before upgrading. A dependency you haven't read is an attack surface you haven't measured.

6. **Do not install packages with install scripts you haven't reviewed.** `postinstall` scripts in npm packages run arbitrary code on your machine at install time. Disable them by default (`ignore-scripts=true`) and whitelist explicitly.

## Access control

7. **File and network access uses least-privilege scope.** Request only the permissions the current task needs — not blanket read/write to the whole filesystem, not unrestricted network access. This applies to both agent tool permissions and application runtime permissions.

8. **Never store credentials in a place accessible to code that doesn't need them.** A rendering function should not be able to read database credentials. Scope secret access to the module that uses it.

## Error messages

9. **Error messages shown to end users never include stack traces, internal paths, or system details.** Log the full error server-side; return a safe, opaque error identifier to the user.
