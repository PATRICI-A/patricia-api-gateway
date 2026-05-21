# API Gateway — PATRICIA

Kong DB-less como punto de entrada único para todos los microservicios de PATRICIA.
Valida JWT en el edge — los backends confían en Kong y no revalidan.

## Tecnologías

- Kong 3.7 (DB-less, declarative config)
- Docker & Docker Compose
- JWT Plugin (HMAC-SHA256) — configuración centralizada con YAML anchors

## Arquitectura

```
Frontend → Kong :8080 → microservicio
                ↓
         valida JWT (iss, exp, role)
         si inválido → 401 sin tocar el servicio
```

**Auth centralizado:** Kong valida el JWT una vez en el edge. Los microservicios
confían en que si la petición llegó, el token ya es válido.

**gamification-service** es el primer piloto de auth centralizado: eliminó su
validación HMAC interna y solo parsea el payload del JWT (sin verificar firma)
para extraer `sub` y `role`. Kong se encarga de la verificación criptográfica.

## Rutas configuradas

| Ruta | Servicio | JWT |
|------|----------|-----|
| `/api/v1/auth/**` | auth-service | No |
| `/api/v1/users/**` | profile-service | Sí |
| `/api/v1/profiles/**` | profile-service | Sí |
| `/api/v1/internal/**` | profile-service | Sí |
| `/api/v1/parches/**` | hangout-service | Sí |
| `/api/v1/invitaciones/**` | hangout-service | Sí |
| `/api/parches/**` | chat-service | Sí |
| `/api/connections/**` | chat-service | Sí |
| `/api/notifications/**` | notification-service | Sí |
| `/api/event-reminders/**` | notification-service | Sí |
| `/api/v1/gamificacion/**` | gamification-service | Sí (centralizado) |
| `/api/v1/rewards/**` | gamification-service | Sí (centralizado) |
| `/api/v1/feed/**` | feed-search-service | Sí |
| `/api/v1/matches/**` | social-matching | Sí |
| `/api/v1/categories/**` | social-matching | Sí |
| `/api/v1/geo/**` | geo-service | Sí |
| `/api/v1/events/**` | campus-events | Sí |
| `/api/analytics/**` | statistics | Sí |
| `/api/v1/analytics/**` | statistics | Sí |
| `/api/v1/support/**` | support-service | Sí |

## Plugins

**Globales (aplican a todas las rutas):**

- **cors** — permite todos los orígenes
- **rate-limiting** — 100 req/min por IP
- **request-size-limiting** — máximo 5 MB por request

**Per-service (vía YAML anchor `&jwt-plugin`):**

El plugin JWT se declara una sola vez como ancla YAML y se reusa en cada
servicio con `<<: *jwt-plugin`. El único servicio sin JWT es `auth-service`.

```yaml
_jwt-plugin: &jwt-plugin
  plugins:
    - name: jwt

services:
  - name: auth-service
    url: ${URL_AUTH}
    # Sin JWT — es el emisor de tokens

  - name: gamification-service
    url: ${URL_GAMIFICATION}
    <<: *jwt-plugin   # Hereda el plugin JWT
```

## Variables de entorno requeridas

```env
JWT_SECRET=<mismo secret que auth-service>
URL_AUTH=http://patricia-auth-service-prod:80
URL_PROFILE=http://patricia-profile-service-prod:80
URL_HANGOUT=http://patricia-hangout-service-prod:80
URL_CHAT=http://patricia-chat-service-prod:80
URL_NOTIFICATION=http://patricia-notificati-service-prod:80
URL_GAMIFICATION=http://patricia-gamificati-service-prod:80
URL_FEED_SEARCH=http://patricia-feedsearch-service-prod:80
URL_MATCHING=http://patricia-social-matching-prod:80
URL_GEO=http://patricia-geo-service-prod:80
URL_EVENTS=http://patricia-campus-events-prod:80
URL_ANALYTICS=http://patricia-stati-analytics-prod:80
URL_SUPPORT=http://patricia-suport-service-prod:80
```

Las URLs usan el nombre corto interno + puerto 80 (ingress de Container Apps).
En local se reemplazan por `http://localhost:<puerto>`.

## Levantar localmente

```bash
docker compose --env-file .env up -d
```

## Build de la imagen

```bash
docker build -t ghcr.io/patrici-a/patricia-api-gateway:latest .
```

## Agregar un nuevo microservicio

1. Agregar la URL en `.env.example` y en el `environment` de `docker-compose.yml`
2. Agregar un bloque en `services` dentro de `kong.yml` con `${VAR}` y `<<: *jwt-plugin`
3. Rebuildear la imagen: `docker build -t ghcr.io/patrici-a/patricia-api-gateway:latest .`
