# Inventario capturado el 16 de noviembre de 2026

Se revisaron el Mac local y ambos servidores mediante Rex. Se tomaron
configuraciones de usuario e identidades de discos; no se copiaron claves
privadas ni bases de datos de aplicaciones.

| Equipo | Sistema observado | SSH del sistema | Rex observado |
| --- | --- | --- | --- |
| Kleya | macOS 26.5.2, Apple Silicon | `kleya.mau-skate.ts.net` | `kleya-1.mau-skate.ts.net` |
| Bagheera | Fedora 43 Server | `bagheera.mau-skate.ts.net` | `bagheera-1.mau-skate.ts.net` |
| Hirayama | Debian 13 trixie | `hirayama.mau-skate.ts.net` | `hirayama-1.mau-skate.ts.net` |

## Discos de datos

| Equipo | Disco | UUID | Montaje | Tipo |
| --- | --- | --- | --- | --- |
| Bagheera | Copper, 1 TB | `e18f0346-d6a6-4422-8264-8ae3b746379c` | `/srv/copper` | ext4 |
| Bagheera | Pewter, 2 TB | `215bf63e-31a5-4080-9ca5-5b734fe071fe` | `/srv/pewter` | XFS |
| Hirayama | iMac Plato, 1 TB | `7d3c1de4-00ab-4120-9b9a-7feccf2fbac6` | `/srv/imac-plato` | ext4 |

El instalador del SO administra los discos de sistema, arranque y swap. No
se trasplantan sus UUID a una reinstalación.

## Configuraciones recogidas

- Los CLI declarados del Mac coincidían con Homebrew. Los nombres y versiones
  de las aplicaciones se guardan en `macos/applications.json`.
- macOS: atajos simbólicos, fuentes de entrada seleccionadas, gestos del
  trackpad integrado/Bluetooth y preferencias de Finder y Dock, sin copiar
  dominios completos que puedan contener sesiones o documentos recientes.
- Rex: tema Dark+, SF Mono a 23 puntos, cursor de bloque,
  paneles, pestañas y atajos. Se excluyeron sesión enfocada, actividad,
  geometría y datos de confianza. El archivo `macos/rex-release.yml` conserva
  la URL y el hash del instalador Mac build 1973.
- Servidores: prompts, colores, atajos, historial, Samba, montajes, servicios
  de Rex y las preferencias explícitas de interfaz e idioma de dconf. No se
  exportó toda la base de dconf.
- Neovim del Mac es 0.12.6; su configuración y lockfile de plugins están
  guardados en `nvim/`.
- Bagheera: Compose activo de `/home/jon/compose.yaml`, rutas de estado y
  digests de las dos imágenes, incluida qBittorrent 5.2.4. Se conservan
  puertos, modos de red y rutas de datos en `workloads/bagheera/compose.yaml`.

## Configuración conservada

La cuenta institucional y contraseñas se recuperan por sus procedimientos.
Los servidores conservan UID/GID 1000. Hirayama conserva `/home/platoa` con
usuario `jon`; revisar esa ruta al preparar otra instalación si se quiere
`/home/jon`.

Los paquetes Stow y el `.zshrc` original se mantienen como configuración
principal. Las preferencias capturadas y el Compose son archivos independientes
que pueden reutilizarse en los próximos scripts de Bash.
