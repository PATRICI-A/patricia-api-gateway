# API Gateway — PATRICIA

Kong DB-less como punto de entrada único para todos los microservicios de PATRICIA. Valida JWT antes de que las peticiones lleguen a los servicios.

## Tecnologías

- Kong 3.7 (DB-less, declarative config)
- Docker Compose
- JWT Plugin (HMAC-SHA256)

## Arquitectura

```
Frontend → Kong :8000 → microservicio
                ↓
         valida JWT (iss, exp)
         si inválido → 401 sin tocar el servicio
```

Los microservicios confían en que si la petición llegó, el token ya fue validado por Kong. Solo necesitan leer el `sub` (userId) del token.

## Rutas configuradas

| Ruta | Servicio | JWT |
|------|----------|-----|
| `/api/v1/auth/**` | auth-service:9090 | No (aquí se obtiene el token) |
| `/api/v1/users/**` | matchpuff-profile-service:8081 | Sí |
| `/api/v1/profiles/**` | matchpuff-profile-service:8081 | Sí |

## Plugins globales

- **jwt** — valida token en todas las rutas excepto auth
- **cors** — permite todos los orígenes (restringir en producción)
- **rate-limiting** — 100 req/min por IP
- **request-size-limiting** — máximo 5 MB por request

## Variables de entorno requeridas

```env
JWT_SECRET=<mismo secret que auth-service>
AUTH_SERVICE_IMAGE=<imagen ECR del auth-service>
PROFILE_SERVICE_IMAGE=<imagen ECR del profile-service>
REDIS_PASSWORD=<password de Redis>
MONGO_URI=<connection string MongoDB Atlas>
RABBITMQ_HOST=<host de RabbitMQ>
RABBITMQ_PORT=5672
RABBITMQ_USERNAME=guest
RABBITMQ_PASSWORD=guest
JWT_EXPIRATION=900000
```

## Levantar localmente

```bash
# Producción (sin puertos expuestos directamente)
docker compose --env-file .env up -d

# Desarrollo (puertos de servicios expuestos + Admin API de Kong)
docker compose -f docker-compose.yml -f docker-compose.dev.yml --env-file .env up -d
```

En desarrollo Kong Admin API queda disponible en `http://localhost:8001`.

## Agregar un nuevo microservicio

1. Agregar el servicio en `docker-compose.yml` con su imagen y variables
2. Agregar la ruta en `kong/kong.yml` bajo `services`
3. Reiniciar Kong: `docker compose restart kong`
