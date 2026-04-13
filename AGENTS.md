# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

Helper_Bot is a minimal Python Telegram echo bot. See `README.md` for setup steps (in Russian).

### Prerequisites

- Python 3.12 with `python3.12-venv` (system package).
- A valid Telegram `BOT_TOKEN` (from BotFather) must be available either as an environment variable or in a `.env` file in the project root. Copy `.env.example` to `.env` and fill in the token.

### Running the bot

```bash
source .venv/bin/activate
python bot.py
```

The bot uses long-polling via `python-telegram-bot`. Only one instance can poll at a time; a 409 Conflict error means another instance is already running.

### Testing

There are no automated tests in this project. To verify the environment:

1. Confirm all imports load: `python -c "import bot; print('OK')"`
2. Start the bot (`python bot.py`) and confirm the log shows `Application started`.
3. Use the Telegram Bot API (`getMe`) to confirm the token is valid.

### Gotchas

- `python3.12-venv` must be installed via `apt` before creating the virtualenv (`sudo apt-get install -y python3.12-venv`). This is a one-time system setup, not part of the update script.
- The bot will crash at startup if `BOT_TOKEN` is missing or empty.
- `.env` is gitignored; it must be created from `.env.example` on each new environment.
