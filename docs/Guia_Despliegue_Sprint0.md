# VITA — Guía de despliegue del Sprint 0 (paso a paso)

Esta guía te lleva desde el `.zip` hasta **VITA instalada en tu iPhone**, gratis.

No puedo pegarte capturas reales de los paneles (cambian seguido y no debo inventarlas), así que te doy
**la ruta exacta de clics** en cada pantalla. Si alguna pantalla se ve distinta a lo que digo, avísame
y lo ajusto al instante.

**Tiempo estimado:** 30–45 min la primera vez. **Costo: $0.**

---

## Antes de empezar: el camino que vas a seguir

Para verla en tu iPhone, VITA tiene que estar publicada en una dirección web (no se puede instalar desde
un archivo suelto). El camino más simple para ti —porque **ya usas GitHub Pages** y no exige instalar
nada en tu computador— es:

```
  Supabase (base de datos)  ─┐
                             ├─►  GitHub (código)  ──►  GitHub Pages (publica solo)  ──►  iPhone
  Tus 2 llaves de Supabase  ─┘
```

GitHub construye y publica la app **automáticamente** cada vez que subes cambios.

### Una decisión que debes tomar (1 minuto)

GitHub Pages es **gratis solo en repositorios públicos**. Eso significa que el **código** de VITA quedaría
visible para cualquiera. Aclaración importante: tu **información personal NO está en el código** — vive en
Supabase, privada y protegida (RLS). El código es solo el "esqueleto" de la app, y la llave que se publica
(`anon key`) es pública por diseño y no da acceso a tus datos. Aun así, tú decides:

- **Opción A — repositorio público + GitHub Pages** (recomendada para empezar): la más simple, cero
  instalaciones, ya conoces Pages. Sigue las Partes 1 a 6.
- **Opción B — repositorio privado + Vercel** (la del plan): mantiene el código privado, pero pide instalar
  algunas herramientas. Está al final, en el **Apéndice**.

Mi recomendación: empieza con la **Opción A** para tener la victoria rápida en tu iPhone hoy; si más
adelante prefieres privado, te paso a Vercel sin problema.

---

## Parte 1 · Supabase (la base de datos)

### 1.1 Crear el proyecto
1. Entra a **supabase.com** e inicia sesión (puedes usar "Continue with GitHub").
2. Botón **New project** (arriba a la derecha, verde).
3. Completa:
   - **Name:** `vita-dev`
   - **Database Password:** genera una y **guárdala** (la necesitarás si algún día usas la CLI).
   - **Region:** elige **South America (São Paulo)** — es la más cercana a Chile, va más rápido.
   - **Plan:** **Free**.
4. **Create new project**. Espera ~2 minutos a que termine de prepararse.

### 1.2 Crear las tablas (correr la migración)
1. En la barra lateral izquierda, abre **SQL Editor**.
2. Clic en **+ New query**.
3. Abre en tu computador el archivo `supabase/migrations/0001_init.sql` (está dentro del `.zip`),
   copia **todo** su contenido y pégalo en el editor.
4. Clic en **Run** (o Ctrl/Cmd + Enter). Debe decir **Success. No rows returned**.
   - Esto crea la tabla `profiles` con seguridad por fila (RLS), el alta automática de perfil y el bucket
     de Storage privado.

### 1.3 Permitir el login rápido (desactivar confirmación por correo)
Para que "Crear cuenta" te deje entrar de inmediato (sin tener que confirmar un correo) durante las pruebas:
1. Barra lateral → **Authentication**.
2. Entra a **Sign In / Providers**.
3. En la lista de proveedores, clic en **Email** para abrir su configuración.
4. **Desactiva** el interruptor **Confirm email** (queda en gris/apagado).
5. **Save**.
   - Más adelante puedes volver a activarlo. Con esto apagado, al crear la cuenta entras directo.

### 1.4 Copiar tus 2 llaves
1. Barra lateral → **Project Settings** (el engranaje, abajo) → **API**.
2. Copia y guarda estos dos valores (los pegarás en GitHub en la Parte 3):
   - **Project URL** → será `SUPABASE_URL` (algo como `https://abcd1234.supabase.co`).
   - **API Keys → anon · public** → será `SUPABASE_ANON_KEY` (una cadena larga).
   - Tranquila: la `anon key` es **segura de publicar**; tus datos están protegidos por RLS, no por esconder esta llave.

✅ **Supabase listo.**

---

## Parte 2 · GitHub (el código)

### 2.1 Crear el repositorio
1. Entra a **github.com** con tu cuenta **yurne21-arch**.
2. Arriba a la derecha, **+** → **New repository**.
3. Completa:
   - **Owner:** yurne21-arch
   - **Repository name:** escribe **exactamente** `vita` (en minúsculas).
     > Importante: el nombre debe ser `vita` porque la app se publica en `.../vita/`. Si lo llamas distinto,
     > avísame para ajustar una línea del proyecto.
   - **Public** (necesario para que Pages sea gratis).
   - **No** marques "Add a README" (subiremos los archivos nosotras).
4. **Create repository**. Deja esa pestaña abierta.

### 2.2 Subir los archivos del `.zip`
Descomprime el `.zip` en tu computador: te queda una carpeta llamada `vita` con todo dentro.
Elige **una** de estas formas de subirla:

**Forma fácil (recomendada): GitHub Desktop (con ventanas, sin escribir comandos)**
1. Instala **GitHub Desktop** (descárgalo desde **desktop.github.com**) e inicia sesión con tu cuenta.
2. Menú **File → Add local repository…** y elige la carpeta `vita` que descomprimiste.
3. Si te dice que no es un repositorio git, clic en **create a repository** (lo convierte). Deja los datos por defecto y **Create repository**.
4. Arriba verás un botón **Publish repository**. Clic ahí:
   - Desmarca "Keep this code private" (debe quedar **público**).
   - Asegúrate de que el nombre sea `vita`.
   - **Publish repository**.
5. Cada cambio futuro: escribes un resumen abajo a la izquierda → **Commit to main** → **Push origin**.

**Forma alternativa: subir por la web**
1. En la página del repo vacío, clic en **uploading an existing file**.
2. Arrastra **todo el contenido** de la carpeta `vita` (incluida la carpeta oculta `.github`, que trae el
   automatismo de publicación). Si tu sistema oculta los archivos que empiezan con punto, usa GitHub Desktop
   en su lugar para no dejarlos fuera.
3. **Commit changes**.

### 2.3 Guardar tus 2 llaves como "secretos"
1. En tu repo `vita`: pestaña **Settings** (arriba).
2. Menú lateral → **Secrets and variables** → **Actions**.
3. Botón **New repository secret**. Crea estos dos (uno a la vez):
   - **Name:** `SUPABASE_URL` · **Secret:** (pega tu Project URL) · **Add secret**.
   - **Name:** `SUPABASE_ANON_KEY` · **Secret:** (pega tu anon key) · **Add secret**.
   - Escribe los nombres **idénticos**, en mayúsculas.

✅ **GitHub listo.**

---

## Parte 3 · Encender la publicación automática (GitHub Pages)

1. En tu repo `vita`: **Settings** → menú lateral **Pages**.
2. En **Build and deployment → Source**, elige **GitHub Actions** (no "Deploy from a branch").
3. No hay que guardar nada más; con elegir esa opción basta.

---

## Parte 4 · Disparar el primer despliegue y obtener la URL

El simple hecho de haber subido el código ya disparó el proceso. Para verlo:
1. En tu repo, pestaña **Actions**.
2. Verás un flujo llamado **CI & Deploy (GitHub Pages)** ejecutándose (círculo amarillo girando).
   - Tarda unos 3–6 minutos la primera vez (instala Flutter, analiza, prueba, construye y publica).
3. Cuando termine en **verde** ✅, tu app está publicada en:

   **https://yurne21-arch.github.io/vita/**

> Si quieres re-desplegar luego de un cambio: solo sube el cambio (Commit + Push) y el flujo corre de nuevo.

---

## Parte 5 · Instalar VITA en tu iPhone

1. Abre **Safari** en tu iPhone (tiene que ser Safari para poder instalarla).
2. Ve a **https://yurne21-arch.github.io/vita/**.
3. Toca el botón **Compartir** (el cuadrado con la flecha hacia arriba, abajo al centro).
4. Desliza y toca **Añadir a pantalla de inicio** → **Añadir** (arriba a la derecha).
5. Sal de Safari y abre el ícono **VITA** desde tu pantalla de inicio: se abre **a pantalla completa**, como una app.

### Probar que todo funciona
1. En la pantalla de bienvenida, escribe un correo y una contraseña y toca **Crear cuenta**
   (como desactivaste la confirmación, entra directo).
2. Deberías ver **Mi Vida** con tu saludo y la tarjeta **"Perfil sincronizado con Supabase"** ✅
   (eso confirma el viaje de ida y vuelta del dato, con RLS).
3. Abajo están las **5 pestañas**: Mi Vida, Salud, Proyectos, Calendario, Más
   (las otras 4 muestran "Próximamente" — es lo correcto en el Sprint 0).
4. El ícono de cerrar sesión está arriba a la derecha en Mi Vida.

✅ **VITA está viva en tu iPhone.**

---

## Parte 6 · Validar el Sprint 0 (tu checklist)

Marca cada punto. Si todos se cumplen, el Sprint 0 está **aprobado** y recién ahí pasamos al Sprint 1.

- [ ] El flujo **CI & Deploy** quedó **verde** (compila, analiza y prueba sin errores).
- [ ] El **login / crear cuenta** funciona.
- [ ] En Mi Vida aparece **"Perfil sincronizado"** (round-trip con Supabase + RLS).
- [ ] La **PWA se instaló** en tu iPhone y abre **a pantalla completa** desde el ícono.
- [ ] Las 5 pestañas se ven y el shell se siente **rápido y limpio** (<5 s).
- [ ] **No gastaste nada** ($0) y no se activó ningún servicio de pago.

---

## Parte 7 · (Opcional) Trabajar en tu computador

No es necesario para tener VITA en el iPhone, pero si quieres editar y ver cambios al instante, instala Flutter:

**Windows**
1. Descarga Flutter (stable) de **docs.flutter.dev/get-started/install/windows**.
2. Descomprime en `C:\src\flutter` y agrega `C:\src\flutter\bin` al **Path** (variables de entorno).
3. Abre una terminal nueva y corre `flutter doctor` (instala lo que te pida).

**Mac**
1. Sigue **docs.flutter.dev/get-started/install/macos** (descarga directa o `brew install --cask flutter`).
2. Corre `flutter doctor`.

**Correr la app localmente** (en la carpeta del proyecto):
```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY
```

---

## Parte 8 · Si algo sale mal (soluciones rápidas)

**La página sale en blanco / no carga en `…/vita/`.**
- Casi siempre es el nombre del repo: debe llamarse **`vita`**. Si lo llamaste distinto, avísame.
- Verifica que en **Settings → Pages** el Source sea **GitHub Actions**.
- GitHub Pages cachea fuerte (ya lo conoces): haz **recarga forzada** o prueba en una pestaña privada.

**Aparece "Faltan SUPABASE_URL y SUPABASE_ANON_KEY".**
- Los secretos no están o tienen el nombre mal escrito. Revisa **Settings → Secrets and variables → Actions**
  (nombres idénticos, en mayúsculas) y vuelve a subir un cambio para reconstruir.

**Creo la cuenta y no entra / me pide confirmar correo.**
- Quedó activada la confirmación. Vuelve a **Authentication → Sign In / Providers → Email** y desactiva
  **Confirm email**. Luego intenta de nuevo.

**El flujo de Actions queda en rojo.**
- Abre el paso que falló, copia el mensaje y **pégamelo**: te digo la línea exacta a corregir.
  (Lo más común al inicio son ajustes menores de versión de paquetes; se arreglan rápido.)

**En la consola web veo "LocalCache no disponible".**
- Es **normal** en Web en el Sprint 0: el caché local (Drift) es opcional y best-effort. Tus datos están a
  salvo en Supabase igual. Se habilita el caché web más adelante.

**Hice un cambio y no se ve.**
- Sube el cambio (Commit + Push), espera a que Actions termine en verde, y haz **recarga forzada** en el iPhone
  (cierra la PWA y vuélvela a abrir).

---

## Apéndice · Opción B: repositorio privado + Vercel (la del plan)

Si prefieres mantener el código **privado**, GitHub Pages no aplica (sería de pago). En su lugar:

1. Crea el repo en GitHub como **Private** y sube el código igual que en la Parte 2.
2. Necesitarás construir el sitio en tu computador (instala Flutter, Parte 7) y, además, **Node.js**.
3. Instala la CLI de Vercel: `npm i -g vercel` e inicia sesión: `vercel login`.
4. Construye:
   ```bash
   cd app
   flutter build web --release \
     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
   ```
5. Publica la carpeta construida:
   ```bash
   cd build/web
   vercel --prod
   ```
   Sigue las preguntas (acepta los valores por defecto). Al final te da una URL `…vercel.app` para abrir en
   tu iPhone igual que en la Parte 5.
6. Para que las rutas internas no den 404 al recargar, crea un archivo `vercel.json` dentro de `build/web` con:
   ```json
   { "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }] }
   ```

> Esta vía da más control y privacidad, a cambio de instalar Flutter + Node y publicar a mano. Si te decides
> por aquí, te acompaño con una versión a tu medida (incluso automatizándolo para que también se publique solo).

---

¿Lista? Empieza por la **Parte 1**. Si te trabas en cualquier paso, dime exactamente en qué pantalla estás y
qué ves, y te desatasco.
