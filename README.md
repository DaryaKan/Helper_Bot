# Helper_Bot

Минимальный Telegram-бот на Python.

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

3. Создайте `.env` из примера и вставьте токен бота:

```bash
cp .env.example .env
```

Содержимое `.env`:

```env
BOT_TOKEN=ваш_токен_из_BotFather
```

4. Запустите бота:

```bash
python bot.py
```

## Команды

- `/start` — приветствие
- любое текстовое сообщение — бот повторяет сообщение
