# CLAUDE.md — AI Stock Analyzer (Web)

## Обзор

Flutter web проект для AI анализа акций. Отдельный от мобильного приложения investlink, общий API бэкенд.

- **Путь:** `/Users/lemon/ai-web/`
- **Стек:** Flutter web, Dio, flutter_bloc, fl_chart, flutter_markdown, google_fonts (Inter)
- **Запуск:** `flutter run -d chrome`
- **Билд:** `flutter build web`

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
│   └── user_plan.dart                 # UserPlan enum (free/pro/premium), PlanInfo, лимиты
├── l10n/
│   └── app_strings.dart               # Двуязычные строки (RU/EN), ModeInfo, HeroRotatingItem
└── presentation/
    ├── pages/
    │   ├── home_page.dart             # 3-step wizard: hero → режим → тикер → анализ
    │   ├── result_page.dart           # Результат: app bar, 3 карточки, AI секции, SWOT
    │   ├── auth_page.dart             # Диалог авторизации (login/register)
    │   └── pricing_page.dart          # Страница тарифов (Free/Pro/Premium)
    └── widgets/
        ├── hero_section.dart          # Анимированный hero с ротацией текста
        ├── mode_chips.dart            # 3x3 сетка карточек режимов (responsive)
        ├── score_gauge.dart           # Полукруглый спидометр 0-100 (CustomPainter)
        ├── indicator_row.dart         # Строка индикатора (label — value)
        ├── ilm_logo.dart              # Анимированный логотип-парусник (CustomPainter)
        └── how_it_works_section.dart  # Секция "Как это работает" — 3 шага
```

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
| Free | 3 | только `technical` |
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
- App bar: кредиты, авторизация, тарифы, переключатель языка, переключатель темы
- История анализов (в памяти cubit, не персистентная)

### ResultPage
- **Sticky SliverAppBar:** тикер, цена, % изменения, тренд badge, score badge, theme toggle
- **3 pricing-style карточки** (IntrinsicHeight + Row на desktop):
  - Обзор — скор, сигнал, тренд, цена
  - Индикаторы — RSI, SMA, MACD, Bollinger, ATR
  - AI Анализ — список фич
- **AI Анализ секции:** markdown парсится по `##`/`###` заголовкам → отдельные карточки с иконками (автоподбор по ключевым словам в заголовке)
- **SWOT:** 4 цветных блока (Strengths, Weaknesses, Opportunities, Threats)
- **Responsive:** `>960px` → 2 колонки, иначе вертикальный stack

### AuthPage (диалог)
- Переключение Login/Register
- Поля email + password
- Показ ошибок, закрытие при успехе

### PricingPage
- 3 карточки тарифов (Free / Pro / Premium) с фичами
- Показывает текущий план
- Responsive grid

---

## Связь с мобильным приложением

Мобильный модуль `invl_ai_analyze` в `investlink-mobile-app/modules/invl_ai_analyze/` использует тот же API.

Отличия мобилки:
- Есть "Анализ моего портфеля" (POST /analyze/PORTFOLIO с позициями из UserPositionCubit)
- Hive для персистентной истории анализов
- Детальный экран с табами (Обзор/Индикаторы/AI/SWOT)
- UI через дизайн-систему investlink (AppColorScheme, AppTextScheme)

---

## Conventions

- Шрифт: **Inter** (Google Fonts)
- Цвета: всегда через `AppThemeScope.of(context).colors` — никогда хардкод
- Строки: всегда через `AppThemeScope.of(context).strings` — для двуязычности
- Стиль вдохновлён: kapitalist.finance (минимализм, карточки с бордерами)
- UI тексты двуязычные (RU/EN)
- Responsive breakpoint: 960px
- Авторизация пока mock — при интеграции заменить `auth_cubit.dart`
