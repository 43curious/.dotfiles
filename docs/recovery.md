# Recuperar un equipo

El repo configura un sistema operativo ya instalado. Recuperar del gestor la
clave SSH del Mac, las credenciales de administrador y el acceso a GitHub y
Tailscale. Los archivos y bases de datos necesitan sus propias copias: ver
[secretos y datos](secrets.md).

## MacBook del trabajo: kleya

1. Reinstalar macOS y seguir el alta institucional/MDM para recuperar la
   cuenta `jcastro`, sus certificados y permisos. El perfil es Apple Silicon;
   no crea ni modifica la cuenta institucional.
2. Instalar las herramientas de desarrollo de Apple y Homebrew:

   ```sh
   xcode-select --install
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. Clonar y restaurar. HTTPS permite obtener el repo público antes de
   recuperar la clave SSH; si pasa a privado, autenticarse primero.

   ```sh
   git clone https://github.com/43curious/.dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ./bootstrap
   ./dotfiles plan kleya --local
   ./dotfiles apply kleya --local
   ./dotfiles check kleya --local
   ```

4. Cerrar y abrir Rex para cargar tema y tipografía. Dar permisos de
   Accesibilidad a AeroSpace y activar su inicio de sesión. Autorizar
   Tailscale con la cuenta habitual.
5. Recuperar documentos, proyectos y bibliotecas desde su copia. Instalar
   DaVinci Resolve Studio y activar su licencia; recuperar bases de datos
   de proyectos, presets y LUTs desde la copia de Resolve. Iniciar sesión en
   Adobe para Audition/Lightroom y en App Store/Creator Studio para Logic,
   Pages y Keynote. Sophos y el software institucional se recuperan con IT.
6. Recuperar del gestor la clave SSH, con modo `0600` y su carpeta con `0700`:

   ```sh
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
   ```

`macos/applications.json` registra nombres, identificadores y versiones.
Homebrew instala las aplicaciones compatibles que falten y respeta las
existentes, incluidas las de IT. Las licencias no se extraen al repositorio.

## Servidores: bagheera e hirayama

1. Instalar Fedora Server para bagheera o Debian 13 para hirayama. Para
   conservar el escritorio, seleccionar GNOME en Fedora y Cinnamon en
   Debian durante la instalación, como en los equipos actuales. Crear `jon`
   con UID/GID 1000 y permisos de administrador; usar el nombre del equipo.
2. Conectar los discos originales sin formatearlos. Si se perdieron,
   restaurarlos antes y actualizar sus UUID reales en `inventory/host_vars/`.
3. Desde la consola, instalar los prerrequisitos:

   ```sh
   # Debian
   sudo apt-get update
   sudo apt-get install -y git curl ca-certificates python3 sudo
   # Fedora
   sudo dnf install -y git curl ca-certificates python3 sudo
   ```

4. Clonar y ejecutar el perfil correcto:

   ```sh
   git clone https://github.com/43curious/.dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ./bootstrap
   ./dotfiles plan hirayama --local
   ./dotfiles apply hirayama --local
   ```

   En una instalación limpia, `jon` puede tener `/home/jon`. Antes de aplicar
   hirayama, ajustar `dotfiles_home` para usar esa carpeta o crear inicialmente
   la cuenta con `/home/platoa`. El repo no mueve una cuenta con sesiones activas.
5. Recuperar el estado de Jellyfin y qBittorrent en Copper antes de arrancar
   sus contenedores. Si falta ese estado:

   ```sh
   ./dotfiles apply bagheera --local --skip-tags workloads
   # Recuperar los datos y después:
   ./dotfiles apply bagheera --local --tags workloads
   ```

   La primera aplicación cambia las referencias de etiqueta a digest y puede
   recrear los contenedores. Las carpetas de estado permanecen en sus montajes.

6. Autorizar Tailscale y crear el acceso SMB con el secreto del gestor:

   ```sh
   sudo tailscale up
   sudo smbpasswd -a jon
   ./dotfiles check hirayama --local
   ```

   Si la credencial SMB ya existe, no hay que cambiarla. También se puede
   inyectar `DOTFILES_SMB_PASSWORD`; Ansible solo crea el usuario SMB si falta.
7. Reiniciar cuando el trabajo esté guardado para comprobar montajes y
   servicios en arranque. El repo no reinicia equipos automáticamente.

## Acceso remoto después de reinstalar

Los nombres SSH del sistema son `bagheera.mau-skate.ts.net`,
`hirayama.mau-skate.ts.net` y `kleya.mau-skate.ts.net`. Los nombres con `-1`
observados en Rex pertenecen a nodos embebidos y no ofrecen SSH/SMB del SO.

Una reinstalación genera una clave de host nueva. Comparar en la consola su
huella con `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` y actualizar
`keys/known_hosts` con la clave pública correcta. Si cambia el nombre del nodo
de Tailscale, actualizar también `inventory/hosts.yml`.

Volver a añadir los servidores a Rex por SSH, usando `rex hosts add --help`
de la versión instalada. Las claves privadas y el emparejamiento de Rex no
se publican; Lua y apariencia sí se restauran. Se conserva el modo compartido
de bagheera y el socket personal de hirayama sin reiniciar sesiones activas.

Para ejecutar desde el Mac, desbloquear la clave SSH y usar el mismo
`./dotfiles plan|apply|check PERFIL` sin `--local`.

## Revisar y volver a una configuración anterior

`plan` muestra diferencias sin aplicar configuraciones. Las herramientas
pueden descargar metadatos y usar archivos temporales; simular una instalación
sin paquetes todavía no sustituye una prueba completa de recuperación.
Las tareas de copia, plantilla y montajes guardan archivos anteriores con
fecha; `.zshrc.before-dotfiles` conserva además la primera copia.

Para volver a una revisión, crear un checkout separado de ese commit,
ejecutar `./bootstrap`, revisar su `plan` y aplicar. Esto restaura la
configuración, pero no revierte datos ni desinstala versiones de paquetes.

Referencias: [Homebrew](https://docs.brew.sh/Installation),
[montajes de Ansible](https://docs.ansible.com/projects/ansible/latest/collections/ansible/posix/mount_module.html).
