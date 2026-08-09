# 🥊 Better Battles — Gen1Recomp Mod

Mejora de batallas para el port **Gen1 Recompilation Project** de Pokémon Red/Blue.  
Añade funciones de calidad de vida (QoL) que los juegos modernos introdujeron en generaciones posteriores, directamente en la Generación 1.

---

## ✨ Características

### 1. 🎨 Better Status (Gradientes de Estado)
Reemplaza el texto estático de estado (`PSN`, `BRN`, `PAR`, `FRZ`, `SLP`) con:
- **Texto flotante animado** sobre el sprite del Pokémon afectado, con colores por tipo de estado.
- **Degradado de color** en la barra de HP que refleja visualmente el estado activo.

### 2. 🔴 Caught Indicator (Indicador de Captura)
Muestra un **icono de Pokébola** al lado del nombre del Pokémon salvaje si ya lo tienes registrado en tu Pokédex.
- Estilo clásico rojo o monocromático gris (configurable).

### 3. ⚡ Quick Item (Menú Rápido de Objetos)
Presiona **← Flecha Izquierda** durante el menú de batalla para abrir un selector rápido de:
- **Pokébolas** — se lanzan directamente sin abrir la mochila (solo en encuentros salvajes).
- **Pociones** — curan al Pokémon activo instantáneamente sin abrir el menú de equipo.
- Navega con **↑↓** entre categorías y **←→** entre objetos.

### 4. 🟦 Type Badges (Indicadores de Tipo)
Muestra **cuadros de color** al lado del nivel de cada Pokémon en batalla, indicando su(s) tipo(s).
- Inspirado en los iconos de tipo de Pokémon Gold/Silver.
- Funciona tanto en modo clásico como en **Voxel 3D**.

---

## 🎨 Tabla de Colores de Tipo

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

## ⚙️ Configuración

Todas las funciones se pueden activar/desactivar individualmente:

1. En el menú principal, ve a **OPCIONES**
2. Selecciona **BETTER BATTLES**
3. Usa ←→ para cambiar entre `ON` / `OFF`:
   - `BETTER STATUS` — Gradientes y texto flotante de estado
   - `CAUGHT POKEBALL` — Indicador de captura
   - `BALL COLOR` — Color de la pokébola indicadora (RED / GREY)
   - `QUICK ITEM BTN` — Menú rápido de objetos
   - `TYPE BADGES` — Cuadritos de tipo

---

## 📦 Instalación

1. Descarga la carpeta `better-battles/`
2. Colócala en `mods/` dentro del directorio de Gen1Recomp
3. Reinicia el juego
4. ¡Disfruta de batallas mejoradas!

---

## 📋 Estructura del Mod

```
better-battles/
├── manifest.json              # Metadatos del mod (v1.0.0)
├── main.lua                   # Punto de entrada, menú de opciones
├── feature_status_ui.lua      # Gradientes y texto flotante de estado
├── feature_caught_indicator.lua # Pokébola de captura
├── feature_quick_item.lua     # Menú rápido de objetos
├── feature_type_badges.lua    # Cuadritos de tipo
└── assets/
    └── types.png              # Asset de referencia (no utilizado en runtime)
```

---

## 🔧 Compatibilidad

- ✅ Modo Clásico (2D)
- ✅ Modo Voxel 3D
- ✅ Modo Wide Layout
- ✅ Compatible con el mod `quality_of_life`

---

## 📄 Licencia

MIT — Uso libre, modifica como quieras.

---

*Hecho con ❤️ por arsdaemonia-design*
