# Dotfiles y equipos

La configuración de mis tres equipos, con perfiles declarativos y unos pocos
comandos para revisar, restaurar y comprobar el resultado. Ansible ejecuta las
tareas; macOS usa Homebrew, Fedora usa DNF y Debian usa APT.

| Perfil | Equipo | Usuario y carpeta personal | Prompt | Datos y servicios |
| --- | --- | --- | --- | --- |
| `kleya` | MacBook del trabajo, Apple Silicon / macOS | `jcastro`, `/Users/jcastro` | Cian, 14 | Homebrew, AeroSpace, Rex, Ghostty, Neovim |
| `bagheera` | Fedora Server | `jon`, `/home/jon` | Morado, 177 | Copper, Pewter, Samba, Jellyfin, qBittorrent |
| `hirayama` | Debian 13 | `jon`, `/home/platoa` | Naranja, 208 | iMac Plato, Samba |

## Empezar

En el Mac, desde este checkout:

```sh
./bootstrap
./dotfiles plan kleya --local
./dotfiles apply kleya --local
./dotfiles check kleya --local
```

`bootstrap` instala el motor en `.venv` y las colecciones en `.ansible`; esas
carpetas se ignoran en Git. Usa Python 3.13 gestionado por uv, sin modificar el
Python del sistema. `plan` usa el modo check de Ansible y muestra diferencias;
`apply` pide la contraseña de sudo cuando hace falta.

Para los servidores, desbloquear primero la clave SSH habitual:

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
./dotfiles plan bagheera
./dotfiles apply bagheera
./dotfiles check bagheera
```

Cambiar `bagheera` por `hirayama`, `servers` o `all`. Los grupos comparten una
contraseña de sudo por ejecución interactiva; usar perfiles individuales si
sus contraseñas son diferentes. Desde la consola de un servidor también se
puede clonar el repo, ejecutar `./bootstrap` y usar `--local` con su perfil.

```sh
./dotfiles apply hirayama --local
./dotfiles plan servers --tags user
./dotfiles apply bagheera --skip-tags workloads
./dotfiles capture servers
```

`capture` guarda un inventario para revisar en `.local/captures/`, fuera de Git.
No convierte automáticamente lo encontrado en configuración deseada.

## Qué se restaura

- Un shell común con los tres colores, historial, atajos y estado de Git.
  El Mac conserva Oh My Zsh, autosugerencias y resaltado de sintaxis. Los
  plugins se fijan a los commits capturados. `~/.zshrc.local` permite añadidos
  privados sin editar el archivo administrado.
- Git, Neovim y los atajos de Rex. En el Mac también se restauran los ajustes
  visuales de Rex —incluido el tema Dark+, SF Mono y tamaño 23—, Ghostty,
  AeroSpace, atajos del sistema, teclado, trackpad, Finder y Dock.
- Paquetes, cuenta `jon` con UID/GID 1000, claves públicas autorizadas,
  SSH, zona horaria, Tailscale y persistencia de Rex en Linux. Se conservan
  las preferencias de escritorio y entrada que se encontraron en dconf.
- Montajes de datos por UUID y las carpetas compartidas `media`, `documents`
  e `iMac Plato`. Samba comprueba el disco real antes de dar acceso y oculta
  `lost+found`. Se conserva SELinux en Fedora.
- El Compose de bagheera, con las dos imágenes actuales fijadas por digest,
  y un servicio que espera al disco antes de arrancar los contenedores.

Las tareas guardan copias de los archivos que sustituyen. Los montajes no
formatean discos, no cambian propietarios de forma recursiva y no sustituyen
datos de aplicaciones por carpetas vacías. Homebrew instala lo declarado sin
eliminar otros paquetes ni actualizar los existentes por defecto.

## Recuperación y GitHub

- [Recuperar un equipo desde cero](docs/recovery.md)
- [Ejecutar desde GitHub Actions](docs/github-actions.md)
- [Inventario capturado y decisiones](docs/inventory.md)
- [Secretos que deben estar en el gestor de contraseñas](docs/secrets.md)
- [Sincronización CZM2 → Pewter](docs/pewter-sync.md)

Esta es una receta de configuración sobre una instalación del sistema
operativo. Los datos personales, las bases de datos y las licencias se
recuperan de sus copias o proveedores. Las versiones del motor, plugins e
imágenes están fijadas; los paquetes del sistema y Homebrew siguen sus
repositorios, por lo que no hay compilación bit a bit ni generaciones de
rollback como en NixOS. Homebrew [no ofrece lockfiles de versiones](https://docs.brew.sh/Brew-Bundle-and-Brewfile).

## Cambiar la configuración

| Archivo o carpeta | Qué cambiar |
| --- | --- |
| `inventory/host_vars/` | Diferencias entre equipos: usuario, color, discos, LAN y recursos compartidos |
| `inventory/hosts.yml` | Direcciones SSH del sistema, distintas de los nodos embebidos de Rex |
| `brewfile` | Paquetes y aplicaciones del Mac; `brewsync` lo abre y aplica sin podar paquetes |
| `shell/zshrc` | Configuración y funciones comunes del shell |
| `macos/preferences.json` | Preferencias permitidas del Mac; los datos binarios del tema usan base64 |
| `macos/rex-release.yml` | Cliente Rex capturado, con URL y SHA-256 |
| `workloads/bagheera/compose.yaml` | Servicios e imágenes del servidor multimedia |
| `keys/` | Claves públicas de usuario y claves públicas conocidas de los servidores |
| `roles/` | Implementación de la restauración |

Los paquetes Stow originales siguen en el repo; `zsh/.zshrc` carga el shell
común. La restauración administra archivos normales con sus copias de
seguridad y conserva el contenido anterior de `.zshrc` en
`.zshrc.before-dotfiles`. El script anterior `scripts/setup-hirayama.sh`
queda para la migración histórica de `platoa`; el mantenimiento habitual usa
`./dotfiles`.

## Validación

```sh
./tests/run
```

Comprueba la sintaxis de los playbooks y scripts, renderiza los dos perfiles
Samba, verifica que las preferencias del Mac preservan claves ajenas y aplica
el perfil de usuario dos veces en una carpeta temporal. La segunda aplicación
debe producir cero cambios, conservando el contenido y destino del enlace
original. GitHub ejecuta estas comprobaciones sin acceder a los equipos.

Las restauraciones reales desde GitHub son manuales y se ejecutan solo desde
`main`, usando las credenciales de cada entorno. El código no instala runners
persistentes ni configura sudo sin contraseña.

La [configuración de Neovim](nvim/.config/nvim/README.md) conserva la
documentación de Mist. Rex carga [init.lua](rex/.config/rex/init.lua); tras
cambiarlo, ejecutar `rex config check` y `rex config reload` en ese equipo.
