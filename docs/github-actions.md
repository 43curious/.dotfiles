# Orquestación desde GitHub

**Check dotfiles**, sin credenciales, valida cada cambio. **Restore machines**
ejecuta manualmente `plan`, `apply` o `check` sobre un equipo, los servidores
o los tres equipos. Solo despliega desde `main`.

## Preparación inicial desde el Mac

1. Crear una clave de despliegue independiente:

   ```sh
   ./scripts/github-key
   ```

   La privada queda en `.local/github-actions_ed25519` y la pública en
   `keys/github-actions.pub`. Copiar la privada al gestor y a GitHub; solo
   la pública se añade al commit.
2. Desbloquear la clave personal y aplicar los perfiles para autorizar esa
   nueva clave pública, sin borrar las existentes:

   ```sh
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
   ./dotfiles apply bagheera
   ./dotfiles apply hirayama
   ./dotfiles apply kleya --local
   ```

3. En GitHub → Settings → Environments, crear `bagheera`, `hirayama` y
   `kleya`. Guardar en cada uno:

   | Secret | Contenido |
   | --- | --- |
   | `DOTFILES_SSH_KEY` | La clave privada dedicada, sin contraseña |
   | `DOTFILES_BECOME_PASSWORD` | Contraseña de sudo de ese equipo |
   | `DOTFILES_SMB_PASSWORD` | Opcional, contraseña SMB para instalaciones nuevas |

   Los entornos permiten contraseñas distintas y revisores de despliegue.
   No se configura ejecución arbitraria de sudo sin contraseña.
4. Crear un cliente OAuth de Tailscale con escritura de claves de autenticación
   y `tag:ci`. Guardar en los secrets del repo `TS_OAUTH_CLIENT_ID` y
   `TS_OAUTH_SECRET`.
5. En la política del tailnet, permitir que `tag:ci` llegue al puerto TCP 22
   de los tres nodos del sistema. El workflow usa un nodo efímero y espera a
   que el destino responda. No usar los nodos embebidos de Rex para SSH.
6. Revisar `keys/known_hosts`. Las claves públicas de ambos servidores se
   capturaron a través de Rex. Para Actions en el Mac, habilitar **Remote
   Login** para `jcastro`, leer desde ese Mac su clave pública de host y
   añadir la entrada de `kleya.mau-skate.ts.net`. Debe estar encendido,
   despierto y autorizado en Tailscale.
7. Subir los commits revisados. En Actions → Restore machines, ejecutar
   primero `plan`, después `apply` y finalmente `check` sobre el mismo perfil.

Sin los secrets, la política de Tailscale o Remote Login en el Mac, el
workflow no puede desplegar. El repo no cambia esas cuentas ni publica
claves privadas. No hay runners persistentes dentro de los equipos y las
operaciones de un mismo perfil no se solapan.

La [acción oficial de Tailscale](https://github.com/tailscale/github-action)
documenta OAuth, tags y el nodo efímero. Las acciones, el motor y las
colecciones de Ansible están fijados a referencias concretas.
