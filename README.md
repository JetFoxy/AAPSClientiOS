# AAPSClient iOS

Нативный iOS-клиент (follower) для AndroidAPS через Nightscout (API v3). Мониторинг петли AAPS
+ удалённые действия-записи (carbs, temp target, переключение профиля, care-события,
управление петлёй) через Nightscout. Болюс не поддерживается (вне модели NS).

## Стек
- Swift / SwiftUI, iOS 16+
- Проект генерируется **xcodegen** из `project.yml` (сам `.xcodeproj` в .gitignore)

## Сборка
```bash
xcodegen generate
xcodebuild -project AAPSClientiOS.xcodeproj -scheme AAPSClientiOS \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates build
```

## Документация
- `docs/2026-06-15-aapsclient-ios-port-design.md` — дизайн-спека
- `docs/2026-06-15-aapsclient-ios-port-plan.md` — план реализации (раунды R1–R11)
- `docs/contracts/nightscout-v3-contract.md` — контракт Nightscout API v3 (auth, чтение,
  запись действий) + фикстуры в `docs/contracts/fixtures/`

## Архитектура
Послойная: `NightscoutClient` (NS v3, парсинг через `JSONSerialization` — НЕ `JSONDecoder`)
→ `DomainModel` → `AppStore` → SwiftUI. Сбоку: `NsTreatmentWriter`, `AlarmEngine`,
`BackgroundScheduler`.
