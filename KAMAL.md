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

**Generar el token:**

1. Ve a **github.com → foto de perfil → Settings → Developer settings →
   Personal access tokens → Tokens (classic)** ([enlace
   directo](https://github.com/settings/tokens)) y genera uno nuevo.
   (Los *fine-grained tokens* no siempre alcanzan a cubrir paquetes/GHCR de
   forma confiable todavía — el token clásico es la vía segura.)
2. Marca el scope **`write:packages`** (esto arrastra `read:packages`
   automáticamente). Ponle una fecha de expiración razonable — GitHub ya no
   deja crear uno sin expiración — y anota cuándo vence: ese día
   `kamal deploy` empezará a fallar en el push/pull hasta que generes otro y
   repitas los pasos de "dárselo a Kamal" de abajo.
3. Al generarlo, GitHub te lo muestra **una sola vez**. Cópialo ya mismo a
   un gestor de contraseñas (1Password, Bitwarden, lo que uses) — si lo
   pierdes no hay forma de recuperarlo, solo de revocarlo y generar otro.

**Qué hacer con el token una vez generado:**

Todavía no lo pongas en `config/deploy.yml` — ese archivo va al repo, y un
token ahí quedaría expuesto. Dos usos, ambos como variable de entorno en tu
terminal, nunca en un archivo del repo:

1. **Probarlo antes de meterlo en Kamal** (opcional, pero te ahorra
   confundir un token malo con un error de Kamal):

   ```bash
   echo "TU_TOKEN" | docker login ghcr.io -u tu-usuario-de-github --password-stdin
   ```

   Un `Login Succeeded` confirma que el token y el usuario están bien.
2. **Dárselo a Kamal**, que es lo que de verdad necesitas — es el **Paso 4**
   de esta guía, más abajo (`export KAMAL_REGISTRY_PASSWORD=...`). Es el
   mismo token en los dos casos.

Y anota tu **nombre de usuario de GitHub** — lo necesitas en el **Paso 3**
de esta guía, para `registry.username`.

**Después del primer `kamal setup`/`kamal deploy`** (el push crea el
paquete solo — no hay nada que crear a mano antes):

1. El paquete aparece en `github.com/<tu-usuario>?tab=packages`, como
   **privado** por defecto. Para que el servidor lo descargue sin fricción,
   dos caminos:
   - Entra al paquete → **Package settings → Change visibility → Public**
     (más simple, igual que Docker Hub); o
   - Déjalo privado — no hace falta nada más, porque Kamal ya hace el mismo
     `docker login` en el servidor con este token (el
     `KAMAL_REGISTRY_PASSWORD` del Paso 4) antes de cada `pull`.
2. Opcional: en la página del paquete, **Package settings → Connect
   repository**, para ligarlo a este repo — aparece entonces en su sidebar
   de GitHub, útil si más adelante alguien más además de ti va a desplegar.

## Paso 2 — acceso SSH al servidor

Antes que nada, define la IP del servidor como variable de entorno — se usa
en los comandos de esta guía y en `config/deploy.yml` (que la lee vía
`<%= ENV.fetch("SERVER_IP") %>` en `servers:`), así que solo hace falta
ponerla en un lugar:

```bash
export SERVER_IP=tu_ip_o_hostname
```

(o en `.envrc` si usas `direnv` — así queda puesta cada vez que entras a la
carpeta del proyecto, sin repetir el `export`.)

Kamal se conecta por SSH igual que lo harías tú a mano. Necesitas poder
hacer, desde tu máquina:

```bash
ssh TU_USUARIO@$SERVER_IP
```

sin que te pida contraseña (con tu llave SSH ya autorizada en
`~/.ssh/authorized_keys` del servidor). Si `TU_USUARIO` no es `root`, ese
usuario necesita:

- Pertenecer al grupo `docker` (o poder correr `docker` sin `sudo`) — si no,
  cada comando de Kamal falla con un `permission denied` contra
  `/var/run/docker.sock`.
- `sudo` sin contraseña (`NOPASSWD`) **solo** si Docker todavía no está
  instalado en el servidor — `kamal setup` lo instala la primera vez y
  necesita privilegios para eso. Si Docker ya está instalado (o lo instalas
  tú una vez a mano como root), no hace falta darle sudo a este usuario en
  absoluto.

Esto se configura del lado del servidor (no en este repo). Con acceso a
`root` una sola vez (por SSH o por la consola web del proveedor):

```bash
usermod -aG docker TU_USUARIO        # para que corra docker sin sudo
# Opcional, solo si Docker no está instalado aún y quieres que
# `kamal setup` lo instale por ti:
echo "TU_USUARIO ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/TU_USUARIO
```

Luego, en `config/deploy.yml`, descomenta y rellena `ssh.user` con
`TU_USUARIO` (ver `# ssh:` al final del archivo) — sin esto Kamal intenta
conectarse como `root`. En este repo ya está puesto como `ssh: user: deploy`,
así que si tu droplet usa un usuario `deploy`, sustituye `TU_USUARIO` por
`deploy` en todos los comandos de esta sección.

**Si tu droplet de DigitalOcean solo tiene contraseña** (no elegiste una
llave SSH al crearlo, o lo creaste hace tiempo): Kamal abre muchas conexiones
SSH en paralelo durante un deploy y no tiene forma de pedirte la contraseña
interactivamente en cada una, así que necesitas pasar antes a autenticación
por llave. Es un paso único:

1. **Genera una llave** en tu máquina, si no tienes ninguna todavía
   (`ls ~/.ssh/*.pub` para comprobarlo):

   ```bash
   ssh-keygen -t ed25519 -C "tu-email"
   ```

   Enter para aceptar la ruta por defecto; puedes dejar la passphrase vacía
   o ponerle una (te la pedirá tu agente SSH, no Kamal).

2. **Cópiala al servidor** con la contraseña que ya tienes de ese usuario —
   la vas a escribir una última vez, aquí:

   ```bash
   ssh-copy-id TU_USUARIO@$SERVER_IP
   ```

   Esto añade tu llave pública a `~/.ssh/authorized_keys` de `TU_USUARIO` en
   el servidor. Si el comando no está disponible o el servidor bloquea SSH
   por contraseña desde fuera, usa la alternativa de abajo.

3. **Verifica** que ya entra sin contraseña:

   ```bash
   ssh TU_USUARIO@$SERVER_IP
   ```

**Alternativa sin `ssh-copy-id`** — vía la consola web de DigitalOcean
(droplet → pestaña **Access** → **Launch Droplet Console**, entra con la
contraseña ahí mismo sin pasar por tu SSH local; si el usuario no es
`root` puede que primero tengas que entrar como `root` en esa consola y
hacer el resto como ese usuario, o con `sudo -u TU_USUARIO -i`):

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "PEGA_AQUI_TU_LLAVE_PUBLICA" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

(corriendo esto ya como `TU_USUARIO`, para que quede en su propio
`~/.ssh/authorized_keys` y no en el de `root`). Tu llave pública (lo que
pegas arriba) es el contenido de `~/.ssh/id_ed25519.pub` en tu máquina
(`cat ~/.ssh/id_ed25519.pub`) — nunca compartas el archivo sin `.pub`, ese
es el privado.

Una vez que `ssh TU_USUARIO@$SERVER_IP` entra sin pedir contraseña, ya
no necesitas esa contraseña para nada más de esta guía — Kamal usa la
llave. Si quieres, desde el panel de DigitalOcean (o editando
`/etc/ssh/sshd_config` en el servidor) puedes desactivar el login por
contraseña, pero no es imprescindible para que Kamal funcione.

## Paso 3 — rellenar `config/deploy.yml`

Abre [`config/deploy.yml`](config/deploy.yml) y edita solo estas líneas
(están marcadas `TODO` en el archivo):

```yaml
# Línea ~14 — tu cuenta del paso 1 + el nombre de este proyecto
image: tu-usuario/hotel_meson

# Línea ~19 — ya lee SERVER_IP (paso 2) vía ERB, no hace falta tocarla aquí
servers:
  web:
    - <%= ENV.fetch("SERVER_IP") %>

# Líneas ~30-33 — tu usuario del registro (y el server, si no es Docker Hub)
registry:
  # server: ghcr.io        # descomenta solo si usas GitHub Container Registry
  username: tu-usuario

# Al final del archivo — solo si te conectas por SSH con un usuario que no
# es root (ver Paso 2)
ssh:
  user: tu_usuario_no_root
```

Nota que `image:` **nunca** lleva el prefijo del registro (ni `ghcr.io/` ni
nada) — eso lo antepone Kamal solo, tomándolo de `registry.server`. Así que
el mismo `image: tu-usuario/hotel_meson` sirve para las dos opciones del
paso 1; lo único que cambia entre Docker Hub y GHCR es:

| Registro | `registry.server` | `registry.username` |
|---|---|---|
| Docker Hub | *(déjalo comentado)* | tu usuario de Docker Hub |
| GHCR | `ghcr.io` | tu usuario de GitHub |

`registry.username` sí puede llevar mayúsculas (como aparece tu usuario de
GitHub, por ejemplo) — el login no distingue mayúsculas/minúsculas. Pero
`image:` es un nombre de repositorio Docker y **tiene que ir todo en
minúsculas**; si tu usuario de GitHub/Docker Hub tiene mayúsculas, escríbelo
en minúsculas solo en `image:` (`docker buildx build` falla con `repository
name must be lowercase` si no).

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

Como el DNS del dominio real puede no apuntar todavía a este droplet, el
bloque `proxy:` de `config/deploy.yml` arranca sin `ssl`/`host` — solo con
`app_port: 3000` (necesario siempre: el contenedor escucha en el 3000, y sin
esto `kamal-proxy` revisa por defecto el puerto 80, donde no responde nada, y
el deploy falla con "target failed to become healthy"). Así puedes probar
que el contenedor arrancó bien pegándole directo a la IP, sin TLS:

```bash
curl -I http://$SERVER_IP/up
```

## Después de transferir el dominio a este droplet

Checklist completo para cuando el registro A de `hotelmesondelbosque.com.mx`
(o de `hotelmesondelbosque.hectoraguilar.dev` en fase de pruebas — ver [Las
dos fases del sitio](#las-dos-fases-del-sitio)) ya apunte a la IP de este
droplet:

1. **Confirma que el DNS ya resuelve aquí** — debe devolver la IP del
   droplet (puede tardar minutos u horas en propagar tras cambiar el DNS en
   el registrador):

   ```bash
   dig +short tu-dominio
   ```

2. **Reactiva `force_ssl`/`assume_ssl` en `config/environments/production.rb`**
   — si en algún momento los desactivaste para probar por IP sin TLS (ver
   la nota `TEMP` en ese archivo), descoméntalos ahora. Sin esto no hay
   HTTPS forzado, ni HSTS, ni cookies marcadas `secure` — quedaría corriendo
   en "modo prueba" en producción:

   ```ruby
   config.assume_ssl = true
   config.force_ssl = true
   ```

3. **Añade `ssl: true` y `host: tu-dominio` al bloque `proxy:`** de
   `config/deploy.yml` (que ya tiene `app_port: 3000` desde el Paso 5):

   ```yaml
   proxy:
     ssl: true
     host: hotelmesondelbosque.com.mx   # o el de pruebas, según la fase
     app_port: 3000
   ```

4. **Si este es el lanzamiento definitivo** (no la fase de pruebas en
   `.hectoraguilar.dev`), quita `SITE_HOST`/`ALLOW_INDEXING` de `env.clear`
   en `config/deploy.yml` si las habías descomentado — ver [Las dos fases
   del sitio](#las-dos-fases-del-sitio). Dejarlas puestas mantiene el sitio
   sirviendo bajo el dominio de pruebas y bloqueado para buscadores aunque
   ya estés en el dominio real.

5. **Redeploy** — en este paso `kamal-proxy` pide el certificado a Let's
   Encrypt automáticamente (necesita el DNS del paso 1 ya propagado):

   ```bash
   bundle exec kamal deploy
   ```

6. **Verifica que responde por HTTPS y que las imágenes cargan** (antes de
   los pasos 2-3 de este checklist, los links de ActiveStorage se generaban
   en `https://` pero no había TLS real, así que las imágenes rotas son la
   señal de que faltó alguno de estos pasos):

   ```bash
   curl -I https://tu-dominio/up
   ```

   Abre el sitio en el navegador y confirma que las imágenes cargan y que
   el candado del certificado es válido (no autofirmado).

7. **Si este servidor reemplaza al de `deploy.sh`/`compose.yaml`** (mismo
   dominio, servidor distinto): una vez confirmado que todo funciona aquí,
   ese otro servidor deja de recibir tráfico en cuanto el DNS termine de
   propagar — no hace falta apagarlo de inmediato, pero ya no lo actualiza
   ningún deploy nuevo.

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
