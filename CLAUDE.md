# CLAUDE.md — AI Stock Analyzer (Web)

## Обзор

Flutter web проект для AI анализа акций. Отдельный от мобильного приложения investlink, общий API бэкенд.

- **Путь:** `/Users/investlinkm4/Develop/web_ai_analyzer/`
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

### Ответ JSON

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
├── main.dart                          # Entry point, BlocProvider, ThemeNotifier
├── theme/
│   └── app_theme.dart                 # AppColors (light/dark), ThemeNotifier, AppThemeScope
├── data/
│   ├── stock_analysis_dto.dart        # Модель ответа API (fromJson, signal, isBullish)
│   ├── analysis_repository.dart       # Dio GET /analyze/{ticker}
│   └── analysis_cubit.dart            # AnalysisCubit + AnalysisState (idle/loading/loaded/error)
└── presentation/
    ├── pages/
    │   ├── home_page.dart             # Главная: поиск, чипсы режимов, история
    │   └── result_page.dart           # Результат: app bar, 3 карточки, AI секции, SWOT
    └── widgets/
        ├── mode_chips.dart            # Wrap чипсов (9 режимов)
        ├── score_gauge.dart           # Полукруглый спидометр 0-100 (CustomPainter)
        └── indicator_row.dart         # Строка индикатора (label — value)
```

---

## Тема

Переключатель light/dark — иконка sun/moon в app bar.

- **Тёмная:** чисто чёрный `#000000`, белый текст `#FFFFFF`
- **Светлая:** белая `#F7F7F8`, чёрный текст `#0A0A0A`

Архитектура:
- `ThemeNotifier` (ChangeNotifier) — хранит isDark, toggle()
- `AppThemeScope` (InheritedWidget) — пробрасывает colors + onToggle
- `AppColors` — набор цветов (bg, surface, card, border, textPrimary, textSecondary, green, red, accent, yellow)

Доступ в виджетах:
```dart
final c = AppThemeScope.of(context).colors;
final onToggle = AppThemeScope.of(context).onToggle;
```

---

## Страницы

### HomePage
- Hero текст "Анализ акций с помощью AI"
- TextField для тикера (автокапитализация)
- ModeChips (Wrap) — 9 режимов анализа
- Кнопка "Анализировать"
- BlocListener → Navigator.push на ResultPage после загрузки
- История анализов (в памяти cubit, не персистентная)
- Зелёная Live точка в app bar

### ResultPage
- **Sticky SliverAppBar:** тикер, цена, % изменения, тренд badge, score badge (72 ПОКУПКА), theme toggle
- **3 pricing-style карточки** (IntrinsicHeight + Row на desktop):
  - Обзор — скор, сигнал, тренд, цена
  - Индикаторы — RSI, SMA, MACD, Bollinger, ATR
  - AI Анализ — список фич
- **AI Анализ секции:** markdown парсится по `##`/`###` заголовкам → отдельные карточки с иконками (автоподбор по ключевым словам в заголовке)
- **SWOT:** 4 цветных блока (Strengths, Weaknesses, Opportunities, Threats)
- **Responsive:** `>960px` → 2 колонки, иначе вертикальный stack

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
- Стиль вдохновлён: kapitalist.finance (минимализм, карточки с бордерами)
- UI тексты на русском
- Responsive breakpoint: 960px
