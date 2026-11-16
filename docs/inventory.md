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

- Los CLI declarados del Mac coincidían con Homebrew. Las aplicaciones GUI
  estaban instaladas fuera de él; se añadieron casks para las recuperables y
  se registraron nombres y versiones en `macos/applications.json`.
- macOS: atajos simbólicos, fuentes de entrada seleccionadas, gestos del
  trackpad integrado/Bluetooth y preferencias de Finder y Dock, sin copiar
  dominios completos que puedan contener sesiones o documentos recientes.
- Rex: Dark+ migrado de Ghostty, SF Mono a 23 puntos, cursor de bloque,
  paneles, pestañas y atajos. Se excluyeron sesión enfocada, actividad,
  geometría y datos de confianza. Se fija el cliente Mac build 1973 por hash.
  En Linux se usa el instalador oficial y su repositorio nativo `preview`
  cuando Rex falta; un binario ya instalado se conserva.
- Ghostty: el enlace existente apuntaba a una carpeta ausente. Se reconstruyó
  el archivo desde el tema y tipografía conservados en Rex; no se afirma
  haber recuperado el original perdido.
- Servidores: prompts, colores, atajos, historial, Samba, montajes, servicios
  de Rex y las preferencias explícitas de interfaz e idioma de dconf. No se
  exportó toda la base de dconf.
- Neovim del Mac es 0.12.6. Los servidores usan ese release oficial verificado
  por SHA-256 en `/opt/neovim`, evitando que el Neovim anterior de Debian 13
  impida cargar la configuración actual de LazyVim.
- Bagheera: Compose activo de `/home/jon/compose.yaml`, rutas de estado y
  digests de las dos imágenes, incluida qBittorrent 5.2.4. Se conservan
  puertos y modos de red; se añade el arranque detrás del disco.

## Organización

Ansible evita construir otro gestor de instalación, comparación de archivos
y ejecución SSH. `dotfiles` ofrece perfiles y operaciones; las diferencias
viven en el inventario y la implementación en roles compartidos.

La cuenta institucional y contraseñas se recuperan por sus procedimientos.
Los servidores conservan UID/GID 1000. Hirayama conserva `/home/platoa` con
usuario `jon`; ajustar ese valor al preparar otra instalación si se quiere
`/home/jon`.

Se conservan los paquetes Stow anteriores, con un shell común y copias de
seguridad. Los paquetes se instalan de forma aditiva. Los plugins e imágenes
cambian mediante referencias revisadas en Git, sin seguir `latest` durante
la recuperación.
