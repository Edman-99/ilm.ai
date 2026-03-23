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

### Заголовки

- `ngrok-skip-browser-warning: true` — **обязателен** для обхода ngrok interstitial

---

## Структура проекта

```
lib/
├── main.dart                          # Entry point, BlocProviders (Analysis + Auth), ThemeNotifier
├── theme/
│   └── app_theme.dart                 # AppColors (light/dark), ThemeNotifier (isDark + locale), AppThemeScope
├── data/
│   ├── stock_analysis_dto.dart        # Модель ответа API (fromJson, signal, isBullish)
│   ├── analysis_repository.dart       # Dio GET /analyze/{ticker}
│   ├── analysis_cubit.dart            # AnalysisCubit + AnalysisState (idle/loading/loaded/error)
│   ├── auth_cubit.dart                # AuthCubit + AuthState (mock авторизация)
│   ├── user_plan.dart                 # UserPlan enum (free/pro/premium), PlanInfo, лимиты
│   ├── analytics_service.dart         # Amplitude трекинг (dart:js_interop обёртка)
│   └── portfolio_mock.dart            # Mock данные для Portfolio Builder (3 стратегии)
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

### AuthCubit (mock, готов к интеграции с бэкендом)

Состояния: `unauthenticated` → `loading` → `authenticated` / `error`

Тестовые пользователи:
- `free@test.com:123` → Free план
- `pro@test.com:123` → Pro план
- `premium@test.com:123` → Premium план

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

### PortfolioPage (AI Portfolio Builder — mock)
- **Step 0:** Ввод суммы ($) + выбор стратегии (3 карточки: консервативная/умеренная/агрессивная)
- **Step 1:** Loading с прогресс баром
- **Step 2:** Результат — 3 stat карточки (доходность/риск/Sharpe), pie chart, таблица позиций, AI-комментарий
- Mock данные: 3 реалистичных портфеля (6-7 ETF), готовы к замене на реальный API
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
- Авторизация пока mock — при интеграции заменить `auth_cubit.dart`
- Дефолтный режим анализа: `full` (если не выбран)
