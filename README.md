# Flappy Clone

iOS-клон Flappy Bird, написанный на Swift с использованием SpriteKit. Проект создан как учебный — полная реализация игровой механики с процедурной графикой, физикой и анимациями персонажа.

---

## Стек

| | |
|---|---|
| Язык | Swift 5.0 |
| UI / Игровой движок | SpriteKit + UIKit |
| Минимальная платформа | iOS 26.5 (iPhone и iPad) |
| Ориентация | Portrait only |
| Зависимости | Нет (ни SPM, ни CocoaPods, ни Carthage) |

---

## Структура папок

```
flappyclone/
├── flappyclone.xcodeproj/       # Xcode-проект и настройки сборки
└── flappyclone/
    ├── AppDelegate.swift        # Точка входа приложения
    ├── SceneDelegate.swift      # Управление жизненным циклом окна
    ├── GameViewController.swift # UIViewController, инициализирует SKView и GameScene
    ├── GameScene.swift          # Вся игровая логика: физика, графика, анимации, счёт
    ├── GameScene.sks            # SpriteKit-сцена (редактор сцен Xcode)
    ├── Actions.sks              # SpriteKit-экшены
    ├── Base.lproj/
    │   └── Main.storyboard      # Storyboard с GameViewController
    ├── Assets.xcassets/
    │   ├── AppIcon.appiconset/  # Иконка приложения
    │   └── AccentColor.colorset/
    └── Info.plist               # Конфигурация приложения
```

---

## Требования

- **macOS** с **Xcode 26+** *(требует проверки — минимальная рабочая версия Xcode не задокументирована)*
- iOS-симулятор или физическое устройство на iOS 26.5+
- Apple Developer аккаунт нужен **только** для запуска на реальном устройстве; для симулятора достаточно бесплатного аккаунта

---

## Установка и запуск

Сторонних зависимостей нет — никаких `pod install` или `swift package resolve` не требуется.

**1. Клонировать репозиторий**

```bash
git clone git@github.com:zhurakov/flappyclone.git
cd flappyclone
```

**2. Открыть в Xcode**

```bash
open flappyclone.xcodeproj
```

**3. Выбрать симулятор или устройство и нажать Run (⌘R)**

**Альтернатива — сборка из терминала:**

```bash
xcodebuild \
  -project flappyclone.xcodeproj \
  -scheme flappyclone \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

---

## Игровая механика

- **Старт:** тап по экрану запускает игру
- **Управление:** каждый тап даёт птице импульс вверх
- **Препятствия:** трубы появляются справа с рандомной высотой зазора и движутся влево
- **Счёт:** +1 за каждую пройденную пару труб
- **Рекорд:** сохраняется в `UserDefaults` между сессиями
- **Game Over:** столкновение с трубой или землёй; тап перезапускает игру
- **Анимации птицы:** крыло, реакция на падение (испуг), реакция на частые тапы (пар, румянец)
- **Тактильная отдача:** лёгкий импульс на каждый тап, уведомление об ошибке на game over

---

## Архитектура

```
AppDelegate
  └── SceneDelegate
        └── GameViewController (UIViewController)
              └── SKView
                    └── GameScene (SKScene, SKPhysicsContactDelegate)
                          ├── Bird (SKNode + physics body)
                          ├── Pipes (SKNode-пары, спавнятся по таймеру)
                          ├── Ground (SKShapeNode + physics body)
                          └── UI-лейблы (счёт, сообщения)
```

`GameScene.swift` содержит всю игровую логику. Физические категории объявлены как вложенная структура `PhysicsCategory`. Состояние игры хранится в enum `GameState` (`.startScreen`, `.playing`, `.gameOver`).

---

## Разработка

**Изменить физику птицы** — константы в начале `GameScene.swift`:
- Импульс прыжка: `bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 55))`
- Гравитация: `physicsWorld.gravity = CGVector(dx: 0, dy: -5.5)`

**Изменить сложность** — константы в `GameScene`:
- `pipeGap: CGFloat = 170` — зазор между трубами
- `wait(forDuration: 1.8)` в `startSpawningPipes()` — интервал появления труб
- Скорость движения труб: `duration: 4.0` в `spawnPipePair()`

**Добавить новую сцену** — создать новый `SKScene`-подкласс, презентовать его через `view.presentScene(_:transition:)` из `GameViewController` или `GameScene`.

---

## Переменные окружения

Не используются. Проект не содержит `.env`-файлов, конфигурационных схем по окружению или feature-флагов.

---

## Известные ограничения / TODO

- **Нет звука** — `AVFoundation` и `SKAudioNode` в коде отсутствуют *(требует проверки)*
- **Нет прогрессии сложности** — скорость труб и размер зазора постоянны на протяжении всей игры
- **Нет тестов** — ни unit, ни UI
- **Нет CI/CD**
- **`GCC_OPTIMIZATION_LEVEL = 0`** — оптимизация отключена в конфигурации Release *(требует проверки — возможно намеренно для отладки)*
- **Одна сцена** — нет экрана настроек, меню или таблицы рекордов
