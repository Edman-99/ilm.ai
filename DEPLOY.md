# Деплой и обслуживание ILM Analytics

## Сервер

| | |
|---|---|
| IP | `109.235.119.153` |
| SSH | `ssh root@109.235.119.153` |
| Проект | `/root/trading-back/` |

---

## Домены

| Домен | Назначение |
|---|---|
| `https://ilm-analytics.com` | Flutter web frontend |
| `https://api.ilm-analytics.com` | FastAPI backend |
| `https://api.ilm-analytics.com/docs` | Swagger документация |

---

## Стек

```
nginx (443/80)
├── ilm-analytics.com      → /var/www/frontend (Docker volume: trading-back_frontend_dist)
└── api.ilm-analytics.com  → app:8000 (FastAPI + uvicorn)

Docker Compose (в /root/trading-back/):
├── nginx    — реверс-прокси + раздача статики
├── app      — FastAPI приложение
├── postgres — база данных
└── certbot  — SSL сертификаты (Let's Encrypt)
```

---

## Деплой фронтенда (Flutter)

### На локальной машине:

```bash
# 1. Собрать
cd /Users/investlinkm4/Develop/web_ai_analyzer
flutter build web --release

# 2. Скопировать на сервер
rsync -avz --delete build/web/ root@109.235.119.153:/tmp/frontend_dist/
```

### На сервере:

```bash
ssh root@109.235.119.153

# Скопировать файлы в Docker volume
docker run --rm \
  -v /tmp/frontend_dist:/src:ro \
  -v trading-back_frontend_dist:/dst \
  alpine sh -c "cp -r /src/. /dst/"

# Перезагрузить nginx (чтобы подхватил новые файлы)
docker compose -f /root/trading-back/docker-compose.yml exec nginx nginx -s reload
```

### Одной командой (с локальной машины):

```bash
cd /Users/investlinkm4/Develop/web_ai_analyzer && \
flutter build web --release && \
rsync -avz --delete build/web/ root@109.235.119.153:/tmp/frontend_dist/ && \
ssh root@109.235.119.153 '
  docker run --rm \
    -v /tmp/frontend_dist:/src:ro \
    -v trading-back_frontend_dist:/dst \
    alpine sh -c "cp -r /src/. /dst/" && \
  docker compose -f /root/trading-back/docker-compose.yml exec nginx nginx -s reload
'
```

---

## Деплой бэкенда (FastAPI)

```bash
# 1. Скопировать изменения на сервер
rsync -avz --exclude '__pycache__' --exclude '*.pyc' \
  /Users/investlinkm4/Develop/web_ai_analyzer/backend/ \
  root@109.235.119.153:/root/trading-back/

# 2. На сервере — пересобрать и перезапустить
ssh root@109.235.119.153
cd /root/trading-back
docker compose build app
docker compose up -d app
```

---

## Перезапуск сервисов

```bash
ssh root@109.235.119.153
cd /root/trading-back

# Перезапустить всё
docker compose restart

# Перезапустить конкретный сервис
docker compose restart app
docker compose restart nginx
docker compose restart postgres

# Полная пересборка (если менялся Dockerfile или requirements.txt)
docker compose down
docker compose build
docker compose up -d
```

---

## Просмотр логов

```bash
ssh root@109.235.119.153
cd /root/trading-back

# Все логи
docker compose logs -f

# Логи конкретного сервиса
docker compose logs -f app
docker compose logs -f nginx
docker compose logs -f postgres

# Последние 100 строк
docker compose logs --tail=100 app
```

---

## Статус контейнеров

```bash
ssh root@109.235.119.153
cd /root/trading-back

docker compose ps
```

Ожидаемый вывод — все `running (healthy)`:
```
NAME                    STATUS
trading-back-nginx-1    running
trading-back-app-1      running (healthy)
trading-back-postgres-1 running (healthy)
trading-back-certbot-1  running
```

---

## SSL сертификаты

Certbot обновляет автоматически каждые 12 часов. Nginx перезагружается каждые 24 часа для подхвата новых сертификатов.

```bash
# Проверить срок действия
ssh root@109.235.119.153
docker compose -f /root/trading-back/docker-compose.yml exec certbot \
  certbot certificates

# Принудительно обновить
docker compose -f /root/trading-back/docker-compose.yml exec certbot \
  certbot renew --force-renewal
```

---

## Переменные окружения

Файл `/root/trading-back/.env` на сервере:

```env
CLAUDE_API_KEY=...
FMP_API_KEY=...
JWT_SECRET_KEY=...
AUTH_BACKEND_URL=https://app12-us-sw.ivlk.io
BOT_JWT_SECRET=...
ALPACA_SANDBOX=true
```

Изменить:
```bash
ssh root@109.235.119.153
nano /root/trading-back/.env
cd /root/trading-back && docker compose up -d app  # перезапустить app для применения
```

---

## Смена API URL во фронтенде

Файл [lib/main.dart](lib/main.dart) — переменная `_baseUrl`:

```dart
static const String _baseUrl = 'https://api.ilm-analytics.com';
```

После изменения — пересобрать и задеплоить фронтенд (см. раздел выше).

---

## База данных

```bash
ssh root@109.235.119.153

# Подключиться к postgres
docker compose -f /root/trading-back/docker-compose.yml exec postgres \
  psql -U trading -d trading

# Бэкап
docker compose -f /root/trading-back/docker-compose.yml exec postgres \
  pg_dump -U trading trading > backup_$(date +%Y%m%d).sql

# Восстановление из бэкапа
cat backup_20260412.sql | docker compose -f /root/trading-back/docker-compose.yml exec -T postgres \
  psql -U trading trading
```

---

## Диагностика проблем

### Сайт не открывается
```bash
# Проверить DNS
dig +short ilm-analytics.com
dig +short api.ilm-analytics.com
# Должно быть: 109.235.119.153

# Проверить контейнеры
ssh root@109.235.119.153
docker compose -f /root/trading-back/docker-compose.yml ps
```

### 502 Bad Gateway
```bash
# Скорее всего упал app
ssh root@109.235.119.153
cd /root/trading-back
docker compose logs --tail=50 app
docker compose restart app
```

### Фронтенд не обновился
```bash
# Проверить что файлы скопировались в volume
ssh root@109.235.119.153
docker run --rm -v trading-back_frontend_dist:/data alpine ls /data
```

### SSL ошибка
```bash
ssh root@109.235.119.153
cd /root/trading-back
docker compose logs --tail=50 certbot
docker compose logs --tail=50 nginx
```
