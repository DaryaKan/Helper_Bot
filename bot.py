import asyncio
import hashlib
import hmac
import json
import logging
import os
import uuid
from dataclasses import dataclass, field
from urllib.parse import parse_qsl

from aiohttp import web
from dotenv import load_dotenv
from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update, WebAppInfo
from telegram.ext import (
    Application,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)

MAX_TASKS_PER_LIST = 10


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

@dataclass
class Task:
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:8])
    text: str = ""
    done: bool = False
    color: str = "#f4f4f4"
    category: str = ""
    drawing: str = ""


@dataclass
class Checklist:
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:8])
    chat_id: int = 0
    tasks: list[Task] = field(default_factory=list)


checklists: dict[int, list[Checklist]] = {}


def _get_or_create_current(chat_id: int) -> Checklist:
    chat_lists = checklists.setdefault(chat_id, [])
    if not chat_lists or len(chat_lists[-1].tasks) >= MAX_TASKS_PER_LIST:
        cl = Checklist(chat_id=chat_id)
        chat_lists.append(cl)
    return chat_lists[-1]


def _serialize_checklists(chat_id: int) -> list[dict]:
    return [
        {
            "id": cl.id,
            "tasks": [
                {"id": t.id, "text": t.text, "done": t.done, "color": t.color, "category": t.category, "drawing": t.drawing}
                for t in cl.tasks
            ],
        }
        for cl in checklists.get(chat_id, [])
    ]


# ---------------------------------------------------------------------------
# Telegram init_data validation
# ---------------------------------------------------------------------------

def _validate_init_data(init_data: str, bot_token: str) -> dict | None:
    parsed = dict(parse_qsl(init_data, keep_blank_values=True))
    received_hash = parsed.pop("hash", None)
    if not received_hash:
        return None

    data_check_string = "\n".join(
        f"{k}={v}" for k, v in sorted(parsed.items())
    )
    secret_key = hmac.new(b"WebAppData", bot_token.encode(), hashlib.sha256).digest()
    computed = hmac.new(secret_key, data_check_string.encode(), hashlib.sha256).hexdigest()

    if not hmac.compare_digest(computed, received_hash):
        return None

    user_data = parsed.get("user")
    if user_data:
        parsed["user"] = json.loads(user_data)
    chat_data = parsed.get("chat")
    if chat_data:
        parsed["chat"] = json.loads(chat_data)
    return parsed


def _extract_chat_id(validated: dict) -> int | None:
    if "chat" in validated and "id" in validated["chat"]:
        return validated["chat"]["id"]
    if "user" in validated and "id" in validated["user"]:
        return validated["user"]["id"]
    return None


# ---------------------------------------------------------------------------
# API handlers (aiohttp)
# ---------------------------------------------------------------------------

def _make_cors_headers() -> dict:
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, X-Telegram-Init-Data",
    }


def _json_response(data: dict, status: int = 200) -> web.Response:
    return web.json_response(data, status=status, headers=_make_cors_headers())


async def handle_options(request: web.Request) -> web.Response:
    return web.Response(status=204, headers=_make_cors_headers())


def _auth(request: web.Request) -> int | None:
    init_data = request.headers.get("X-Telegram-Init-Data", "")
    if not init_data:
        return None
    bot_token = request.app["bot_token"]
    validated = _validate_init_data(init_data, bot_token)
    if not validated:
        return None
    return _extract_chat_id(validated)


async def api_get_tasks(request: web.Request) -> web.Response:
    chat_id = _auth(request)
    if chat_id is None:
        return _json_response({"error": "unauthorized"}, 401)
    return _json_response({"lists": _serialize_checklists(chat_id)})


async def api_add_task(request: web.Request) -> web.Response:
    chat_id = _auth(request)
    if chat_id is None:
        return _json_response({"error": "unauthorized"}, 401)

    body = await request.json()
    text = (body.get("text") or "").strip()
    if not text:
        return _json_response({"error": "text required"}, 400)

    color = (body.get("color") or "#f4f4f4").strip()
    category = (body.get("category") or "").strip()
    drawing = body.get("drawing") or ""

    cl = _get_or_create_current(chat_id)
    task = Task(text=text, color=color, category=category, drawing=drawing)
    cl.tasks.append(task)

    return _json_response({
        "task": {"id": task.id, "text": task.text, "done": task.done, "color": task.color, "category": task.category, "drawing": task.drawing},
        "list_id": cl.id,
        "lists": _serialize_checklists(chat_id),
    })


async def api_toggle_task(request: web.Request) -> web.Response:
    chat_id = _auth(request)
    if chat_id is None:
        return _json_response({"error": "unauthorized"}, 401)

    body = await request.json()
    task_id = body.get("task_id", "")

    for cl in checklists.get(chat_id, []):
        for task in cl.tasks:
            if task.id == task_id:
                task.done = not task.done
                return _json_response({
                    "task": {"id": task.id, "text": task.text, "done": task.done, "color": task.color, "category": task.category, "drawing": task.drawing},
                    "lists": _serialize_checklists(chat_id),
                })

    return _json_response({"error": "task not found"}, 404)


async def api_update_task(request: web.Request) -> web.Response:
    chat_id = _auth(request)
    if chat_id is None:
        return _json_response({"error": "unauthorized"}, 401)

    body = await request.json()
    task_id = body.get("task_id", "")

    for cl in checklists.get(chat_id, []):
        for task in cl.tasks:
            if task.id == task_id:
                if "text" in body:
                    task.text = (body["text"] or "").strip() or task.text
                if "color" in body:
                    task.color = (body["color"] or "#f4f4f4").strip()
                if "category" in body:
                    task.category = (body["category"] or "").strip()
                if "drawing" in body:
                    task.drawing = body["drawing"] or ""
                return _json_response({
                    "task": {"id": task.id, "text": task.text, "done": task.done, "color": task.color, "category": task.category, "drawing": task.drawing},
                    "lists": _serialize_checklists(chat_id),
                })

    return _json_response({"error": "task not found"}, 404)


async def api_delete_task(request: web.Request) -> web.Response:
    chat_id = _auth(request)
    if chat_id is None:
        return _json_response({"error": "unauthorized"}, 401)

    body = await request.json()
    task_id = body.get("task_id", "")

    for cl in checklists.get(chat_id, []):
        for i, task in enumerate(cl.tasks):
            if task.id == task_id:
                cl.tasks.pop(i)
                return _json_response({"lists": _serialize_checklists(chat_id)})

    return _json_response({"error": "task not found"}, 404)


# ---------------------------------------------------------------------------
# Telegram bot handlers
# ---------------------------------------------------------------------------

def _webapp_url() -> str:
    return os.getenv("WEBAPP_URL", "")


async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    webapp_url = _webapp_url()
    if not webapp_url:
        await update.message.reply_text(
            "Привет! Я Helper_Bot 📋\n"
            "WEBAPP_URL не настроен — Mini App недоступен."
        )
        return

    keyboard = InlineKeyboardMarkup([
        [InlineKeyboardButton("📋 Открыть чеклист", web_app=WebAppInfo(url=webapp_url))]
    ])
    await update.message.reply_text(
        "Привет! Я Helper_Bot 📋\n\n"
        "Нажми кнопку ниже, чтобы открыть чеклист.\n"
        "Добавляй задачи и отмечай выполненные — вместе!",
        reply_markup=keyboard,
    )


async def cmd_checklist(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    webapp_url = _webapp_url()
    if not webapp_url:
        await update.message.reply_text("WEBAPP_URL не настроен.")
        return

    keyboard = InlineKeyboardMarkup([
        [InlineKeyboardButton("📋 Открыть чеклист", web_app=WebAppInfo(url=webapp_url))]
    ])
    await update.message.reply_text(
        "📋 Нажми кнопку, чтобы открыть чеклист:",
        reply_markup=keyboard,
    )


async def echo_add_task(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if not update.message or not update.message.text:
        return

    chat_id = update.effective_chat.id
    text = update.message.text.strip()
    if not text:
        return

    cl = _get_or_create_current(chat_id)
    task = Task(text=text)
    cl.tasks.append(task)

    total = sum(len(c.tasks) for c in checklists.get(chat_id, []))
    await update.message.reply_text(
        f"✅ Задача добавлена (всего: {total}). "
        "Открой /checklist чтобы посмотреть."
    )


# ---------------------------------------------------------------------------
# Startup
# ---------------------------------------------------------------------------

async def run_api_server(app: web.Application, host: str, port: int) -> None:
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, host, port)
    await site.start()
    logger.info("API server started on http://%s:%d", host, port)


def main() -> None:
    load_dotenv()
    token = os.getenv("BOT_TOKEN")
    if not token:
        raise RuntimeError("BOT_TOKEN is not set. Put it in your .env file.")

    api_port = int(os.getenv("API_PORT", "8080"))

    # --- aiohttp API ---
    api_app = web.Application()
    api_app["bot_token"] = token

    api_app.router.add_route("OPTIONS", "/api/tasks", handle_options)
    api_app.router.add_route("OPTIONS", "/api/tasks/add", handle_options)
    api_app.router.add_route("OPTIONS", "/api/tasks/toggle", handle_options)
    api_app.router.add_route("OPTIONS", "/api/tasks/update", handle_options)
    api_app.router.add_route("OPTIONS", "/api/tasks/delete", handle_options)

    api_app.router.add_get("/api/tasks", api_get_tasks)
    api_app.router.add_post("/api/tasks/add", api_add_task)
    api_app.router.add_post("/api/tasks/toggle", api_toggle_task)
    api_app.router.add_post("/api/tasks/update", api_update_task)
    api_app.router.add_post("/api/tasks/delete", api_delete_task)

    docs_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "docs")
    if os.path.isdir(docs_dir):
        api_app.router.add_static("/", docs_dir, name="static")

    # --- Telegram bot ---
    application = Application.builder().token(token).build()
    application.add_handler(CommandHandler("start", cmd_start))
    application.add_handler(CommandHandler("checklist", cmd_checklist))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, echo_add_task))

    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    loop.run_until_complete(run_api_server(api_app, "0.0.0.0", api_port))
    logger.info("Starting Telegram polling...")
    application.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
