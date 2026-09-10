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
make api                # API и необходимые инфраструктурные зависимости
make app                # API, worker, frontend assets и Nginx
make frontend           # пересобрать React assets и запустить Nginx
make frontend-dev       # API в Docker + Vite/hot reload на хосте
make smoke-overtone     # изолированный smoke: React → Nginx → mock API
make logs               # логи всех сервисов
make logs SERVICE=worker
make ps
make down
make purge              # удалить контейнеры и образы, сохранив volumes
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
старыми именами `backend_*`. Команды `make down` и `make purge` данные не
удаляют: `purge` удаляет контейнеры, сеть и связанные образы, но сохраняет
volumes.

## Frontend и Nginx

React-приложение собирается внутри Docker сервисом `frontend-assets`. Это
одноразовый контейнер: он копирует новые hashed assets в named volume
`frontend_dist`, атомарно заменяет `index.html` и успешно завершается. Старые
hashed assets удаляются через 7 дней, поэтому уже открытая вкладка не получает
404 во время обновления. Постоянный сервис `nginx`
монтирует этот volume только для чтения, раздаёт SPA и проксирует `/api/*` в
`api:3000`.

Nginx не входит во frontend-модуль. Его локальная infrastructure-конфигурация
находится в `nginx/nginx.conf`; позднее её можно перенести в отдельный infra
репозиторий. TLS и доменная маршрутизация в локальном стеке не настраиваются.

Для production-like проверки:

```sh
make frontend
curl http://localhost:${FRONTEND_PORT:-8080}/nginx-health
curl http://localhost:${FRONTEND_PORT:-8080}/api/health
```

Полный smoke-тест поднимает отдельный Compose-проект `overtone-smoke` на
портах `18080/18081`, проверяет SPA fallback, cache headers, проксирование API
и несколько циклов polling до готового отчёта, затем удаляет только свои
контейнеры и временный volume:

```sh
make smoke-overtone
```

Для принудительного обновления assets в составе всего стека используйте
`make up REBUILD=1` или `make up-gpu REBUILD=1`. Старые hashed assets удаляются
после семидневного окна совместимости.

## Режим разработки

Для React-разработки с hot reload нужен установленный Node.js. Команда ниже
поднимает API с его Compose-зависимостями, затем запускает Vite на порту 5173:

```sh
make frontend-dev
```

Vite проксирует `/api` на `http://127.0.0.1:3000`. Параметры можно изменить в
`../overtone/frontend/.env.development`, взяв за основу
`.env.development.example`. Production routing этим файлом не настраивается.

## Release-образы

`api`/`worker` и `frontend-assets` имеют независимые image references и не
обязаны иметь одинаковый git SHA:

```dotenv
OVERTONE_BACKEND_IMAGE=registry/overtone-backend:<git-sha>
OVERTONE_FRONTEND_IMAGE=registry/overtone-frontend-assets:<git-sha>
```

OCI label `org.opencontainers.image.revision` используется только для проверки,
что immutable tag содержит ожидаемую сборку. API-совместимость проверяется в
runtime через request/response header `X-Overtone-API-Version`, а не через
Docker metadata.

Для ручного развёртывания укажите только изменившийся компонент:

```sh
make deploy-overtone COMPONENT=frontend \
  IMAGE=registry/overtone-frontend-assets:<frontend-git-sha>

make deploy-overtone COMPONENT=backend \
  IMAGE=registry/overtone-backend:<backend-git-sha>
```

Backend deployment перезапускает только `api`/`worker`, затем делает reload
уже работающего Nginx, чтобы он заново разрешил Docker DNS имени `api`.
Frontend и Nginx-контейнер при этом не пересоздаются.

Перед первой такой выкладкой обновите сам `overtone-local-stack` на сервере:
release-команда ожидает image-переменные, атомарный `frontend-assets` и новый
Nginx readiness-check из этого репозитория.
