import logging
import os
from dataclasses import dataclass, field

from dotenv import load_dotenv
from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.ext import (
    Application,
    CallbackQueryHandler,
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

MAX_TASKS_PER_MESSAGE = 10


@dataclass
class Task:
    text: str
    done: bool = False


@dataclass
class ChecklistMessage:
    message_id: int
    tasks: list[Task] = field(default_factory=list)


checklists: dict[int, list[ChecklistMessage]] = {}


def _render(cl: ChecklistMessage, page: int | None = None) -> tuple[str, InlineKeyboardMarkup]:
    header = f"📋 <b>Чеклист #{page}</b>" if page else "📋 <b>Чеклист</b>"
    lines = [header, ""]

    buttons: list[list[InlineKeyboardButton]] = []
    for i, task in enumerate(cl.tasks):
        icon = "✅" if task.done else "⬜"
        lines.append(f"{icon} {task.text}")
        btn_label = f"{icon} {task.text}"
        if len(btn_label) > 64:
            btn_label = btn_label[:61] + "…"
        buttons.append([
            InlineKeyboardButton(btn_label, callback_data=f"t:{cl.message_id}:{i}")
        ])

    done = sum(1 for t in cl.tasks if t.done)
    lines.append(f"\nВыполнено: {done}/{len(cl.tasks)}")

    return "\n".join(lines), InlineKeyboardMarkup(buttons)


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text(
        "Привет! Я Helper_Bot 📋\n\n"
        "Отправь текстовое сообщение — я добавлю его как задачу в чеклист.\n"
        "Нажимай кнопки, чтобы отмечать выполненное. "
        "Любой участник чата может отмечать задачи.\n\n"
        f"Лимит задач в одном списке: {MAX_TASKS_PER_MESSAGE}.\n"
        "Когда лимит достигнут — создаётся новый список."
    )


async def add_task(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if not update.message or not update.message.text:
        return

    chat_id = update.effective_chat.id
    task_text = update.message.text.strip()
    if not task_text:
        return

    chat_lists = checklists.setdefault(chat_id, [])
    need_new = not chat_lists or len(chat_lists[-1].tasks) >= MAX_TASKS_PER_MESSAGE

    if need_new:
        page = len(chat_lists) + 1
        cl = ChecklistMessage(message_id=0, tasks=[Task(text=task_text)])
        chat_lists.append(cl)

        text, kb = _render(cl, page if page > 1 else None)
        sent = await update.message.reply_text(text, reply_markup=kb, parse_mode="HTML")
        cl.message_id = sent.message_id
    else:
        cl = chat_lists[-1]
        cl.tasks.append(Task(text=task_text))

        page = len(chat_lists)
        text, kb = _render(cl, page if page > 1 else None)
        try:
            await context.bot.edit_message_text(
                chat_id=chat_id,
                message_id=cl.message_id,
                text=text,
                reply_markup=kb,
                parse_mode="HTML",
            )
        except Exception:
            logger.exception("Failed to edit checklist message")


async def toggle_task(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    query = update.callback_query
    await query.answer()

    parts = (query.data or "").split(":")
    if len(parts) != 3:
        return

    try:
        msg_id, task_idx = int(parts[1]), int(parts[2])
    except ValueError:
        return

    chat_id = update.effective_chat.id
    chat_lists = checklists.get(chat_id, [])

    for list_idx, cl in enumerate(chat_lists):
        if cl.message_id != msg_id:
            continue
        if not (0 <= task_idx < len(cl.tasks)):
            break

        cl.tasks[task_idx].done = not cl.tasks[task_idx].done
        page = list_idx + 1
        text, kb = _render(cl, page if len(chat_lists) > 1 else None)
        try:
            await query.edit_message_text(text=text, reply_markup=kb, parse_mode="HTML")
        except Exception:
            logger.exception("Failed to update checklist")
        break


def main() -> None:
    load_dotenv()
    token = os.getenv("BOT_TOKEN")

    if not token:
        raise RuntimeError("BOT_TOKEN is not set. Put it in your .env file.")

    application = Application.builder().token(token).build()
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(toggle_task, pattern=r"^t:"))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, add_task))

    application.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
