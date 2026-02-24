# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | Yes       |

## Reporting a Vulnerability

Please do **not** open a public GitHub issue for security vulnerabilities.

Instead, email: **jon-build@proton.me**

Include:
- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fixes

You can expect an acknowledgement within 48 hours and a resolution or mitigation plan within 14 days.

## Scope

Marksmith is a local-only macOS utility. It reads clipboard content, converts Markdown to rich text, and writes it back. It makes no network connections and stores no user data beyond preferences in `UserDefaults`.

Relevant security concerns:
- XSS in generated HTML (mitigated: all user content is HTML-entity-escaped, including raw HTML blocks and inline HTML)
- Malicious clipboard content triggering unexpected behavior
- Privilege escalation via the app's unsandboxed clipboard access
