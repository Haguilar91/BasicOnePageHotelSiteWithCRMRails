# Despliegue y lanzamiento

Checklist operativa del sitio. La guía para editar contenido (Avo, Easy Edit,
teléfonos, SEO) vive en el propio sitio, en `/docs`; esto es lo otro: lo que
hay que hacer en el servidor.

---

## Desplegar

```bash
./deploy.sh
```

Eso es todo. El script hace, en orden:

1. Respalda `storage/production.sqlite3` en `~/backups/`.
2. `git pull origin main`.
3. Reconstruye la imagen y recrea el contenedor.

Y al arrancar el contenedor, `docker/migrate.sh` (instalado como
`/etc/my_init.d/99_migrate.sh`) corre solo:

- `bundle install` si hace falta,
- **`rails db:migrate`** — las migraciones se aplican solas, no son un paso manual,
- `rails assets:precompile`.

---

## Configuración por fase

El sitio vive primero en la dirección de pruebas y después en el dominio
definitivo. Son dos configuraciones, y la diferencia entre ellas es qué
variables de entorno están puestas.

### Fase 1 — pre-lanzamiento, en `hotelmesondelbosque.hectoraguilar.dev`

```bash
SITE_HOST=hotelmesondelbosque.hectoraguilar.dev
ALLOW_INDEXING=false
```

Con eso, las URLs internas y las vistas previas de WhatsApp son correctas para
quien esté revisando el sitio, pero Google tiene prohibido indexarlo.

### Fase 2 — lanzamiento, cuando `hotelmesondelbosque.com.mx` apunte al servidor

**Quita las dos variables** y vuelve a desplegar. Los valores por defecto ya
son la configuración final:

| | Fase 1 (pruebas) | Fase 2 (lanzado) |
|---|---|---|
| `SITE_HOST` | `hotelmesondelbosque.hectoraguilar.dev` | *(sin definir)* |
| `ALLOW_INDEXING` | `false` | *(sin definir)* |
| Dominio en las URLs | `…hectoraguilar.dev` | `hotelmesondelbosque.com.mx` |
| ¿Google lo indexa? | no | **sí** |

El dominio por defecto está en `config/initializers/site_host.rb`.

---

## Checklist del día del lanzamiento

- [ ] Apuntar el DNS de `hotelmesondelbosque.com.mx` al servidor.
- [ ] Quitar `SITE_HOST` y `ALLOW_INDEXING` del entorno.
- [ ] `./deploy.sh`
- [ ] Verificar que `https://hotelmesondelbosque.com.mx/robots.txt` **ya no**
      dice `Disallow: /` y sí trae la línea `Sitemap:`.
- [ ] Dar de alta el sitio en [Google Search Console](https://search.google.com/search-console)
      y enviar `https://hotelmesondelbosque.com.mx/sitemap.xml`.
- [ ] Revisar la ficha del hotel con el
      [Rich Results Test](https://search.google.com/test/rich-results).
- [ ] Cambiar la contraseña de las cuentas de prueba con permisos de admin
      (`test@test.com`, `aaaa@google.com`) o borrarlas — el sitio pasa a ser
      público y esas cuentas entran a Avo.

---

## Red de seguridad

Aunque se olvide toda la configuración de arriba, el sitio **solo se deja
indexar mientras está contestando en su propio dominio canónico**. Una copia en
otra dirección —staging, una URL de preview, entrando por IP— sirve
`Disallow: /` por su cuenta.

Eso se decide comparando el host de la petición contra el dominio canónico
(`SeoHelper#canonical_host?`), no preguntando si tal variable existe. La razón:
un staging levantado con un respaldo de la base de producción heredaría
cualquier valor guardado en la base, pero no puede heredar el host por el que
lo están visitando.

---

## Cosas que no son automáticas

- **El respaldo de la base** sí se hace solo en cada deploy (`~/backups/`),
  pero nadie los rota — conviene limpiarlos de vez en cuando.
- **Search Console** es manual y de una sola vez (ver checklist arriba).
- **Las traducciones al inglés** se editan en `/translations`, no se generan
  solas al publicar contenido nuevo en español.

---

## Si `git pull` pide sudo

Quedaron archivos de un contenedor viejo con otro dueño. `deploy.sh` lo detecta
y te dice qué correr:

```bash
sudo chown -R $(id -u):$(id -g) ~/Sites/Hotel
```
