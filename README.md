# 🐾 Feral_One_Lite *GP* v1.0 - La Rotación simplificada ---- by Holle (SouthSeas server)

Feral_One es un asistente de rotación inteligente para Druidas Ferales en Turtle WoW (1.12.1). Está diseñado para maximizar el flujo de energía mediante Reshift Dinámico, permitiendo que el jugador se concentre en la estrategia mientras el addon optimiza el gasto de energía.

🚀 Características Principales
⚙️ Sistema de Marchas(Gears): Cambia entre P1, P2 y Neutral (N) para ajustar los umbrales de reshift según tu regeneración de maná.

🛡️ Detección de Inmunidad y clearcasting: Cambia automáticamente a "Claw" si detecta que el objetivo es inmune a sangrados, si detecta un proc de clarcasting prioriza shred para mas daño!

⚡ Modo Turbo (Berserk): Optimiza la rotación durante Berserk. En este modo, no se utiliza Tiger's Fury para evitar conflictos lógicos y maximizar el DPS mediante el uso agresivo de Reshift.

🎯 Cruz Visual: Mira dinámica que cambia de color según la actitud del objetivo (Hostil/Amistoso).

🧠 Filosofía de Juego (Decisiones del Jugador)
No es un Addon "1-button", Feral_One busca que el jugador mantenga el control sobre habilidades clave:

🚫 Sin Rip ni Faerie Fire: El addon no automatiza estas habilidades. El jugador debe decidir cuándo aplicar el debuff de armadura o cuándo priorizar el sangrado de Rip sobre un finish move como Ferocius Bite.

🐯 Tiger's Fury: Automatizado en Gear neutral y Gear p1, pero desactivado en Turbo y p2 para priorizar el spam de Shred/Claw/Shred y el flujo de energía puro.

⌨️ Comandos Rápidos
/fo help - Guía rápida in-game.

/fo status - Revisa umbrales y estado del modo Turbo.

/fo p1 / p2 / n - Gestión de marchas de combate.

---------------------------------------------------------------

El usuario debe crear 3 macros para el correcto funcionamiento del Addon

primer macro: 
  /startattack
  /run DoFeralRotation("trash") 
**el macro optimizado para limpiar trash, clearcasting liberado para claw o rake**

segundo macro:
  /startattack
  /run DoFeralRotation("boss")
**el macro optimiazado para peleas contra boses, clearcasting restringido unicamente a Shred**

tercer macro:
  /fo cycle
**el macro para funcionar como caja de cambios, alterna entre N, p1, p2**

---------------------------------------------------------------


Ahora si ese gato correra en el grand prix como los grandes :D

https://youtu.be/Y01y15wkT48

