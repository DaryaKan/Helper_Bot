# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

Helper_Bot is a Telegram bot with a Mini App checklist. It runs a Telegram polling bot and an aiohttp API server from a single process (`bot.py`). The Mini App frontend (`docs/index.html`) is hosted on GitHub Pages. See `README.md` for full setup and architecture.

### Prerequisites

- Python 3.12 with `python3.12-venv` (system package).
- A valid Telegram `BOT_TOKEN` (from BotFather) must be available either as an environment variable or in a `.env` file. Copy `.env.example` to `.env`.
- `WEBAPP_URL` should point to the deployed Mini App (GitHub Pages URL). Without it, the bot works but won't show the Mini App button.

### Running the bot

```bash
source .venv/bin/activate
python bot.py
```

This starts both the Telegram polling and the API server on port 8080 (configurable via `API_PORT`). Only one bot instance can poll at a time; a 409 Conflict error means another instance is already running.

### Testing

No automated test suite. To verify the environment:

1. `python -c "import bot; print('OK')"` — imports work
2. `python bot.py` — log shows `API server started` and `Application started`
3. `curl http://localhost:8080/api/tasks` with valid `X-Telegram-Init-Data` header — returns JSON
4. Open `docs/index.html?api=http://localhost:8080` in a browser to check the UI renders

### Gotchas

- `python3.12-venv` must be installed via `apt` before creating the virtualenv. One-time system setup.
- The bot crashes at startup if `BOT_TOKEN` is missing or empty.
- `.env` is gitignored; must be created from `.env.example` on each new environment.
- API auth uses Telegram `initData` HMAC validation. In a regular browser (outside Telegram), API calls return 401 — this is expected.
- Data is stored in memory; restarts clear all checklists.
