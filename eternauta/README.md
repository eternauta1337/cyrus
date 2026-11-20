# El fork de Cyrus de eternauta1337

Cyrus de [cyrusagents/cyrus](https://github.com/cyrusagents/cyrus) con unos pocos arreglos propios. La
rama es **`eternauta`**: los tags de arriba (`v0.2.83`, …) más un commit por parche, cada uno con su
prueba. Lo usan todos los Cyrus de Ale (archi, macmini, la VM de Azul) y Rubencito.

## Los parches

| commit | qué arregla | arriba |
|---|---|---|
| `CYRUS_HOME_SIN_LIMITES=1` turns off home directory restrictions | con esa variable en el servicio, Claude no tiene restricciones de lectura sobre el home. Sin la variable, Cyrus se porta como siempre | no hay opción equivalente |
| access check uses the message author on prompted webhooks | el control de acceso mira al autor del mensaje, no al creador de la sesión. Antes, una sesión creada por un agente quedaba bloqueada para todos | sin reportar |
| clear a stale stop flag when a session is resumed | después de frenar una sesión, la próxima respuesta se publica en Linear. Antes se la comía la marca de freno | [#1389](https://github.com/cyrusagents/cyrus/issues/1389) |
| `CYRUS_CLAUDE_SIN_USER_SETTINGS=1` skips the user's Claude settings | con esa variable, Claude no carga los settings del usuario de la máquina (plugins, MCP, permisos de `~/.claude`), pero sigue usando su credencial. Para cuando la cuenta de la máquina es de una persona. Viene de Rubencito | no hay opción |
| `CYRUS_CONTEXT_FILE` appended to the system prompt | el contenido de ese archivo se suma al prompt de sistema de cada sesión nueva, de cualquier motor. Se relee en cada sesión, sin reiniciar. Viene de Rubencito | `customSystemInstructions` (0.2.80) es texto fijo de hasta 8000 caracteres |

Todo lo que cambia está marcado con un comentario `eternauta:` en el código, y las pruebas están en
`packages/*/test/eternauta-*.test.ts`. Cuando arriba arregle algo, se saca el commit.

## Instalar

```
git clone https://github.com/eternauta1337/cyrus ~/cyrus && cd ~/cyrus && git checkout eternauta
eternauta/instalar.sh                      # en ~/.local/cyrus
eternauta/instalar.sh --prefix /opt/cyrus  # en otro lado
```

Instala con el mismo layout que `npm install -g --prefix … cyrus-ai`, así que el servicio que corre
`<prefix>/bin/cyrus` no cambia. Después hay que reiniciarlo **enseguida**: entre que se instala y se reinicia, el Cyrus que sigue corriendo tiene los archivos cambiados abajo y las sesiones que arrancan fallan (pasó el 20/11 con `Native CLI binary … not found`). `<prefix>/lib/node_modules/cyrus-ai/ETERNAUTA`
dice qué commit del fork está instalado, y la instalación anterior queda en `cyrus-ai.anterior`.

## Actualizar a una versión nueva de arriba

```
cd ~/cyrus
git fetch upstream --tags
git rebase --onto v0.2.84 v0.2.83 eternauta   # la base vieja y la nueva
env -u CYRUS_HOME_SIN_LIMITES pnpm --filter cyrus-edge-worker --filter cyrus-claude-runner exec vitest run
git push --force-with-lease origin eternauta
eternauta/instalar.sh
```

Si un commit choca, se resuelve a mano. Si arriba ya lo arregló, se descarta el commit.
