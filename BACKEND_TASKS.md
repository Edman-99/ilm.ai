# Backend Tasks — ILM Web App

## Что убрать (больше не используется на фронте)

### Убрать из AI Analysis сервера:
- `POST /auth/register` — регистрация убрана
- `POST /auth/login` — авторизация убрана
- `POST /analyze/portfolio-builder` — Portfolio Builder убран
- Логика тарифов (free/pro/premium) — лимитов нет, все режимы доступны всем
- JWT валидация на `/analyze` — запросы идут без токена

### Не нужно реализовывать:
- Тарифные планы и биллинг
- Ежедневные лимиты запросов
- User profile / session management

---

## P0 — Без этого не запустимся

### 1. Задеплоить AI Analysis API на постоянный хост

Сейчас: `https://b5ab-31-171-168-220.ngrok-free.app` — умирает при рестарте ngrok.

Нужно: стабильный URL (subdomain, VPS, cloud function). После деплоя — сообщить URL, фронт поменяет одну строку в `lib/main.dart:20`.

---

### 2. `POST /leads` — сохранение лидов

Фронт шлёт при первом анализе и перед демо Trading Analytics. Без авторизации.

**Request:**
```json
POST /leads
Content-Type: application/json

{
  "first_name": "Иван",            // обязательное
  "last_name": "Петров",            // опциональное
  "email": "ivan@mail.ru",          // обязательное
  "whatsapp": "+77001234567",        // опциональное
  "source": "ai_analysis"           // откуда пришёл: "ai_analysis" или "trading_demo"
}
```

**Response:** `200 OK` (любой body)

**Действия:**
- Сохранять в БД
- Дедупликация по email (обновлять если уже есть)
- Пушить в CRM / Telegram менеджерам (имя, email, WhatsApp, source)
- Менеджер должен видеть: "Иван Петров пришёл через AI анализ" или "через Trading demo"

---

### 3. `GET /analyze/{ticker}?mode={mode}` — проверить формат ответа

Без авторизации. Без лимитов. 9 режимов: `full`, `technical`, `screener`, `risk`, `dcf`, `earnings`, `portfolio`, `dividends`, `competitors`.

**Response (все поля обязательные):**
```json
{
  "ticker": "AAPL",
  "mode": "technical",
  "mode_description": "Technical Analysis",
  "price": 189.50,
  "change_1m": 5.3,
  "rsi": 45.2,
  "sma20": 185.30,
  "sma50": 180.10,
  "macd": 0.0052,
  "macd_signal": 0.0031,
  "bb_upper": 195.40,
  "bb_lower": 175.20,
  "atr": 3.45,
  "trend": "Bullish",
  "score": 72,
  "analysis": "## Section Title\n\nMarkdown text..."
}
```

**Важно:**
- `score` — целое число 0-100
- `trend` — строка ("Bullish" / "Bearish")
- `analysis` — markdown с `##` заголовками секций (фронт парсит по ним и показывает как отдельные карточки)
- Ответ без обёртки — просто JSON объект, не `{ "data": { ... } }`

---

## P1 — Trading Analytics (уже работает, проверить стабильность)

Эндпоинты на `app12-us-sw.ivlk.io`. Используются в Trading Analytics табе.

### 4. `POST /auth_db/login/`

```json
// Request
{ "email": "user@example.com", "password": "pass123" }

// Response
{ "tokens": { "access": "jwt_token", "refresh": "refresh_token" } }
```

---

### 5. `GET /orders/order_history/`

Пагинация. Фронт читает `results` или `orders` массив + поле `next`.

**Query params:** `?status=filled&page_size=500&page=1`

```json
// Response
{
  "results": [
    {
      "id": "order_1",
      "symbol": "AAPL",
      "side": "buy",
      "status": "filled",
      "filled_qty": 10,
      "filled_avg_price": 172.50,
      "filled_at": "2026-01-15T14:30:00Z",
      "created_at": "2026-01-15T14:30:00Z",
      "avg_entry_price": 172.50,
      "commission": 0.02,
      "profit_cash": 185.0,
      "profit_percent": 10.7
    }
  ],
  "next": null
}
```

**Auth:** `Authorization: Bearer <access_token>`

---

### 6. `GET /alpaca/get_all_positions/`

Фронт обрабатывает оба формата: массив или `{ "positions": [...] }`.

```json
[
  {
    "symbol": "AAPL",
    "qty": 15,
    "avg_entry_price": 188.30,
    "current_price": 192.50,
    "market_value": 2887.50,
    "unrealized_pl": 63.0,
    "unrealized_plpc": 2.23,
    "side": "long"
  }
]
```

**Auth:** `Authorization: Bearer <access_token>`

---

### 7. `GET /proxy_api/v1/polygon/ticker_history`

Спарклайны — 30 дней close prices для графиков.

**Query params:** `?ticker=AAPL&adjusted=true&sort=asc&timePeriod=1/day/2026-02-27/2026-03-29&limit=30`

```json
{
  "results": [
    { "c": 189.50, "h": 190.25, "l": 188.75, "o": 189.00, "t": 1646000000000, "v": 45000000 }
  ]
}
```

Фронт использует только поле `c` (close price).

**Auth:** `Authorization: Bearer <access_token>`

---

## P2 — Следующий этап

### 8. CORS заголовки на AI Analysis сервере

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, ngrok-skip-browser-warning
```

Обязательно обработать `OPTIONS` preflight запросы — вернуть `200` с заголовками.

---

### 9. `POST /auth/token/refresh/` — обновление JWT (Trading)

Фронт уже сохраняет `refresh` токен, но пока не использует. Нужен когда `access` протухает.

```json
// Request
{ "refresh": "refresh_token_here" }

// Response
{ "access": "new_access_token" }
```

---

### 10. Strategies CRUD (будущее)

Ручное управление стратегиями пользователя. Сейчас стратегии только в демо (хардкод).

```
POST   /strategies              — создать стратегию
GET    /strategies              — список стратегий пользователя
PUT    /strategies/{id}         — обновить (имя, описание, тикеры)
DELETE /strategies/{id}         — удалить
```

**Модель:**
```json
{
  "id": "uuid",
  "name": "Growth",
  "description": "High-growth tech stocks",
  "icon": "trending_up",
  "color": "#22C55E",
  "symbols": ["NVDA", "TSLA", "AMD"]
}
```

**Auth:** `Authorization: Bearer <access_token>`

---

### 11. Расширить `/leads` — трекинг действий

Добавить в лид информацию о том что пользователь делал:

```json
{
  "first_name": "Иван",
  "email": "ivan@mail.ru",
  "whatsapp": "+77001234567",
  "source": "ai_analysis",
  "tickers_analyzed": ["AAPL", "TSLA", "NVDA"],
  "modes_used": ["full", "technical"],
  "analysis_count": 3
}
```

Это позволит менеджерам видеть: "Иван проанализировал AAPL, TSLA, NVDA — интересуется техническим анализом".

---

## Сводная таблица

| # | Что | Приоритет | Статус |
|---|-----|-----------|--------|
| — | Убрать `/auth/register`, `/auth/login`, `/analyze/portfolio-builder` | **P0** | Убрать |
| — | Убрать JWT валидацию и тарифы на `/analyze` | **P0** | Убрать |
| 1 | Задеплоить AI API на постоянный хост | **P0** | Сделать |
| 2 | `POST /leads` | **P0** | Сделать |
| 3 | Проверить формат `/analyze/{ticker}` | **P0** | Проверить |
| 4 | `POST /auth_db/login/` | P1 | Уже есть |
| 5 | `GET /orders/order_history/` | P1 | Уже есть |
| 6 | `GET /alpaca/get_all_positions/` | P1 | Уже есть |
| 7 | `GET /proxy_api/v1/polygon/ticker_history` | P1 | Уже есть |
| 8 | CORS на AI сервере | P2 | Настроить |
| 9 | `POST /auth/token/refresh/` | P2 | Добавить |
| 10 | `/strategies` CRUD | P2 | Будущее |
| 11 | Расширить `/leads` трекингом | P2 | Будущее |

---

## Конфигурация фронта после деплоя

Когда AI API задеплоен — сообщить URL. Фронт обновит:
- `lib/main.dart:20` — заменить `_baseUrl` на новый URL
- `api/proxy.js:17` — заменить URL в Vercel proxy
- Убрать заголовок `ngrok-skip-browser-warning` из `main.dart:44`
