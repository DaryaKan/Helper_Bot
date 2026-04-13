# Helper_Bot

Telegram-бот с интерактивным чеклистом через Mini App.

## Архитектура

```
Telegram ←→ бот (Python, polling + aiohttp :8080) ←→ Mini App (встроен в тот же сервер)
```

- **bot.py** — Telegram-бот + HTTP API + раздача статики (`docs/`)
- **docs/index.html** — Mini App (фронтенд чеклиста)

## Быстрый запуск

1. Создайте виртуальное окружение:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

2. Установите зависимости:

```bash
pip install -r requirements.txt
```

3. Создайте `.env` из примера и заполните:

```bash
cp .env.example .env
```

Содержимое `.env`:

```env
BOT_TOKEN=ваш_токен_из_BotFather
WEBAPP_URL=https://your-domain.com/index.html
API_PORT=8080
```

> **WEBAPP_URL** должен быть HTTPS. Варианты:
> - VPS с доменом и SSL-сертификатом — `https://your-domain.com/index.html`
> - ngrok/cloudflared для локальной разработки — `https://xxxx.ngrok-free.app/index.html`
> - GitHub Pages (если API на отдельном сервере) — `https://user.github.io/Helper_Bot/?api=https://your-api.com`

4. Запустите бота:

```bash
python bot.py
```

Бот запускает одновременно:
- Telegram polling
- HTTP-сервер на `http://0.0.0.0:8080` (API + статика `docs/`)

## Команды бота

- `/start` — приветствие + кнопка Mini App
- `/checklist` — кнопка для открытия чеклиста
- текстовое сообщение — добавляет задачу в чеклист

## API эндпоинты

| Метод | URL | Описание |
|-------|-----|----------|
| GET | `/api/tasks` | Получить все чеклисты |
| POST | `/api/tasks/add` | Добавить задачу (`{"text": "..."}`) |
| POST | `/api/tasks/toggle` | Переключить статус (`{"task_id": "..."}`) |
| POST | `/api/tasks/delete` | Удалить задачу (`{"task_id": "..."}`) |

Все запросы требуют заголовок `X-Telegram-Init-Data` с валидными данными из Telegram WebApp SDK.
