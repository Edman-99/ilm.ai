#!/bin/bash
set -e

SERVER="webadmin@109.235.119.153"
PORT="2222"
REMOTE_DIR="~/trading-back"

echo "🚀 Деплой на $SERVER..."

# Синхронизируем файлы (без .env и __pycache__)
rsync -avz --progress \
  -e "ssh -p $PORT" \
  --exclude='.env' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='.git' \
  --exclude='trading.db' \
  --exclude='venv' \
  backend/ \
  $SERVER:$REMOTE_DIR/

echo "📦 Пересобираем и перезапускаем..."
ssh -p $PORT $SERVER "cd $REMOTE_DIR && docker compose down app && docker compose build app && docker compose up -d"

echo "⏳ Ждём старт..."
sleep 10

echo "✅ Статус:"
ssh -p $PORT $SERVER "cd $REMOTE_DIR && docker compose ps && curl -s http://localhost:8000/health"
