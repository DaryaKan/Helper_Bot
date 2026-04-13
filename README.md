# Helper_Bot

Telegram-бот с интерактивным чеклистом через Mini App.

## Архитектура

```
Telegram ←→ бот (Python, polling) ←→ API (aiohttp :8080) ←→ Mini App (GitHub Pages)
```

- **bot.py** — Telegram-бот + HTTP API сервер
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
WEBAPP_URL=https://your-username.github.io/Helper_Bot/
API_PORT=8080
```

4. Запустите бота:

```bash
python bot.py
```

Бот запускает одновременно:
- Telegram polling
- API сервер на `http://0.0.0.0:8080`

## Настройка GitHub Pages

1. Перейдите в **Settings → Pages** вашего репозитория
2. Source: **Deploy from a branch**
3. Branch: `main`, папка: `/docs`
4. Сохраните — через минуту Mini App будет доступен по URL

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
