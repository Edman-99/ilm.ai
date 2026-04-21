# TODO — Web AI Analyzer

## Деплой фронтенда (приоритет 1)

- [ ] Получить доступ к серверу `109.235.119.153` (Hoster.KZ)
  - Вариант A: Зайти через тот компьютер где есть SSH ключ → добавить новый ключ
  - Вариант B: Через панель Hoster.KZ → VNC Console → добавить ключ вручную
  - Добавить ключ на сервер:
    ```bash
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAu4C/TFfoSpInnENInDUqghVEQ6xuQe+zpAumWR30Tp edman.a@investlink.io" >> /root/.ssh/authorized_keys
    ```

- [ ] Задеплоить фронтенд на сервер
  ```bash
  # Собрать (уже собран, но можно пересобрать)
  flutter build web --release

  # Загрузить на сервер
  rsync -avz --delete build/web/ root@109.235.119.153:/tmp/frontend_new/ -e "ssh -p 2222"

  # На сервере — переложить в nginx
  ssh -p 2222 root@109.235.119.153 "cp -r /tmp/frontend_new/* /root/trading-back/frontend/"
  ```

---

## Тестирование после деплоя

- [ ] Проверить что сайт открывается
- [ ] Войти в Trading Analytics → убедиться что AI Insights и Journal убраны из сайдбара
- [ ] Создать стратегию через UI → проверить что сохраняется в БД
- [ ] Редактировать / удалить стратегию
- [ ] Проверить что demo режим работает корректно

---

## Бэкенд (уже сделано ✅)

- [x] Новая модель `Strategy` + `StrategyPosition` (PostgreSQL)
- [x] CRUD API `/trading/strategies` (FastAPI)
- [x] Auth через `X-User-Email` header
- [x] Docker деплой на сервер

---

## Фронтенд (уже сделано ✅)

- [x] Убраны AI Insights и Journal из сайдбара
- [x] Новый `StrategyEntity` с `entries` (symbol + qty)
- [x] CRUD стратегий через UI (создать / редактировать / удалить)
- [x] Карточки стратегий с девиацией, статистикой, заметками
- [x] `TradingRepository` — методы для стратегий API
- [x] `TradingAnalyticsCubit` — логика стратегий
- [x] Demo данные обновлены под новую структуру

---

## Возможные улучшения (следующая итерация)

- [ ] Target allocation % — показывать pie chart по стратегиям
- [ ] Привязка сделок к стратегии (тегирование ордеров)
- [ ] Performance per strategy — P&L по каждой стратегии
- [ ] Rebalancing suggestions — подсказки когда отклонение > порог
