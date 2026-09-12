# Desplegar con Kamal

Guía paso a paso. Si solo quieres el resumen, está en la sección
[Qué reemplaza a qué](#qué-reemplaza-a-qué) al final.

---

## Qué necesitas antes de empezar

Cuatro cosas, ninguna la puede rellenar el código por ti:

1. **Un servidor** — cualquier VPS (DigitalOcean, Hetzner, etc.) al que
   puedas entrar por SSH como `root` (o un usuario con Docker/sudo). Puede
   ser el mismo servidor donde vive hoy `deploy.sh`, o uno nuevo para probar
   sin tocar el que está en producción — ver la nota de puertos más abajo
   antes de decidir.
2. **Una cuenta en un registro de imágenes** — donde Kamal sube la imagen
   construida para que el servidor la descargue. La más simple es
   [Docker Hub](https://hub.docker.com) (cuenta gratis). También sirve
   `ghcr.io` (GitHub Container Registry) si prefieres quedarte en GitHub.
3. **El dominio apuntando al servidor** — un registro DNS tipo A de
   `hotelmesondelbosque.com.mx` (o de `hotelmesondelbosque.hectoraguilar.dev`
   mientras estás en fase de pruebas) hacia la IP del servidor. Kamal pide el
   certificado TLS a Let's Encrypt automáticamente, pero Let's Encrypt
   necesita que el dominio ya resuelva a ese servidor antes de emitirlo.
4. **Docker en tu máquina** — Kamal construye la imagen localmente (o en el
   propio servidor, según configuración) antes de subirla. Si ya pudiste
   correr `docker build` o `docker compose build` en este repo, ya lo
   tienes.

El gem `kamal` ya está instalado (`bundle exec kamal ...`); no hace falta
nada más para tenerlo disponible.

---

## Paso 1 — cuenta y token en el registro de imágenes

Elige uno. Docker Hub es lo más simple si no quieres crear nada nuevo;
GHCR sirve si ya vives en GitHub y prefieres no abrir otra cuenta.

### Opción A — Docker Hub

1. Crea una cuenta en [hub.docker.com](https://hub.docker.com) si no tienes.
2. En **Account Settings → Personal access tokens**, genera un token con
   permiso de lectura/escritura (Read & Write). Cópialo — no se vuelve a
   mostrar.
3. Anota tu **nombre de usuario** de Docker Hub — lo necesitas en el paso 3.

No hace falta crear el repositorio de imagen a mano; Docker Hub lo crea solo
(público) la primera vez que Kamal hace push.

### Opción B — GitHub Container Registry (ghcr.io)

Usa tu cuenta de GitHub que ya tienes — no necesitas crear nada nuevo.

1. Ve a **github.com → foto de perfil → Settings → Developer settings →
   Personal access tokens → Tokens (classic)** ([enlace
   directo](https://github.com/settings/tokens)) y genera uno nuevo.
   (Los *fine-grained tokens* no siempre alcanzan a cubrir paquetes/GHCR de
   forma confiable todavía — el token clásico es la vía segura.)
2. Marca el scope **`write:packages`** (esto arrastra `read:packages`
   automáticamente). Sin fecha de expiración corta, o vas a tener que
   regenerarlo y volver a exportarlo cada tanto.
3. Cópialo al generarlo — no se vuelve a mostrar.
4. Anota tu **nombre de usuario de GitHub** — lo necesitas en el paso 3.
5. La primera vez que Kamal suba la imagen, el paquete se crea en
   `github.com/<tu-usuario>?tab=packages` como **privado** por defecto. Para
   que el servidor pueda descargarlo sin fricción, dos caminos:
   - Entra al paquete → **Package settings → Change visibility → Public**
     (más simple, igual que Docker Hub); o
   - Déjalo privado y usa el mismo token (con `read:packages`) como
     `KAMAL_REGISTRY_PASSWORD` también en el servidor — Kamal ya hace el
     `docker login` ahí con esas mismas credenciales antes del `pull`, así
     que no necesitas ningún paso extra aparte de esto.

## Paso 2 — acceso SSH al servidor

Kamal se conecta por SSH igual que lo harías tú a mano. Necesitas poder
hacer, desde tu máquina:

```bash
ssh root@IP_DEL_SERVIDOR
```

sin que te pida contraseña (con tu llave SSH ya autorizada en
`~/.ssh/authorized_keys` del servidor). Si el servidor solo tiene un usuario
sin privilegios de root, se puede usar (ver `ssh:` al final de
`config/deploy.yml`), pero ese usuario necesita poder correr Docker.

## Paso 3 — rellenar `config/deploy.yml`

Abre [`config/deploy.yml`](config/deploy.yml) y edita solo estas líneas
(están marcadas `TODO` en el archivo):

```yaml
# Línea ~14 — tu cuenta del paso 1 + el nombre de este proyecto
image: tu-usuario/hotel_meson

# Línea ~19 — la IP o el hostname del servidor del paso 2
servers:
  web:
    - 203.0.113.10

# Líneas ~30-33 — tu usuario del registro (y el server, si no es Docker Hub)
registry:
  # server: ghcr.io        # descomenta solo si usas GitHub Container Registry
  username: tu-usuario
```

Nota que `image:` **nunca** lleva el prefijo del registro (ni `ghcr.io/` ni
nada) — eso lo antepone Kamal solo, tomándolo de `registry.server`. Así que
el mismo `image: tu-usuario/hotel_meson` sirve para las dos opciones del
paso 1; lo único que cambia entre Docker Hub y GHCR es:

| Registro | `registry.server` | `registry.username` |
|---|---|---|
| Docker Hub | *(déjalo comentado)* | tu usuario de Docker Hub |
| GHCR | `ghcr.io` | tu usuario de GitHub |

Todo lo demás del archivo (el dominio, el volumen de la base de datos, el
health check) ya está resuelto — no necesita edición.

## Paso 4 — la contraseña del registro

Esta **no** va en el repo. Antes de desplegar, en la terminal desde la que
vas a correr `kamal`:

```bash
export KAMAL_REGISTRY_PASSWORD=el_token_del_paso_1
```

`.kamal/secrets` ya sabe leerla de esa variable de entorno (y ya sabe leer
`RAILS_MASTER_KEY` directo de `config/master.key`, sin que hagas nada).

Si vas a desplegar seguido, puedes poner ese `export` en tu shell profile
(`~/.bashrc`, `~/.config/fish/config.fish`, etc.) en vez de escribirlo cada
vez — pero nunca lo escribas dentro de un archivo del repo.

## Paso 5 — primer despliegue

Con los 3 pasos anteriores hechos:

```bash
bundle exec kamal setup
```

Esto, en orden:

1. Instala Docker en el servidor si hace falta.
2. Construye la imagen localmente y la sube al registro del paso 1.
3. Arranca `kamal-proxy` en el servidor (reemplaza a `docker/nginx.conf` —
   pide el certificado TLS solo, vía Let's Encrypt, para el `proxy.host` de
   `config/deploy.yml`).
4. Levanta el contenedor de la app.

En este primer arranque, con el volumen `hotel_meson_storage` vacío,
`bin/docker-entrypoint` corre `rails db:prepare`, que crea la base **y la
siembra** (`db/seeds.rb`) — igual que pasa hoy en un `docker compose up`
contra un volumen nuevo.

Verifica que responde:

```bash
curl -I https://hotelmesondelbosque.com.mx/up
```

## Despliegues siguientes

Una vez hecho el `setup` inicial, cada despliegue nuevo es solo:

```bash
bundle exec kamal deploy
```

---

## Nota importante si reusas el servidor de `deploy.sh`

`kamal-proxy` quiere los puertos 80 y 443 del servidor para sí mismo (ahí
recibe el tráfico y hace el TLS). Si en ese mismo servidor ya hay algo
ocupando esos puertos para el sitio actual — un nginx/caddy a nivel de
sistema, por ejemplo — hay conflicto. Antes de correr `kamal setup` en el
servidor de producción actual, confirma qué tiene ocupado el 80/443 ahí
(`sudo ss -tlnp | grep -E ':80|:443'`). Si hay duda, prueba primero contra un
servidor nuevo o contra el dominio de pruebas
(`hotelmesondelbosque.hectoraguilar.dev`) en una IP distinta.

## Las dos fases del sitio

Mismas variables que en `compose.yaml` / `DEPLOY.md`, ahora en
`config/deploy.yml` bajo `env.clear` (comentadas — descoméntalas mientras
el sitio vive en `hotelmesondelbosque.hectoraguilar.dev`, quítalas de nuevo
al lanzar en el dominio definitivo):

```yaml
env:
  clear:
    SITE_HOST: hotelmesondelbosque.hectoraguilar.dev
    ALLOW_INDEXING: "false"
```

Si cambias de dominio entre fases, actualiza también `proxy.host` al mismo
tiempo — es el dominio para el que Kamal pide el certificado TLS.

## Qué reemplaza a qué

- **`docker/nginx.conf`** → lo hace `kamal-proxy` (incluido en Kamal), con
  TLS automático.
- **El `/data` de `fly.toml`** (intento de Fly.io, descartado) → el volumen
  `hotel_meson_storage:/rails/storage` en `config/deploy.yml`, que es donde
  este Dockerfile realmente guarda la base sqlite (`config/database.yml`) y
  los archivos de ActiveStorage (`config/storage.yml`).
- **`deploy.sh` / `compose.yaml`** → siguen ahí tal cual, sin tocar. Esto es
  una ruta de despliegue alterna, no un reemplazo (todavía).

## Otras órdenes útiles

```bash
bundle exec kamal app logs           # logs del contenedor
bundle exec kamal app exec -i bash   # shell dentro del contenedor
bundle exec kamal console            # rails console remoto
bundle exec kamal config             # valida config/deploy.yml sin conectarse a nada
```
