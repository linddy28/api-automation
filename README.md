# API Automation — GoRest Users (Karate)

Automatización de las APIs de usuarios de [GoRest](https://gorest.co.in/) usando el
framework **Karate**. Cubre los 4 endpoints requeridos (List, Create, Update, Delete)
con validación de status code y aserciones sobre el cuerpo de la respuesta.

## Stack

| Herramienta    | Uso                                  |
| -------------- | ------------------------------------ |
| Java 11+       | Runtime                              |
| Maven          | Gestión de dependencias y build      |
| Karate 1.4.1   | Framework de automatización de APIs  |
| JUnit 5        | Runner de pruebas                    |
| GitHub Actions | Pipeline CI/CD                       |

## Estructura del proyecto

```
api-automation/
├── pom.xml                                   # Configuración Maven + dependencias
├── .github/workflows/api-tests.yml           # Pipeline CI (GitHub Actions)
└── src/test/java/
    ├── karate-config.js                      # Config global (baseUrl, token, timeouts)
    ├── logback-test.xml                       # Configuración de logs
    └── com/bancosol/
        ├── UsersRunner.java                  # Runner JUnit 5
        └── users.feature                     # Feature con los 4 escenarios
```

## Endpoints automatizados

Base URL: `https://gorest.co.in/public/v2`

| Escenario   | Método | Path             | Status esperado |
| ----------- | ------ | ---------------- | --------------- |
| List users  | GET    | `/users`         | 200             |
| Create user | POST   | `/users`         | 201             |
| Update user | PATCH  | `/users/{id}`    | 200             |
| Delete user | DELETE | `/users/{id}`    | 204 (+ 404 GET) |

Cada escenario incluye **el status code esperado más al menos un assert adicional**
sobre el cuerpo de la respuesta.

> Notas de diseño:
> - Los escenarios de Update y Delete **crean su propio usuario** primero para
>   obtener un `id` dinámico, en lugar de depender de un id fijo (como `6940344`
>   del enunciado, que puede no existir). Así las pruebas son deterministas y
>   repetibles.
> - Las cabeceras (incluido el `Authorization: Bearer`) se definen con
>   `configure headers` en `karate-config.js`. En Karate, una cabecera puesta con
>   `header ...` solo aplica a la **siguiente** petición; GoRest responde `404` a
>   peticiones sin token sobre un id concreto, por lo que persistir la cabecera es
>   necesario para que GET/PATCH/DELETE funcionen dentro del mismo escenario.

## Requisitos previos

- Java JDK 8 o superior (probado con 11/17)
- Maven configurado ([guía](https://www.baeldung.com/install-maven-on-windows-linux-mac))
- Git

## Autenticación (Bearer token)

El token se lee, en orden de prioridad:

1. Propiedad de sistema `-Dgorest.token=...`
2. Variable de entorno `GOREST_TOKEN`
3. Valor por defecto incluido en `karate-config.js` (el token del enunciado)

En CI se recomienda usar el secret `GOREST_TOKEN` en lugar de dejarlo en el código.

## Ejecutar las pruebas

```bash
cd api-automation

# Todos los escenarios
mvn test

# Con un token propio
mvn test -Dgorest.token=TU_TOKEN

# Un solo tag (ejemplo: solo Create)
mvn test -Dkarate.options="--tags @create"
```

### Tags disponibles

`@list`, `@create`, `@update`, `@delete`

## Reportes

Tras ejecutar, Karate genera reportes HTML en:

```
target/karate-reports/karate-summary.html
```

## CI/CD

El pipeline en `.github/workflows/api-tests.yml` instala JDK 17, cachea las
dependencias Maven y ejecuta `mvn -B test` en cada push y pull request a
`main`/`master`. Los reportes de Karate se publican como artefactos del build.
Configura el secret `GOREST_TOKEN` en el repositorio (Settings → Secrets and
variables → Actions) para no exponer el token.
