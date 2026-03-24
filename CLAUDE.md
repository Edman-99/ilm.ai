# CLAUDE.md — AI Stock Analyzer (Web)

## Обзор

Flutter web проект для AI анализа акций. Отдельный продукт от мобильного приложения investlink, общий API бэкенд.

- **Путь:** `/Users/investlinkm4/Develop/web_ai_analyzer/`
- **Стек:** Flutter web, Dio, flutter_bloc, fl_chart, flutter_markdown, google_fonts (Inter)
- **Запуск:** `flutter run -d chrome`
- **Билд:** `flutter build web`
- **Аналитика:** Amplitude (SDK + Session Replay + Autocapture)

---

## API

**Base URL (ngrok, временный):** `https://6df8-31-171-168-220.ngrok-free.app`

> Когда будет прод — заменить в `lib/main.dart` → `_baseUrl`

### Эндпоинты

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/analyze/{ticker}?mode={mode}` | Анализ одного тикера |
| POST | `/analyze/portfolio-builder` | Построение портфеля (amount + risk_strategy) |
| GET | `/modes` | Список режимов |
| POST | `/auth/register` | Регистрация пользователя |
| POST | `/auth/login` | Авторизация пользователя |

### Режимы (mode)

| mode | Описание |
|------|----------|
| `full` | Полный отчёт (все методологии) |
| `technical` | Технический анализ (Citadel) |
| `screener` | Скрининг акции (Goldman Sachs) |
| `risk` | Оценка рисков (Bridgewater) |
| `dcf` | DCF оценка (Morgan Stanley) |
| `earnings` | Анализ перед отчётностью (JPMorgan) |
| `portfolio` | Построение портфеля (BlackRock) |
| `dividends` | Дивидендный анализ (Гарвард) |
| `competitors` | Конкурентный анализ (Bain) |

### Ответ JSON (analyze)

```json
{
  "ticker": "AAPL",
  "mode": "full",
  "mode_description": "Полный инвестиционный отчёт",
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
  "trend": "Бычий",
  "score": 72,
  "analysis": "## Заголовок секции\nТекст анализа в markdown..."
}
```

### Ответ JSON (portfolio-builder)

```json
{
  "strategy": "moderate",
  "total_amount": 10000,
  "expected_return_min": 8.5,
  "expected_return_max": 12.3,
  "max_drawdown": -15.2,
  "rebalancing_frequency": "quarterly",
  "allocations": [
    {
      "ticker": "AAPL",
      "name": "Apple Inc.",
      "asset_class": "US Large Cap",
      "percentage": 20.0,
      "amount": 2000.0,
      "shares": 10.5,
      "price": 190.50
    }
  ],
  "analysis": "## Markdown анализ портфеля..."
}
```

### Заголовки

- `ngrok-skip-browser-warning: true` — **обязателен** для обхода ngrok interstitial
- `Authorization: Bearer <jwt_token>` — автоматически добавляется после login/register

---

## Структура проекта

```
lib/
├── main.dart                          # Entry point, единый Dio, BlocProviders (Analysis + Auth), ThemeNotifier
├── theme/
│   └── app_theme.dart                 # AppColors (light/dark), ThemeNotifier (isDark + locale), AppThemeScope
├── data/
│   ├── stock_analysis_dto.dart        # Модель ответа API (fromJson, signal, isBullish)
│   ├── analysis_repository.dart       # Dio: GET /analyze/{ticker}, POST /analyze/portfolio-builder
│   ├── analysis_cubit.dart            # AnalysisCubit + AnalysisState (idle/loading/loaded/error)
│   ├── auth_cubit.dart                # AuthCubit + AuthState (реальный API, JWT токен)
│   ├── user_plan.dart                 # UserPlan enum (free/pro/premium), PlanInfo, лимиты
│   ├── analytics_service.dart         # Amplitude трекинг (dart:js_interop обёртка)
│   └── portfolio_result_dto.dart      # PortfolioResultDto + PortfolioAllocation (fromJson)
├── l10n/
│   └── app_strings.dart               # Двуязычные строки (RU/EN), ModeInfo, HeroRotatingItem
└── presentation/
    ├── pages/
    │   ├── home_page.dart             # 3-step wizard: hero → режим → тикер → анализ
    │   ├── result_page.dart           # Результат: app bar, 3 карточки, AI секции, SWOT, шеринг
    │   ├── portfolio_page.dart        # AI Portfolio Builder (сумма → стратегия → портфель)
    │   ├── auth_page.dart             # Диалог авторизации (login/register)
    │   └── pricing_page.dart          # Страница тарифов (Free/Pro/Premium)
    └── widgets/
        ├── hero_section.dart          # Анимированный hero с ротацией текста
        ├── mode_chips.dart            # 3x3 сетка карточек режимов (responsive)
        ├── score_gauge.dart           # Полукруглый спидометр 0-100 (CustomPainter)
        ├── indicator_row.dart         # Строка индикатора (label — value)
        ├── ilm_logo.dart              # Анимированный логотип-парусник (CustomPainter)
        ├── how_it_works_section.dart  # Секция "Как это работает" — 3 шага
        └── analysis_skeleton.dart     # Skeleton loading для анализа
```

---

## Аналитика (Amplitude)

- **SDK:** подключён в `web/index.html` (CDN snippet с Session Replay + Autocapture)
- **API Key:** `be7957c558a52cf3ac704939f240eec1`
- **Dart обёртка:** `lib/data/analytics_service.dart` — синглтон через `dart:js_interop`

### Трекаемые события

| Событие | Описание |
|---------|----------|
| `mode_selected` | Выбор режима анализа |
| `ticker_entered` | Ввод тикера |
| `analysis_started` | Нажатие "Анализировать" |
| `analysis_completed` | Успешный анализ |
| `analysis_error` | Ошибка анализа |
| `analysis_shared` | Шеринг результата |
| `login` / `logout` | Авторизация |
| `pricing_viewed` | Просмотр тарифов |
| `theme_toggled` / `locale_toggled` | Настройки |
| `portfolio_opened` | Открытие Portfolio Builder |
| `portfolio_build_started` / `portfolio_build_completed` | Сборка портфеля |

Autocapture: page views, sessions, клики, формы, web vitals, rage clicks, dead clicks.

---

## Авторизация и тарифы

### AuthCubit (реальный API)

Интегрирован с бэкендом. JWT аутентификация.

- Единый `Dio` инстанс создаётся в `main.dart` и шарится между `AuthCubit` и `AnalysisCubit`
- После login/register токен сохраняется в `_token` и автоматически добавляется в заголовки Dio (`Authorization: Bearer`)
- Logout очищает токен из заголовков
- Ошибки маппятся по HTTP статусам: 404→accountNotFound, 401→wrongPassword, 409→emailTaken
- Состояния: `unauthenticated` → `loading` → `authenticated` / `error`

### Тарифные планы (UserPlan)

| План | Анализов/день | Доступные режимы |
|------|---------------|------------------|
| Free | 3 | все 9 (временно для теста, обычно только `technical`) |
| Pro | 30 | все 9 режимов |
| Premium | ∞ | все 9 режимов |

- Заблокированные режимы показывают badge "Pro" с замком
- Клик по заблокированному режиму → PricingPage
- Badge с остатком кредитов в верхнем левом углу

---

## Локализация

Двуязычный интерфейс RU/EN. Переключатель — кнопка в app bar.

- Все строки в `lib/l10n/app_strings.dart`
- Доступ: `AppThemeScope.of(context).strings`
- ThemeNotifier хранит `locale` (ru/en), метод `toggleLocale()`

---

## Тема

Переключатель light/dark — иконка sun/moon в app bar.

- **Тёмная:** чисто чёрный `#000000`, белый текст `#FFFFFF`
- **Светлая:** белая `#F7F7F8`, чёрный текст `#0A0A0A`

Архитектура:
- `ThemeNotifier` (ChangeNotifier) — хранит isDark, locale, toggle(), toggleLocale()
- `AppThemeScope` (InheritedWidget) — пробрасывает colors, strings, locale, onToggle, onToggleLocale
- `AppColors` — набор цветов (bg, surface, card, border, textPrimary, textSecondary, green, red, accent, yellow)

Доступ в виджетах:
```dart
final c = AppThemeScope.of(context).colors;
final s = AppThemeScope.of(context).strings;
final onToggle = AppThemeScope.of(context).onToggle;
```

---

## Страницы

### HomePage (3-step wizard с AnimatedSwitcher)
- **Step 0:** Hero секция с анимированным логотипом + ротация текста, 9 карточек режимов (responsive grid: 3/2/1 колонки)
- **Step 1:** Поле ввода тикера (крупный центрированный TextField)
- **Step 2:** Подтверждение — badges с выбранным режимом и тикером, кнопка "Анализировать"
- **Loading:** Skeleton loading — имитация ResultPage с shimmer-плейсхолдерами
- App bar: портфель, кредиты, авторизация, тарифы, переключатель языка, переключатель темы
- Логин запрашивается при выборе режима (до ввода тикера), после логина — автопродолжение
- История анализов (в памяти cubit, не персистентная)

### ResultPage
- **Sticky SliverAppBar:** тикер, цена, % изменения, тренд badge, score badge, кнопка шеринга, theme toggle
- **3 pricing-style карточки** (IntrinsicHeight + Row на desktop):
  - Обзор — скор, сигнал, тренд, цена
  - Индикаторы — RSI, SMA, MACD, Bollinger, ATR
  - AI Анализ — список фич
- **AI Анализ секции:** markdown парсится по `##`/`###` заголовкам → отдельные карточки с иконками (автоподбор по ключевым словам в заголовке)
- **SWOT:** 4 цветных блока (Strengths, Weaknesses, Opportunities, Threats)
- **Шеринг:** копирует компактную сводку в буфер обмена
- **Дисклеймер:** "Не является инвестиционной рекомендацией" внизу
- **Responsive:** `>960px` → 2 колонки, иначе вертикальный stack

### PortfolioPage (AI Portfolio Builder — реальный API)
- **Step 0:** Ввод суммы ($) + выбор стратегии (3 карточки: консервативная/умеренная/агрессивная)
- **Step 1:** Loading с прогресс баром
- **Step 2:** Результат — stat карточки (доходность/риск/drawdown), pie chart, таблица позиций (акции+ETF), AI-комментарий
- API: POST `/analyze/portfolio-builder` (amount + risk_strategy) → `PortfolioResultDto`
- Модель: `portfolio_result_dto.dart` — PortfolioResultDto + PortfolioAllocation
- Точка входа: кнопка "Собрать портфель" в app bar на главной

### AuthPage (диалог)
- Переключение Login/Register
- Поля email + password
- Показ ошибок, закрытие при успехе

### PricingPage
- 3 карточки тарифов (Free / Pro / Premium) с фичами
- Показывает текущий план
- Responsive grid

---

## SEO

- **Title:** "ILM — AI-анализ акций | Citadel · Bridgewater · BlackRock"
- **Open Graph:** og:title, og:description, og:image — превью для Telegram/WhatsApp/Facebook
- **Twitter Card:** summary_large_image
- **Meta:** description, keywords, theme-color, viewport
- **TODO:** og:image баннер 1200x630, og:url когда будет домен, sitemap, robots.txt

---

## Dio архитектура

Единый `Dio` инстанс в `main.dart`:
- `baseUrl`: `_baseUrl` (ngrok → прод)
- `connectTimeout: 30s`, `receiveTimeout: 60s`
- `ngrok-skip-browser-warning: true` — дефолтный заголовок
- Шарится между `AuthCubit` и `AnalysisCubit` через constructor injection
- `AuthCubit` добавляет `Authorization: Bearer` заголовок после login/register
- `_dio.close()` в `dispose()` виджета

---

## Документация проекта

| Файл | Описание |
|------|----------|
| `API.md` | Полная API-справка (эндпоинты, ошибки, авторизация) |
| `BACKEND_SPEC.md` | Спецификация бэкенда для разработчиков |
| `11_portfolio_blackrock.md` | Методология Portfolio Builder (BlackRock, акции+ETF) |

---

## Связь с мобильным приложением

Мобильный модуль `invl_ai_analyze` в `investlink-mobile-app/modules/invl_ai_analyze/` использует тот же API.

Отличия мобилки:
- Есть "Анализ моего портфеля" (POST /analyze/PORTFOLIO с позициями из UserPositionCubit)
- Hive для персистентной истории анализов
- Детальный экран с табами (Обзор/Индикаторы/AI/SWOT)
- UI через дизайн-систему investlink (AppColorScheme, AppTextScheme)

Стратегия: ILM web — отдельный продукт + лид-генератор для мобилки investlink.

---

## Conventions

- Шрифт: **Inter** (Google Fonts)
- Цвета: всегда через `AppThemeScope.of(context).colors` — никогда хардкод
- Строки: всегда через `AppThemeScope.of(context).strings` — для двуязычности
- Стиль: чёрно-белый минимализм (kapitalist.finance), без цветных акцентов в UI элементах
- Описания режимов: фокус на ценность для клиента ("что получишь"), не на технические термины
- UI тексты двуязычные (RU/EN)
- Responsive breakpoint: 960px
- Авторизация: реальный API с JWT (заменён mock)
- Дефолтный режим анализа: `full` (если не выбран)
- Flutter version: 3.35.3 (`.fvmrc`)
