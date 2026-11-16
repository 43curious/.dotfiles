# Secretos y datos fuera de Git

El gestor habitual es la fuente para recuperar credenciales. El repo solo
lleva claves públicas, UUID, preferencias seleccionadas y configuración.
`.local/`, `secrets/` y `backups/` están ignorados.

| Entrada en el gestor | Se necesita para |
| --- | --- |
| Clave privada SSH del Mac y su contraseña | Acceder a servidores y GitHub después de perder el Mac |
| Contraseña de administrador de cada equipo | Aplicar paquetes, montajes y servicios con sudo |
| Contraseña SMB de `jon` en cada servidor | Crear el acceso Samba en una instalación nueva |
| Acceso a GitHub y recuperación MFA | Obtener el repo y administrar Actions |
| Cuenta Tailscale y recuperación MFA | Autorizar equipos y crear el cliente OAuth de CI |
| Clave privada dedicada de GitHub Actions | Secret `DOTFILES_SSH_KEY`, distinto de la clave personal |
| Cliente y secreto OAuth de Tailscale para CI | `TS_OAUTH_CLIENT_ID` y `TS_OAUTH_SECRET` |
| Licencias y cuentas de Adobe, Apple, Resolve, etc. | Recuperar las aplicaciones del Mac |

Consultar las contraseñas en el gestor cuando hagan falta. No escribirlas en
archivos versionados ni como argumentos visibles. En uso interactivo, sudo y
`smbpasswd` pueden pedirlas directamente.

## Datos que requieren una copia aparte

| Equipo | Qué recuperar |
| --- | --- |
| Kleya | Proyectos `~/Dev`, notas, documentos, Zotero, bibliotecas de audio/vídeo, bases de datos de Resolve, presets y LUTs |
| Bagheera | `/srv/copper/media`, `/srv/copper/docker/jellyfin`, `/srv/copper/docker/qbittorrent` y `/srv/pewter` |
| Hirayama | Contenido de `/srv/imac-plato` |

El caché `/srv/copper/docker/transcode` se puede recrear vacío después de
verificar el montaje. Las otras carpetas de estado necesitan su copia válida.
Las bases de datos y configuraciones internas pueden contener tokens: su
copia debe ser privada y cifrada, separada de este repositorio.

Este cambio captura la receta; no crea ni verifica una copia externa de esos
datos. Confirmar que existe una copia fuera del disco original y ensayar su
restauración. Sincronizar con Pewter no conserva versiones históricas ni
protege frente a perder ambos discos.
