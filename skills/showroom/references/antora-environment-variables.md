# Antora Environment Variables

Reference: https://docs.antora.org/antora/latest/playbook/environment-variables/

Environment variables take precedence over playbook keys. CLI options take precedence over environment variables.

## Key Variables for Showroom

| Variable | Format | Default | Use Case |
|----------|--------|---------|----------|
| `URL` | String | Not set | Overrides `site.url` in playbook. Set when publishing to a specific domain. |
| `CI` | Boolean | Not set | When `true`: JSON log format, suppresses stdout, hides edit-page links. Set in CI pipelines. |
| `GIT_CREDENTIALS` | String | Not set | Auth for private content source repos. Format: `https://user:token@host` |
| `GIT_CREDENTIALS_PATH` | String | Not set | Path to git credentials file (alternative to inline `GIT_CREDENTIALS`) |
| `ANTORA_CACHE_DIR` | String | `<user cache>/antora` | Custom cache directory. Useful in CI to persist cache between runs. |
| `ANTORA_LOG_LEVEL` | String | `warn` | Log verbosity: `error`, `warn`, `info`, `debug`. Set to `debug` when troubleshooting. |
| `ANTORA_LOG_FAILURE_LEVEL` | String | Not set | Fail the build if log messages at this level or above are emitted. Set to `warn` in CI. |
| `ANTORA_LOG_FORMAT` | String | Auto | `pretty` (interactive) or `json` (CI). Auto-detected based on `CI` and terminal. |
| `GOOGLE_ANALYTICS_KEY` | String | Not set | Google Analytics tracking ID for the generated site. |

## Usage Examples

### Unset a conflicting variable temporarily
```bash
env -u URL antora antora-playbook.yml
```

### CI pipeline with strict validation
```bash
export CI=true
export ANTORA_LOG_FAILURE_LEVEL=warn
antora antora-playbook.yml
```

### Debug a failing build
```bash
ANTORA_LOG_LEVEL=debug antora antora-playbook.yml
```

### Private content repo authentication
```bash
export GIT_CREDENTIALS='https://token:ghp_xxx@github.com'
antora antora-playbook.yml
```
