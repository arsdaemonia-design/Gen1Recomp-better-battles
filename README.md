# 🥊 Better Battles — Gen1Recomp Mod

[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](https://github.com/arsdaemonia-design/Gen1Recomp-better-battles/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[Español](#español) | [English](#english)

---

## Español

**Better Battles** es una suite integral de mejoras de interfaz y calidad de vida (QoL) para las batallas de Pokémon Red/Blue en **Gen1Recomp**. Introduce funciones inspiradas en las generaciones modernas de Pokémon (indicadores de tipo estilo Johto, ventaja en equipo, indicadores de efectividad de ataques, acceso rápido a objetos, Pokébola de captura y gradientes animados de estado) manteniendo la estética fiel del Game Boy y soporte completo para modo 2D Clásico y Voxel 3D.

---

### ✨ Características

#### 1. 🎨 Better Status (Gradientes de Estado)
Reemplaza el texto estático de estado (`PSN`, `BRN`, `PAR`, `FRZ`, `SLP`) con efectos configurables individualmente:
- **STATUS TEXT**: Texto flotante animado sobre el sprite del Pokémon afectado, con colores por tipo de estado.
- **STATUS OVERLAY**: Degradado de color brillante en la barra de HP que refleja visualmente el estado activo.

#### 2. 🔴 Caught Indicator (Indicador de Captura)
Muestra un **icono de Pokébola** al lado del nombre del Pokémon salvaje si ya lo tienes registrado en tu Pokédex.
- Estilo clásico rojo o monocromático gris (configurable).

#### 3. ⚡ Quick Item (Menú Rápido de Objetos)
Presiona **← Flecha Izquierda** durante el menú de batalla para abrir un selector rápido de:
- **Pokébolas** — se lanzan directamente sin abrir la mochila (solo en encuentros salvajes).
- **Pociones** — curan al Pokémon activo instantáneamente sin abrir el menú de equipo.
- Navega con **↑↓** entre categorías y **←→** entre objetos.
- El menú se muestra **por encima** del menú de batalla, sin solaparse con él.

#### 4. 🟦 Type Badges (Indicadores de Tipo)
Muestra **iconos de tipo nítidos** al lado del nivel de cada Pokémon en batalla, indicando su(s) tipo(s).
- Inspirado en los iconos de tipo de Pokémon Gold/Silver.
- Usa los **15 tipos reales de la Generación 1** (con color de respaldo si falta la imagen).
- Se renderizan a resolución de ventana, tanto en modo clásico como en **Voxel 3D**.

#### 5. ⚔️ Effective Markers & Party Advantage
Muestra la efectividad de los ataques y ventajas de equipo (inspirado en Pokémon Switch):
- **Battle Markers**: Al seleccionar un ataque, muestra un icono verde (Súper Efectivo), gris (Sin Efecto) o rojo (Poco Efectivo).
- **Best Move Suggestion**: Un **cuadrado dorado pulsante** resalta el movimiento con el mejor daño esperado (potencia × efectividad).
- **STAB Highlight**: Los ataques que comparten tipo con tu Pokémon reciben un **brillo dorado y pulso animado**.
- **Party Advantage**: Al abrir tu Mochila de Equipo en batalla, un **triángulo verde brillante (▲)** aparecerá dinámicamente junto a los Pokémon que tengan ataques súper efectivos contra el enemigo actual. ¡Brilla en dorado si el ataque tiene STAB!

---

### 📜 Changelog v1.2.0

- **Fix crítico**: Se corrigió un cierre de juego al enfrentar Pokémon de tipo **Psíquico** (ej. Abra). El ID interno del tipo en los datos es `PSYCHIC_TYPE` (nombre visible "PSYCHIC"), por lo que la búsqueda del icono devolvía `nil` y causaba un error. Ahora los tipos se normalizan con `TypeChart.displayName`.
- **Fix**: `getScaledIcon(...).w` ya no intenta leer `nil` si falta un icono (usa el cuadrito de color como respaldo).
- **Removido**: Se eliminó el multiplicador numérico (×0 / ×1 / ×2 / ×.5 / ×.25) junto al marcador para simplificar la interfaz.
- **Nuevo**: Log de errores del mod — si algo falla en el dibujo, escribe `better-battles.log` en la carpeta de guardado (y no cierra la partida sin avisar).

---

### 🎨 Tabla de Colores de Tipo

Los cuadritos de tipo usan los siguientes colores para identificar cada tipo de la Generación 1:

| Color | Tipo | Ejemplo |
|:-----:|------|---------|
| 🟫 | **NORMAL** | Rattata, Chansey, Snorlax |
| 🔴 | **FIRE** | Charmander, Vulpix, Arcanine |
| 🔵 | **WATER** | Squirtle, Lapras, Gyarados |
| 🟡 | **ELECTRIC** | Pikachu, Voltorb, Jolteon |
| 🟢 | **GRASS** | Bulbasaur, Oddish, Exeggutor |
| 🩵 | **ICE** | Articuno, Jynx, Lapras |
| 🟤 | **FIGHTING** | Machop, Hitmonlee, Hitmonchan |
| 🟣 | **POISON** | Ekans, Nidoran, Grimer |
| 🟠 | **GROUND** | Diglett, Cubone, Sandshrew |
| 🔹 | **FLYING** | Pidgey, Spearow, Aerodactyl |
| 💗 | **PSYCHIC** | Abra, Drowzee, Mewtwo |
| 🟩 | **BUG** | Caterpie, Scyther, Pinsir |
| 🪨 | **ROCK** | Geodude, Onix, Aerodactyl |
| 👻 | **GHOST** | Gastly, Haunter, Gengar |
| 💜 | **DRAGON** | Dratini, Dragonair, Dragonite |

> **Nota:** Pokémon con dos tipos muestran dos cuadritos lado a lado.  
> Ejemplo: Pidgey = 🟫🔹 (Normal + Flying)

---

### ⚙️ Configuración

Todas las funciones se pueden activar/desactivar individualmente:

1. En el menú principal, ve a **OPCIONES**
2. Selecciona **BETTER BATTLES**
3. Usa ←→ para cambiar entre `ON` / `OFF`:
   - `STATUS TEXT` — Texto flotante de estado
   - `STATUS OVERLAY` — Gradientes de color en la barra de vida
   - `CAUGHT POKEBALL` — Indicador de captura
   - `BALL COLOR` — Color de la pokébola indicadora (RED / GREY)
   - `QUICK ITEM BTN` — Menú rápido de objetos
   - `TYPE BADGES` — Cuadritos de tipo
   - `EFFECTIVE MARKERS` — Marcadores de efectividad y STAB

---

### 📦 Instalación

1. Descarga el archivo `.zip` de la sección de **Releases**.
2. Coloca el archivo `.zip` directamente dentro de la carpeta `mods/` de Gen1Recomp (o arrástralo a la ventana del juego).
3. Gen1Recomp detectará e instalará el archivo `.zip` automáticamente.

---

---

## English

**Better Battles** is a comprehensive battle UI and quality-of-life (QoL) enhancement suite for Pokémon Red/Blue in **Gen1Recomp**. It introduces features inspired by modern Pokémon games (Johto-style type badges, Party Advantage, move effectiveness markers, quick item access, caught Pokeball indicator, and animated status gradients) while preserving the authentic Game Boy aesthetic and fully supporting both 2D Classic and Voxel 3D modes.

---

### ✨ Features

#### 1. 🎨 Better Status (Status Gradients)
Replaces static status text (`PSN`, `BRN`, `PAR`, `FRZ`, `SLP`) with individually configurable effects:
- **STATUS TEXT**: Animated floating text above the affected Pokémon sprite, color-coded by status type.
- **STATUS OVERLAY**: Color gradient on the HP bar visually reflecting the active status condition.

#### 2. 🔴 Caught Indicator
Displays a **Pokéball icon** next to wild Pokémon names if already registered in your Pokédex.
- Classic red or monochrome grey style (configurable).

#### 3. ⚡ Quick Item Menu
Press **← Left Arrow** during the battle menu to open a quick selector for:
- **Pokéballs** — thrown directly without opening the bag (wild battles only).
- **Potions** — heals active Pokémon instantly without opening the party menu.
- Navigate with **↑↓** between categories and **←→** between items.
- The menu is drawn **above** the battle menu, without overlapping it.

#### 4. 🟦 Type Badges
Displays **crisp type icons** next to each Pokémon's level indicator in battle showing its type(s).
- Inspired by Pokémon Gold/Silver type badges.
- Uses the **15 real Generation 1 types** (with a color fallback if the image is missing).
- Rendered at window resolution, supporting both Classic 2D and **Voxel 3D** modes.

#### 5. ⚔️ Effective Markers & Party Advantage
Displays move effectiveness and party advantages (inspired by modern Switch Pokémon games):
- **Battle Markers**: When selecting a move, shows a green (Super Effective), grey (No Effect), or red (Not Very Effective) icon.
- **Best Move Suggestion**: A **pulsing golden square** highlights the move with the best expected damage (power × effectiveness).
- **STAB Highlight**: Moves that share a type with your Pokémon gain a **gold border and animated pulse** highlighting maximum power.
- **Party Advantage**: When opening the Party Menu in battle, a **bright green triangle (▲)** appears dynamically next to Pokémon that have a super-effective move against the current enemy. It glows GOLD if the move has STAB!

---

### 📜 Changelog v1.2.0

- **Critical fix**: Fixed a crash (game closing) when facing **Psychic**-type Pokémon (e.g. Abra). The game's internal type ID is `PSYCHIC_TYPE` (display name "PSYCHIC"), so the badge lookup returned `nil` and errored. Types are now normalized via `TypeChart.displayName`.
- **Fix**: `getScaledIcon(...).w` no longer dereferences `nil` when an icon is missing (falls back to the color square).
- **Removed**: The numeric multiplier (×0 / ×1 / ×2 / ×.5 / ×.25) next to the marker, to keep the UI simpler.
- **New**: Mod error log — if a drawing error occurs, it writes `better-battles.log` to the save folder (and no longer silently closes the game).

---

### 🎨 Type Color Reference Table

| Color | Type | Example |
|:-----:|------|---------|
| 🟫 | **NORMAL** | Rattata, Chansey, Snorlax |
| 🔴 | **FIRE** | Charmander, Vulpix, Arcanine |
| 🔵 | **WATER** | Squirtle, Lapras, Gyarados |
| 🟡 | **ELECTRIC** | Pikachu, Voltorb, Jolteon |
| 🟢 | **GRASS** | Bulbasaur, Oddish, Exeggutor |
| 🩵 | **ICE** | Articuno, Jynx, Lapras |
| 🟤 | **FIGHTING** | Machop, Hitmonlee, Hitmonchan |
| 🟣 | **POISON** | Ekans, Nidoran, Grimer |
| 🟠 | **GROUND** | Diglett, Cubone, Sandshrew |
| 🔹 | **FLYING** | Pidgey, Spearow, Aerodactyl |
| 💗 | **PSYCHIC** | Abra, Drowzee, Mewtwo |
| 🟩 | **BUG** | Caterpie, Scyther, Pinsir |
| 🪨 | **ROCK** | Geodude, Onix, Aerodactyl |
| 👻 | **GHOST** | Gastly, Haunter, Gengar |
| 💜 | **DRAGON** | Dratini, Dragonair, Dragonite |

> **Note:** Dual-type Pokémon display two squares side by side.  
> Example: Pidgey = 🟫🔹 (Normal + Flying)

---

### ⚙️ Configuration

All features can be toggled individually:

1. Open the main menu and go to **OPTIONS**.
2. Select **BETTER BATTLES**.
3. Use ←→ to switch between `ON` / `OFF`:
   - `STATUS TEXT` — Floating status text above sprite
   - `STATUS OVERLAY` — Status color gradient on HP bar
   - `CAUGHT POKEBALL` — Caught Pokeball indicator
   - `BALL COLOR` — Pokeball indicator color (RED / GREY)
   - `QUICK ITEM BTN` — Quick item selection menu
   - `TYPE BADGES` — Type badges
   - `EFFECTIVE MARKERS` — Move effectiveness markers and STAB

---

### 📦 Installation

1. Download the `.zip` release file from **Releases**.
2. Place the `.zip` file directly inside the `mods/` directory of Gen1Recomp (or drag and drop it into the game window).
3. Gen1Recomp will automatically detect and load the `.zip` mod file.

---

## 🔧 Compatibility

- ✅ Classic 2D Mode
- ✅ Voxel 3D Mode
- ✅ Wide Layout Mode
- ✅ Compatible with `quality_of_life` mod

---

## 📄 License

MIT — Free to use and modify.

---

*Made with ❤️ by arsdaemonia-design*
