# Local stack

Локальный Docker Compose для Overtone и medical-scribe. Каталоги `overtone`,
`medical-scribe` и `local-stack` должны лежать рядом.

## Первый запуск

```sh
cp .env.example .env
make up
```

Основные команды:

```sh
make up                 # весь стек с mock inference
make up-gpu             # весь стек с GPU inference
make infra              # только PostgreSQL, Redis и MinIO
make app                # API, frontend и worker
make logs               # логи всех сервисов
make logs SERVICE=worker
make ps
make down
```

По умолчанию `make up` использует существующие образы. Для пересборки:

```sh
make up REBUILD=1
make up-gpu REBUILD=1
make up REBUILD=1 BUILD_FLAGS="--no-cache --pull"
make up REBUILD=1 BUILD_SERVICES="api worker"
```

`BUILD_SERVICES` ограничивает только пересборку; после неё запускается весь стек.
Чтобы ограничить и запуск, используйте `UP_SERVICES="api worker"`.

Дополнительные опции `docker compose up` передаются через `UP_FLAGS`:

```sh
make up UP_FLAGS="-d --wait"
```

Проверка конфигурации без запуска контейнеров:

```sh
make config
make config PROFILE=gpu
```

Mock и GPU inference взаимоисключающие. `make up` и `make up-gpu` автоматически
останавливают контейнер другого режима. Существующие volumes сохранены под
старыми именами `backend_*`. Команда `make down` данные не удаляет.
