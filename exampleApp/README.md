# Шаблон проекта
## Цель
Быстро создавать новый проект с базовыми настройками, компонентами и основными решениями, а не тащить со всех проектов по чуть-чуть.

## Быстрая навигация
- [Создание проекта по шаблону](#cоздание-проекта-по-шаблону)
- [Генерация тестового проекта](#генерация-тестового-проекта)
- [Завершение настройки шаблона](#завершение-настройки-шаблона)

### Создание проекта по шаблону
1. Склонировать репозиторий
    - https: `git clone https://mobileup.gitlab.yandexcloud.net/mobileup/mobileup/development-ios/projects/template-from-ios-16` 
    - ssh: `git clone git@mobileup.gitlab.yandexcloud.net:mobileup/mobileup/development-ios/projects/template-from-ios-16.git`
2. Установить [XcodeGen](https://github.com/yonaskolb/XcodeGen#installing]) (в консоли `brew install xcodegen`)
3. Сменить название папки `Template-from-ios-16` на название проекта (в консоли `mv template-from-ios-16 <Project Name>`)
4. Открыть папку проекта (в консоли `cd <Project Name>`)
5. Запустить файл `rename` (в консоли `sh rename`):
    1. Задать имя проекта
    2. Задать имя таргета. 
    3. Файл `rename` самоуничтожится
6. Поменять название приложения в файлах конфигурации. Файлы лежат в директории Source/Configs, переменная APP_DISPLAY_NAME.
7. Запустить файл `generate` (в консоли `sh generate`), будет создан файл `.xcodeproj`
8. Сменить текущий репозиторий на репозиторий проекта (в консоли `git remote set-url <remote_name> <remote_url>`)
9. Удалить скрипт `testGenerate.sh`
10. Открыть `.xcodeproj` и начать коммитить

### Генерация тестового проекта
Тестовый проект нужен для отладки и добавления нового функционала в шаблон
1. Выполнить пункт 1 из "Создание проекта по шаблону"
2. Запустить скрипт в консоли `sh testGenerate` для генерации `Example.xcodeproj`
3. Открыть `Example.xcodeproj`

### Завершение настройки шаблона
После создания шаблона нужно удалить в этом файле всё до раздела **"Основная информация по проекту"**

# Основная информация по проекту

## Быстрая навигация
- [Файл проекта](#файл-проекта)
- [Настройка версии приложения](#настройка-версии-приложения)
- [Архитектура](#архитектура)
  - [Шаблон модуля](#шаблон-модуля)
- [Конфигурации](#конфигурации)
- [Ресурсы](#ресурсы)
  - [Иконки](#иконки)
  - [Цвета](#цвета)
  - [Шрифты](#шрифты)
  - [Строки](#строки)
- [Навигация](#навигация)
  - [TabBar](#tabbar)
  - [NavigationBar](#navigationbar)
  - [Routers](#routers)
    - [NavigationRouter](#navigationrouter)
    - [PresentationRouter](#presentationrouter)
    - [RootRouter](#rootrouter)
    - [TabBarRouter](#tabbarrouter)
- [Обработка ошибок](#обработка-ошибок)
- [Bottom sheet](#bottom-sheet)
    - [Один боттом шит](#пример-использования-одного-боттом-шита)
    - [Несколько боттом шитов](#пример-использования-нескольких-боттом-шитов)
    - [Кастомизация фона выше ботомшита](#кастомизация-фона-выше-ботомшита)
- [Алерты](#алерты)
- [Тосты](#тосты)
- [Skeleton](#skeleton)
- [Работа с датами](#работа-с-датами)
- [Aналитика](#аналитика)
- [Диплинки](#диплинки)
- [Push-уведомления](#push-уведомления)
    - [Обработка получения токена](#обработка-получения-токена)
    - [Тестирование пушей](#тестирование пушей)
- [Кеширование](#кеширование)
    - [UniqueStorageKey](#uniquestoragekey)
    - [RamMemoryStorageService](#rammemorystorageservice)
    - [DiskStorageService](#diskstorageservice)
    - [KeychainStorageService](#keychainstorageservice)
    - [CacheStorable](#cachestorable)
    - [Expiry](#expiry)
- [Сетевой слой](#сетевой-слой)
- [Логи](#логи)
- [Дебаг панель](#дебаг-панель)
- [Utils](#utils)
    - [EventBus](#EventBus)
    - [VPNDetectionUtil](#VPNDetectionUtil)
    - [ApplicationLifecycleUtil](#ApplicationLifecycleUtil)
    - [WebCacheCleanerUtil](#WebCacheCleanerUtil)
    - [JailbreakDetectionUtil](#JailbreakDetectionUtil)
    - [HapticFeedbackUtil](#HapticFeedbackUtil)

## Файл проекта
На проекте используется [XcodeGen](https://github.com/yonaskolb/XcodeGen#installing]), для использования его необходимо установить в систему (в консоли `brew install xcodegen`).
Для создания `.xcodeproj` файла используется команда в консоли `sh generate`, которая создает файл с параметрами из `project.yml`. Все настройки проекта производятся в файле `project.yml`, подробно о настройках и работе на проекте с XcodeGen можно прочитать в [Readme XcodeGen](https://gitlab.com/mobileup/mobileup/development-ios/templates/-/blob/master/README.md).

## Настройка версии приложения
Версия приложения задается в конфиг-файле `project.yml`с помощью проперти app_version:

```yaml
variables:
  appVersion: &app_version "1.0"
```

## Архитектура
На проекте используется архитектура MVVM + Coordinator. Каждый модуль находится в группе `UI` и состоит из:  
- `Factory` - собирает модуль.  
- `ViewModel` - обрабатывает события и изменяет состояния экрана.  
- `ViewController` - отображет содержимое экрана и его текущее состояние.  
- `Coordinator` - выполняет переходы между модулями.  

Взаимодействие `ViewModel` с `ViewController` осуществляется через замыкания. Контроллер вызывает методы вью модели напрямую.  

### Шаблон модуля
В папке проекта /Template имеется шаблон для быстрого создания модуля. Чтобы начать им пользоваться необходимо добавить его в Xcode:  
1. Переходим в `Finder` к папке `~/Library/Developer/Xcode/Templates/`;  
2. Если внутри нет папки `File Templates` - создаем её;  
3. Внутри `File Templates` создаем ещё одну с названием `MobileUp Templates`;  
4. Копируем шаблоны из папки `Templates/`, которая лежит в корне папки проекта, в `MobileUp Templates`;  

Работа с шаблоном:  
1. В группе `UI` создаем группу нового модуля и тапаем на `New File...` (или ⌘+N);  
2. Выбираем шаблон `MVVM + C` в разделе `MobileUp Templates`;  
3. Указываем имя модуля, жмем `Create`.  

## Конфигурации
Подробнее о работе c файлами конфигурации в [гайде](https://ascnt.atlassian.net/wiki/spaces/MG/pages/594914)

Класс Еnvironments обеспечиват доступ к свойствам окружения
Например:
- instance возвращает текущее окружение
- isRelease позволяет определить, является ли текущее окружение релизным

```swift
final class Environments {
    enum ConfigKey: String, CaseIterable {
        case instance = "INSTANCE"
    }
    
    static var instance: Instance { value(for: .instance)! }
    static var isRelease: Bool { instance.isRelease }
    
    static func setup() {
        checkConfiguration()
    }
}
```
Примеры использования

```swift
if Environments.isRelease {
    ...
}

или

ServerClient(url: Environments.serverUrl) 
```

## Ресурсы
Все ресурсы находятся в группе Resources. Для работы с ними используется библиотека Rswift.

### Иконки
Находятся в ассет-файле Resources/Assets/Icons.assets. Все иконки разбиты на папки в зависимотси от размера - `ic16`, `ic24` и т.д.

Если отсутствует нужная папка:
1. Создаём новую в формате icS (S - размер иконок).
2. Устанавливаем галочку `Provide Namespaces`.

Если отсутствует нужная иконка:
1. Импортируем необходимую иконку в формате `.svg`.
2. Устанавливаем `Universal` для `Devices`.
3. Устанавливаем `Single Scale` для `Scales`.

**Пример использования:**
```swift
// UIKit
imageView.image = R.image.ic32.home.asUIImage
        
// SUI
R.image.ic32.home.image
```

### Цвета
Цвета находятся в ассет-файле Resources/Assets/Colors.assets. Все цвета разбиты на папки в зависимости от места применения - Icons, Button, Text и т.д. При cоздании папки устанавливаем галочку `Provide Namespaces`.

Если отсутствует нужный цвет:
1. B соответствующей папке создаем Color Set.
2. Цвет добавляем как `HEX` значение, например `#14B32F`.
3. Устанавливаем `None` для `Appearances`.
4. Устанавливаем `Universal` для `Devices`.

Когда нужно будет добавить поддержку тёмной темы, `Appearances` переключим в `Any, Dark`, тогда в `Dark` будем выставлять цвет для тёмной темы.

**Пример использования:**
```swift
// UIKit
view.tintColor = R.color.icons.primary.asUIColor
        
// SUI 
R.color.icons.disabled.color
```

### Шрифты
Шрифты хранятся в экстеншне UIFont и распределены по категориям: заголовки, кнопки, основной текст и тд. Для того, чтобы добавить новый шрифт, нужно в экстеншне добавить статическую константу, которая будет отвечать за новый шрифт.

**Пример использования:**
```swift
// UIKit
label.font = .Heading.medium
        
// SwiftUI
.font(UIFont.Heading.primary.asFont)
```

### Строки
Строки располагаются в `.strings` файлах.
Все файлы хранятся в Resources/Localizable/ с соответствующим именем

**Пример добавления строк:**
```swift
"examples-title" = "Библиотека готовых решений";
```
**Пример использования:**
```swift
R.string.examples.examplesTitle()
```

## Навигация
### TabBar
Для создания таббара используется библиотека [TabBarController](https://github.com/MobileUpLLC/TabBarController), которая позволяет полностью кастомизировать таббар. `CustomTabBarController` наследуется от `TabBarController` и переопределяет два свойства: `controllers`, передавая туда массив своих контроллеров и `tabBarView`, передавая в него кастомную вью. Контроллеры, которые находятся в таббаре подписаны под протокол `CustomTabBarItemProvider` и реализуют его свойство `tabBarItemIcon`.

**Пример**
```swift
final class ExamplesController: HostingController<ExamplesView>, CustomTabBarItemProvider {
    var tabBarItemIcon: UIImage
    
    init(viewModel: ExamplesViewModel) {
        tabBarItemIcon = UIImage(systemName: "rectangle.on.rectangle") ?? UIImage()
        super.init(rootView: ExamplesView(viewModel: viewModel))
    }
}
```

Для скрытия таббара на конкретном экране нужно переопределить пропертю isTabBarHidden в контроллере со значением false

```swift
final class ExamplesController: HostingController<ExamplesView>, CustomTabBarItemProvider {
    var isTabBarHidden: Bool { false }
}
```

### NavigationBar
Для настройки навбара используется протокол `Navigatable`. 
- `var navigationBarItem: NavigationBarItem` свойство, в которое нужно передать модели элементов навбара
- `var isNavigationBarHidden: Bool` свойство, которое позволяет скрыть навбар
- `var isBackButtonHidden: Bool` свойство, которое позволяет скрыть кнопку back
- `func configureNavigationBar()` Метод для настройки навбара, который имеет базовую реализацию в экстеншене

**Пример использования**
```swift
final class ExampleViewController: Navigatable {
    init(viewModel: ExampleViewModel) {
        super.init(rootView: ExamplesView(viewModel: viewModel))
        
        let centralItemType = NavigationBarCentralItem.ItemType.title(
            R.string.Example.navigationBarTitle()
        )
        let centralItem = NavigationBarCentralItem(type: centralItemType)
        
        let leftItem = NavigationBarSideItem(type: .back)
        
        let rightItemType = NavigationBarSideItem.ItemType.icon(R.image.share24.asUiImage)
        let rightItem = NavigationBarSideItem(
            type: rightItemType,
            onTapAction: viewModel.onShareButtonTapped
        )
        
        navigationBarItem = NavigationBarItem(
            centralItem: centralItem,
            leftItem: leftItem,
            rightItems: [rightItem]
        )
    }
}
```

### Routers
Навигационные переходы осуществляется через роутеры - контроллеры, закрытые протоколами `NavigationRouter`, `PresentationRouter`, `TabBarRouter`, `RootRouter`. В расширении UIViewController содержится базовая реализация методов этих протоколов.

#### NavigationRouter
Протокол `NavigationRouter` предоставляет методы для управления стеком навигации.
```swift
protocol NavigationRouter: AnyObject {
    func push(controller: UIViewController, isAnimated: Bool)
    func pop(isAnimated: Bool)
    func pop(to: AnyClass, isAnimated: Bool)
    func popToRoot(isAnimated: Bool)
}
```
**Пример:**
```swift
final class ExamplesCoordinator {
    weak var router: NavigationRouter?

    func showSkeletonModule() {
        let controller = SkeletonFactory.createSkeletonController()
        
        router?.push(controller: controller, isAnimated: true)
    }
```

#### PresentationRouter
Протокол `PresentationRouter` предоставляет методы для модальных переходов
```swift
protocol PresentationRouter: AnyObject {
    func present(controller: UIViewController, isAnimated: Bool, completion: Closure.Void?)
    func dismiss(isAnimated: Bool, completion: Closure.Void?)
}
```
**Пример:**
```swift
final class ExamplesCoordinator {
    weak var router: PresentationRouter?
    
    func showWebPageModule(pageModel: WebPageModel) {
        let controller = WebPageFactory.createWebPageController(pageModel: pageModel)
        
        router?.present(controller: controller, isAnimated: true, completion: nil)
    }
}
```

#### TabBarRouter
Протокол `TabBarRouter` предоставляет метод `selectTab(index: Int)` для переходов между табами

```swift 
protocol TabBarRouter: AnyObject {
    func selectTab(index: Int)
}
```
**Пример:**

```swift
final class TabBarCoordinator {
    weak var router: TabBarRouter?
    
    func openHome() {
        router?.selectTab(index: .one)
    }
} 
```

#### RootRouter
Протокол `RootRouter` предоставляет метод для замены текущего корневого контроллера на новый
```swift
protocol RootRouter: AnyObject {
    func showApplicationRoot(controller: UIViewController, animated: Bool)
}
```
**Пример:**
```swift
final class BottomSheetExampleCoordinator {
    weak var router: RootRouter?

    func showExampleModule() {
        let controller = ExamplesFactory.createExamplesController()
        
        router?.showApplicationRoot(controller: controller, animated: true)
    }
}
```

## Обработка ошибок
Текущая обработка ошибок применяется для экранов, где нет списка. Для выполнения асинхронных операций используется структура `Perform`. Если операция завершается ошибкой, она передается в замыкание onError.

**Пример использования**
```swift
class ExampleViewModel {
    ...

    func getSomeData() {
        isLoading = true
        
        Perform { [weak self] in

            let data = try await repository.loadData()
            
            onMain {
                // update view with data
            }
        } onError: { [weak self] _ in
            self?.isError = true
            self?.isLoading = false
        }
    }
}
```
Для отображения ошибки используется модификатор `.errorState(isError:)` который возвращает вью c ошибкой, когда флаг isError, переданный из вьюмодели имеет значение `true`
```swift
struct ExampleView: View {
    @ObservedObject var viewModel: ExampleViewModel

    var body: some View {
        VStack {
           ... 
        }
        .skeleton(isLoading: viewModel.isLoading) {
            SkeletonContentView()
        }
        .errorState(isError: viewModel.isError) {
            ErrorView(onRetry: viewModel.onRetryButtonTapped)
        }
    }
}
```

## Bottom sheet
Для показа боттом шита нужно использовать модификатор `.sheet()`
Размер боттом шита определяется модификатором `.presentationDetents()`
Так как на проекте реализована навигация на UIKit, sheet не может иметь вложенную навигацию. То есть `sheet` используем для простых боттом шитов

По нажатию вне области попапа, вью закрывается.

### Пример использования одного боттом шита
Пример основанный на использовании булевой переменной, которая управляет показом или скрытием одного Bottom Sheet.

```swift
final class BottomSheetExampleViewModel: ObservableObject {
    @Published var isBottomSheetPresented = false
    ...
    
    func onShowBottomSheetButtonTapped() {
        isBottomSheetPresented = true
    }
    
    func onShowSkeletonButtonTapped() {
        isBottomSheetPresented = false
        
        // NOTE: onMainAfter используем для того, чтобы модуль открылся после того, как закроется bottom sheet 
        onMainAfter(deadline: .now() + 1) { [weak self] in
            self?.coordinator.showSkeletonModule()
        }
    }
}
```
```swift 
struct BottomSheetExampleView: View {
    @ObserverdObject var viewModel: BottomSheetExampleViewModel
    
    var body: some View {
        ZStack {
            Color.white
            Button("show BottomSheet") {
                viewModel.onShowBottomSheetButtonTapped()
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $viewModel.isBlueSheetPresented) {
            ZStack {
                ...
                Button("Show skeleton") {
                    viewModel.onShowSkeletonButtonTapped()
                }
            }
            .presentationDetents([.fraction(0.5)])
        }
    }
}
```

### Пример использования нескольких боттом шитов
Пример основанный на использовании enum, который помогает управлять показом или скрытием нескольких Bottom Sheet не дублируя при этом код

```swift 
final class MultipleBottomSheetExampleViewModel: ObservableObject {
    enum BottomSheet: Identifiable {
        case greenSheet
        case blueSheet
        
        var id: Self { self }
    }
    
    @Published var bottomSheet: BottomSheet?
    
    ...
    func onShowBlueSheetButtonTapped() {
        bottomSheet = .blueSheet
    }
    
    func onShowGreenSheetButtonTapped() {
        bottomSheet = .greenSheet
    }
}

struct MultipleBottomSheetExampleView: View {
    @ObservedObject var viewModel: MultipleBottomSheetExampleViewModel

    var body: some View {
        ZStack {
            ...
        }
        .sheet(item: $viewModel.bottomSheet) { sheet in
            switch sheet {
            case .greenSheet:
                ZStack {
                    ...
                    Button("Show blue sheet") {
                        viewModel.onShowBlueSheetButtonTapped()
                    }
                }
                .presentationDetents([.medium])
            case .blueSheet:
                ZStack {
                    ...
                    Button("Show green sheet") {
                        viewModel.onShowGreenSheetButtonTapped()
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}
```
### Кастомизация фона выше ботомшита

При показе боттом шита фон автоматически затемняется. Эппл не предоставляет возможности задать цвет. Но можно сделать кастомное решение: при показе ботомшита на вью накладывать оверлей.

Модификатор `.presentationBackgroundInteraction(.enabled(upThrough: .medium))` позволяет отключить системное затемнение фона при показе боттом шита (доступен с iOS 16.4). Чтобы не загромождать вью условными конструкциями, используется кастомный модификатор `.enablePresentationBackgroundInteraction()`, который уже содержит в себе проверку версии iOS.

До iOS 16.4 лучше использовать системное затемнение фона, иначе кастомный оверлей и системный фон выше ботомшита будут смешиваться и результирующий цвет не будет соответствовать макетам.

```swift 
struct BottomSheetExampleView: View {
    var body: some View {
        ZStack {
            ...
        }
        .overlay {
            Color.black
                .opacity(viewModel.isBottomSheetPresented ? 0.5 : 0)
                .animation(.linear(duration: 0.15), value: viewModel.isBottomSheetPresented)
                .onTapGesture {
                    viewModel.isBottomSheetPresented = false
                }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $viewModel.isBottomSheetPresented) {
            GreenBottomSheetView()
                .enablePresentationBackgroundInteraction(detent: .medium)
        }
    }
}

struct GreenBottomSheetView: View {
    var body: some View {
        ...
    }
}
```

## Алерты
Для показа алертов используем модификатор `.alert()`
Если по нажатию на кнопку алерта нужно открывать следующий алерт или боттом шит, задержку, чтобы алерт закрылся, делать не нужно. Он автоматически закрывается перед тем, как откроется следующий. 

**Пример использования:**
```swift
struct ExampleView: View {
    @ObservedObject var viewModel: ExampleViewModel
    
    var body: some View {
        ZStack {
            ...
        }
        .alert(
            R.string.examples.alertTitle(),
            isPresented: $viewModel.isAlertPresented,
            actions: {
                Button(R.string.examples.alertButtonTitle()) {
                    viewModel.onAlertButtonTapped()
                }
            },
            message: { Text(R.string.examples.alertMessage()) }
        )
    }
}

final class ExampleViewModel: ObservableObject {
    @Published var isAlertPresented = false
    @Published var isBottomSheetPresented = false
    ...
    
    func onShowAlertButtonTapped() {
        isAlertPresented = true
    }
    
    func onAlertButtonTapped() {
        isBottomSheetPresented = true
    }
}
```

## Тосты
Для показа тостов используем протокол `ToastRouter`. Основной метод протокола `showToast(with item: ToastItem)`. 
`ToastItem` содержит следующие параметры:
- `viewItem` - содержит стиль, сообщение, иконки для вью тоста
- `toastType` - тип тоста (глобальный тост добавлен на window/локальный тост добавлен на view у UIViewController)
- `direction` - расположение тоста на экране (сверху/снизу)
- `duration` - время в секундах, на которое тост останется видимым (не считая анимации)
- `isHideOnTap` - определяет, будет ли тост скрываться по нажатию
- `onTap` - замыкание, которое будет выполняться по нажатию на тост

Для использования стандартных тостов добавляем соответствующие методы в протокол ToastRouter. Затем, в расширении UIViewController реализуем их, вызывая showToast() с заранее заданными параметрами.

**Пример добавления тоста:**

Добавляем новый метод в протокол `ToastRouter`, например `showToast(with item: ToastItem)`
```swift
protocol ToastRouter: AnyObject {
    ...
    func showToast(with item: ToastItem)
}
```
В расширении `UIViewController` этот метод создает вью тоста, которая наследуется от `ToastBaseView` и вызывает `showTost()` с заранее определенными параметрами.
```swift
extension UIViewController: ToastRouter {
    func showToast(with item: ToastItem) {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        let toastView = ToastView(item: item.viewItem)

        var fromView: UIView

        switch item.toastType {
        case .global:
            fromView = window
        case .local:
            fromView = view
        }

        ToastPresenter.shared.showToast(
            toastView: toastView,
            fromView: fromView,
            direction: item.direction,
            duration: item.duration,
            insets: .init(top: 56, left: 16, bottom: 120, right: 16),
            isHideOnTap: item.isHideOnTap,
            onTap: item.onTap
        )
    }
}
```

**Пример использования:**
```swift
final class ExampleCoordinator {
    weak var router: ToastRouter?

    func showToast(item: ToastItem) {
        router?.showToast(with: item)
    }
}

final class ExampleViewModel: ObservableObject {
        private func showToastExample() {
        let toastItem = ToastItem(
            viewItem: ToastViewItem(
                style: .success,
                message: "Тестовый тост для проверки с очень длинным описанием в две строки",
                leftIcon: UIImage(),
                rightIcon: nil
            ),
            toastType: .local,
            direction: .bottom,
            duration: .three,
            isHideOnTap: true,
            onTap: { // добавить действие при нажатии если есть }
        )
        
        coordinator.showToast(item: toastItem)
    }
}
```

## Skeleton
Для того что бы добавить ко `view` skeleton, используем модификатор `skeleton`

**Пример добавления skeleton**
```swift
    var body: some View {
        Text(Constants.contentText)
            // добавляем к контенту модификатор skeleton и view которая будет скелетонироваться
            .skeleton(isLoading: viewModel.isLoading) {
                SkeletonContentView()
            }
    }
```

Для реализации `skeleton` используем `ShimmerModifier`. Для него можно настроить параметры анимации и градиента которые будут применены к `view`. Для настроек анимации и градиента необходимо реализовать анимацию и градиент по аналогии с ShimmerModifier.defaultAnimation и ShimmerModifier.defaultGradient и передать их в модификатор или же изменить значения по умолчанию.

**Метод добавления модификатора**
```swift
@ViewBuilder func shimmering(
        active: Bool = true,
        animation: Animation = ShimmerModifier.defaultAnimation,
        gradient: Gradient = ShimmerModifier.defaultGradient,
        bandSize: CGFloat = 0.3
    ) -> some View {
        if active {
            modifier(ShimmerModifier(animation: animation, gradient: gradient, bandSize: bandSize))
        } else {
            self
        }
    }
``` 

При необходимости `ShimmerModifier` можно доработать для проигрывания анимации в нужном направлении. Для этого необходимо настроить значения у `ShimmerModifier` `startPoint` и `endPoint`.

**Пример настройки позиции анимации**

```swift
// начальная точка анимации градиента
var startPoint: UnitPoint {
    if layoutDirection == .rightToLeft {
        return isInitialState ? UnitPoint(x: max, y: min) : UnitPoint(x: 0, y: 1)
    } else {
        return isInitialState ? UnitPoint(x: min, y: min) : UnitPoint(x: 1, y: 1)
    }
}

// конечная точка анимации градиента
var endPoint: UnitPoint {
    if layoutDirection == .rightToLeft {
        return isInitialState ? UnitPoint(x: 1, y: 0) : UnitPoint(x: min, y: max)
    } else {
        return isInitialState ? UnitPoint(x: 0, y: 0) : UnitPoint(x: max, y: max)
    }
}


```

## Работа с датами
DateService — сервис, предоставляющий методы для форматирования даты в различных форматах. Его основная цель — конвертировать объект Date в строку с учетом заданного формата, локализации и других условий (например, вывод «Сегодня» или «Вчера» для недавних дат).

Форматы дат:
- `day` - показывает день: Сегодня, Вчера или в формате 11 ноября.
- `dayNumber` - только день: 23.
- `dayTime` - комбинирует день и время: Сегодня 11:00
- `month` - название месяца: Январь 
- `year` - год: 2024
- `dayTimeDot` - день и время через точку: Сегодня • 11:00.
- `dayMonthYear` - дата в формате dd.MM.yyyy или MM.dd.yyyy (в зависимости от локализации).

**Пример использования:**
```
let model = ...

let viewItem = ViewItem(
    day: DateService.convert(date: model.date, format: .day)
)
```

DateRangeService — сервис для работы с диапазонами и компонентами дат. Он предоставляет методы для вычисления, сравнения и преобразования дат с использованием календарных операций.

**Пример использования:**
```
let date = Date()
let nextMonth = DateRangeService.addMonthsToDate(count: 1, date: date)
```

## Аналитика
Класс `AnalyticsService` предоставляет универсальный сервис для отправки событий аналитики через провайдеров. Провайдерами могут быть любые сервисы аналитики, соответствующие протоколу `AnalyticsProvider`
```swift 
protocol AnalyticsProvider {
    // Метод должен содержать логику настройки сервиса
    func configure()

    // Метод для отправки события в сервис аналитики
    func report(event: AnalyticsEvent, params: [AnalyticsEventParam: Any]) 
    
    //Метод для фильтрации событий перед отправкой. Он должен решать, отправлять ли это событие в сервис аналитики или нет
    func shouldReport(event: AnalyticsEvent) -> Bool
}
```
`AnalyticsService` cодержит два метода: 
- `configure(providers:)` Эти провайдеры будут использоваться для отправки аналитических событий.
- `report(event:params:)` Отправляет событие во все провайдеры аналитики, которые были переданы в массив `providers`. Каждый провайдер решает, нужно ли ему отправлять это событие, в зависимости от своей реализации метода `shouldReport`.

Новые события и параметры добавляются в `AnalyticsEvent` и `AnalyticsEventParam`.

**Пример добавления сервиса аналитики:**
```swift
class AppDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AnalyticsService.shared.configure(providers: [FirebaseService.shared])
        
        ...
    }
}
```
**Пример отправки события аналитики:**
```swift
AnalyticsService.shared.report(
    event: .webviewCellTap,
    params: [.testParam: Constants.viewName]
)
```

## Диплинки
Для обработки Deeplink'ов используется `DeepLinkService`, который является фасадом для разных провайдеров. Если потребуется добавить новый обработчик диплинков, то расширение делается через добавление нового провайдера, без глобальных изменений. Провайдеры должны соответствовать протоколу `DeepLinkProvider`

**Пример добавления провайдера:**
```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        DeepLinkService.shared.configure(launchOptions: launchOptions, providers: [URLSchemeDeepLinkProvider.shared])

        return true
    }
}

```
Основные свойства и методы `DeepLinkService`:
- `onDeeplinkReceived` Замыкание, которое будет вызвано при получении ссылки. 
- `configure(launchOptions:providers:)` Метод, в котором каждый провайдер будет настроен с параметрами launchOptions. Провайдеры могут использовать эту информацию для обработки ссылок.

Для работы с диплинками нужно добавить URL-схему в Info.plist. Для тестирования работы диплинков можно использовать Safari: вставить URL в адресную строку, приложение откроется, и далее DeepLinkService обработает этот URL.

**Пример подписки на получение диплинка и его обработка:**
```swift
final class TabBarViewModel {
    ...
    
    init(deepLinkService: DeepLinkService) {
        ...
    
        deepLinkService.onDeeplinkReceived = { [weak self] deepLink in
            self?.handleDeepLink(deeplink: deepLink)
        }
    }
    
    private func handleDeepLink(deeplink: DeepLink) {
        switch deeplink {
        case .test:
            ...
        }
    }
}
```

## Push-уведомления
Для обработки пушей используется синглтон `PushService`, который управляет запросом разрешений на получение push-уведомлений, а также обработкой поступающих уведомлений. Он содержит:
 - `onPushReceive` Замыкание, которое будет вызвано при получении push-уведомления.
 - `requestAuthorization(options:)` Метод, который запрашивает разрешение для получения push-уведомлений. 

**Пример использования**
```swift
final class ExampleViewModel: ObservableObject {
    ...
    private let pushService: PushService
    
    init(coordinator: CustomTabBarCoordinator, pushService: PushService) {
        ...
        
        pushService.onPushReceive = { [weak self] model in
            self?.onPushTapped(model: model)
        }
        
        func viewDidAppear() {
            Task {
            // запрос разрешения пользователя на получение push-уведомлений
                _ = try? await pushService.requestAuthorization()
            }
        }
    
        private func onPushTapped(model: PushPayloadModel) {
            // обработка push-уведомления
            ...
        }
    }
```
### Обработка получения токена
`PushTokenRepository` получает токен девайса, который можно передать на сервер для получение от него пуш уведомлений.

### Тестирование пушей
Для тестирования можно использовать apns-файл, который лежит в папке APNSFiles в директории проекта. Этот файл нужно перенести на симулятор и пуш появится.

## Кеширование
Для кеширования на диск в виде файла или в оперативную память используется библиотека `Cache`.
Для кеширования в keychain используется библиотека `KeychainAccess`.

Вся работа по работе с библиотеками закрыта обертками:

- `RamMemoryStorageService`
- `DiskStorageService`
- `KeychainStorageService`

Каждый сервис(хранилище) следует протоколу `Storable`.
```swift 
protocol Storable {
    associatedtype Key: Hashable
    associatedtype Value

    var allKeys: [Key] { get }
    var allObjects: [Value] { get }

    func object(forKey key: Key) throws -> Value
    func entry(forKey key: Key) throws -> StorageEntry<Value>
    func removeObject(forKey key: Key) throws
    func setObject(_ object: Value?, forKey key: Key, expiry: Expiry?) throws
    func objectExists(forKey key: Key) -> Bool
    func removeAll() throws
    func removeExpiredObjects() throws
    func isExpiredObject(forKey key: Key) throws -> Bool
    func removeInMemoryObject(forKey key: Key) throws
}
```
### UniqueStorageKey
Протокол `Storable` использует ключ `Key: Hashable`. Рекомендуется по работе с хранилищами использовать `UniqueStorageKey`,
который гаранитрирует уникальность ключа для текущего окружения (дев прод).
```swift
struct UniqueStorageKey<T: Hashable>: Hashable {
    private let value: T
    private let mobileApi: String

    init(value: T) {
        self.value = value
        self.mobileApi = Environments.mobileApiUrl.absoluteString
    }
}
```
**Пример работы:**
```swift 
private typealias UniqueKey = UniqueStorageKey<String>

private let citiesStorageService = RamMemoryStorageService<UniqueKey, [CityResponse]>()
```

### RamMemoryStorageService
Сервис по хранению данных в оперативной памяти
**Пример работы:**
```swift
private typealias UniqueKey = UniqueStorageKey<String>

enum Constants {
    static let citiesKey = UniqueKey(value: "citiesKey")
}

private let citiesStorageService = RamMemoryStorageService<UniqueKey, [CityResponse]>()

let object = citiesStorageService?.object(forKey: Constants.citiesKey)

... другие операции из протокола Storablee
```

### DiskStorageService
Сервис по хранению данных в виде файлов на диске. Если использовать дефолтный конфиг, то:

- данные сохраняются в папку `AppContainer/Library/Application Support/PersistansCaches/PersistentStorage/'
- максимальный размер хранилища 50 мегабайт

**Пример работы:**
```swift
private typealias HomeDataKey = UniqueStorageKey<String>

enum Constants {
    static let homeDataKey = HomeDataKey(value: "HomeDataKey")
}

private let homeDataStorageService = DiskStorageService<HomeDataKey, CachedHomeData>(
    transformer: TransformerFactory.forCodable(ofType: CachedHomeData.self)
)

let object = homeDataStorageService?.object(forKey: Constants.homeDataKey)

... другие операции из протокола Storable
```

### KeychainStorageService
Сервис по хранению данных в кейчейне. Тип ключ для этого хранилища по умолчанию UniqueStorageKey и явно при создании не задается.
**Пример работы:**
```swift
enum Constants {
    static let profileKey = UniqueStorageKey<String>(value: "profileKey")
}

private let profileStorageService = KeychainStorageService<GetProfileResponse>(
    config: .default, transformer: KeychainTransformerFactory.forCodable(ofType: GetProfileResponse.self)
)

let object = profileStorageService?.object(forKey: Constants.profileKey)

... другие операции из протокола Storable
```

### CacheStorable
Данный протокол применяется к Repository и имеет дефолтные реализации, которые позволяют:

- считывать данные из кеша;
- записывать данные в кеш;
- проверять данные на протухание;
- получать данные из кеша или делать запрос на сервер.

Протокол работает со всеми вышеперечисленными хранилищами.
API:
```swift
protocol CacheStorable {
    func fetchDataWithCache<StorageServiceType: Storable>(
        storageService: StorageServiceType?,
        networkService: NetworkService,
        key: StorageServiceType.Key,
        expiry: Expiry,
        isForceRefresh: Bool,
        isNeedToRemoveExpiredDataInCache: Bool,
        fetchData: @escaping (_ networkService: NetworkService) async throws -> StorageServiceType.Value
    ) async throws -> StorageServiceType.Value

    func saveData<StorageServiceType: Storable>(
        storage: StorageServiceType,
        object: StorageServiceType.Value,
        key: StorageServiceType.Key,
        expiry: Expiry
    )

    func getData<StorageServiceType: Storable>(
        storage: StorageServiceType,
        key: StorageServiceType.Key
    ) -> StorageServiceType.Value?

    func removeExpiredObject<StorageServiceType: Storable>(
        storage: StorageServiceType,
        key: StorageServiceType.Key
    ) -> Bool
}
```

**Пример использования:**
```swift
final class ProfileRepository: CacheStorable {
    private typealias UniqueKey = UniqueStorageKey<String>

    private enum Constants {
        static let getProfileStorageKey = UniqueKey(value: "ProfileRepository.getProfileKey")
        static let getPopularCitiesStorageKey = UniqueKey(value: "ProfileRepository.getPopularCities")
        static let profileExpiryInSeconds: Expiry = .seconds(300)
    }

    private let profileStorageService = KeychainStorageService<GetProfileResponse>(
        config: .default, transformer: KeychainTransformerFactory.forCodable(ofType: GetProfileResponse.self)
    )

    private let citiesStorageService = RamMemoryStorageService<UniqueKey, [CityResponse]>()

    private let networkService: NetworkService(
        provider: MoyaProvider<MobileApi>(
            session: .defaultWithoutCache,
            plugins: [LoggerPlugin.instance, ShoppingCartPlugin()]
        )
    )

    func getProfile(isForceRefresh: Bool = false) async throws -> GetProfileResponse {
        try await fetchDataWithCache(
            storageService: profileStorageService,
            networkService: networkService,
            key: Constants.getProfileStorageKey,
            isForceRefresh: isForceRefresh,
            isNeedToRemoveExpiredDataInCache: false,
            fetchData: { networkService in try await networkService.getProfile().data }
        )
    }
    
    func getPopularCities() async throws -> [CityResponse] {
        try await fetchDataWithCache(
            storageService: citiesStorageService,
            networkService: stubNetworkService,
            key: Constants.getPopularCitiesStorageKey,
            expiry: .never,
            fetchData: { networkService in try await networkService.getPopularCities() }
        )
    }
```

### Expiry
Позволяет задать время протухания данных

```swift 
public enum Expiry {
  /// Object will be expired in the nearest future
  case never
  /// Object will be expired in the specified amount of seconds
  case seconds(TimeInterval)
  /// Object will be expired on the specified date
  case date(Date)
  }
```

**Пример использования:**

```swift
final class ProfileRepository: CacheStorable {
    private typealias UniqueKey = UniqueStorageKey<String>

    private enum Constants {
        static let getProfileStorageKey = UniqueKey(value: "ProfileRepository.getProfileKey")
        static let profileExpiryInSeconds: Expiry = .seconds(300)
    }

    private let profileStorageService = KeychainStorageService<GetProfileResponse>(
        config: .default, transformer: KeychainTransformerFactory.forCodable(ofType: GetProfileResponse.self)
    )

    func getProfile(isForceRefresh: Bool = false) async throws -> GetProfileResponse {
        try await fetchDataWithCache(
            storageService: profileStorageService,
            networkService: networkService,
            key: Constants.getProfileStorageKey,
            expiry: Constants.profileExpiryInSeconds
            isForceRefresh: isForceRefresh,
            isNeedToRemoveExpiredDataInCache: false,
            fetchData: { networkService in try await networkService.getProfile().data }
        )
    }
```

## Сетевой слой
Для работы с сетью используется обертка над Moya, которая умеет в обработку рефреш токена при множественных запросах на обновление токена.
Подробную информацию по работе Moya и дополнительным настройкам можно посмотреть [здесь](https://github.com/Moya/Moya)

Каждый сетевой сервис должен следовать протоколу `NetworkService`
```swift
protocol NetworkService {
    associatedtype Target: MobileApiTargetType
    
    var onTokenRefreshFailed: Closure.Void? { get set }
    
    func request<T: Decodable>(target: Target) async throws -> T
    func request(target: Target) async throws
}
```

`onTokenRefreshFailed` вызывается только один раз, когда токен не удалось обновить. В данном случае необходимо выполнить логаут.


`MobileService` используется как синглтон, который содержит необходимую настройку сетевого слоя, что в результате упрощает его использование в проекте
```swift
class MobileService: BaseNetworkService<MobileApi> {
    static let shared = MobileService()
        
    init() {
        let tokenProvider = AuthRepository()

        let apiProvider = MoyaProvider<MobileApi>(
            session: .defaultWithoutCache,
            plugins: [LoggerPlugin.instance, AccessTokenPlugin(accessTokenProvider: tokenProvider)]
        )
                
        super.init(apiProvider: apiProvider, tokenRefreshProvider: tokenProvider)
    }
}

```

**Пример использования:**
```swift
final class NetworkExampleViewModel: ObservableObject {
    private let coordinator: NetworkExampleCoordinator
    private let mobileService: MobileService
    
    init(coordinator: NetworkExampleCoordinator, mobileService: MobileService) {
        self.coordinator = coordinator
        self.mobileService = mobileService
    }
        
    func onRequestDataButtonTapped() {

        Perform {
            let items: [ExampleModel] = try await self.mobileService.request(target: .example(.testItems))
            ...
        }
    }
}
```

### Работа с моковыми данными
В MobileService настроено поведение stubClosure MoyaProvider, при интеграции с бэком это позволяет управлять подменой реального ответа от сервера на мок для конкретного запроса. Для использования реализуем протокол MockableMobileApiTarget, добавляем моковые данные в json-формате в Resources/Mock. Для переключения мок/реальный запрос используется свойство isMockEnabled.

**Пример использования:**
```swift
extension ExampleApi: MockableMobileApiTarget {
    var isMockEnabled: Bool { getIsMockEnabled() }
    
    func getMockFileName() -> String? {
        switch self {
        case .testItems:
            return "MockTempTokenModel"
        }
    }
    
    private func getIsMockEnabled() -> Bool {
        switch self {
        case .testItems:
            return true
        }
    }
}
```

## Логи
Подробнее о работе с логами в [гайде](https://ascnt.atlassian.net/wiki/spaces/MG/pages/141197407/Logger)

Для удобной работы с логами разбиваем их на подсистемы:
```swift
extension Log {
    static let deeplinkService = Log(subsystem: subsystem, category: "DeeplinkService")
    static let previewService = Log(subsystem: subsystem, category: "PreviewService")
   
    static let videoRecordView = Log(subsystem: subsystem, category: "VideoRecordView")
    static let editView = Log(subsystem: subsystem, category: "EditView")

    static let skeletonViewModel = Log(subsystem: subsystem, category: "SkeletonViewModel")
    static let recordViewModel = Log(subsystem: subsystem, category: "recordViewModel")
    ...
    private static let subsystem = Bundle.main.bundleIdentifier ?? .empty
}
```
Примеры использования:
```swift
DeeplinksService.initSession { [weak self] parameters, error, _ in
    if let error {
        Log.deeplinkService.error(logEntry: .text(error))
    } else if let parameters {
        Log.deeplinkService.debug(logEntry: .detailed("Received deeplink", parameters))
        ...
    }
}

class SkeletonViewModel {
    ...
    
    init() {
        Log.skeletonViewModel.debug(logEntry: .text("init skeletonViewModel"))
        ...
    }
    
    deinit {
        Log.skeletonViewModel.debug(logEntry: .text("deinit skeletonViewModel"))
    }
}
```
## Дебаг панель
Для просмотра логов на устройстве реализована дебаг панель с помощью библиотеки [Pulse](https://github.com/kean/Pulse). Дебаг панель (модуль Logs) открывается при тряске девайса и только на дев сборке. Pulse работает на уровне URLSession и настраивается с помощью URLSessionProxy. Настройка сессии происходит в файле Moya+session. Для отображения не сетевых логов в дебаг панели используется метод `storeMessage`

```swift
struct Log {
    ...
    private func log(level: OSLogType, logEntry: LogEntry) {
        ...
        // Log to Pulse
        LoggerStore.shared.storeMessage(
            label: category,
            level: level.toLoggerStoreLevel(),
            message: logMessage
        )
    }
}
```

## Utils
На проекте есть раздел утилиты которые можно использовать для облегчения разработки

### EventBus
Используется как альтернатива `Notification`, для шаринга изменения объекта всем подписчикам. Например можем использовать для обновления данных без повторного запроса в сеть. Для этого создадим `EventBus` и замыкание с логикой которое будет выполнятся после отправки данных. А дальше после того как данные успешно отправятся на сервер мы передадим их в `EventBus` с помощью метода send(event:), после чего выполнится наше замыкание.

**Пример использования**
```swift
// подписываем модель используемую в EventBus на протокол Eventable
extension AccessTokenRequestModel: Eventable {
    static let eventId = UUID()
}
    
final class ExampleViewModel: ObservableObject {
    private let exampleRepository = ExampleRepository()
    ...
    
    private func checkUserAuthorizedStatus() {
        authRepository.onAccessTokenUpdate = { [weak self] model in
            self?.requestModel = model
        }
    }
}

final class ExampleRepository: {
    ...
    
    // создаем объект EventBus
    private var authEventBus = EventBus<AccessTokenRequestModel>()
    
    // создаем замыкание которое будет вызываться при обновлении данных
    var onAccessTokenUpdate: Closure.Generic<AccessTokenRequestModel>? {
        didSet {
            authEventBus = EventBus(subscribe: onAccessTokenUpdate)
        }
    }
    
    func refresh() async throws {
        ...
        
        // отправим обновленные данные в EventBus для вызова замыкания
        authEventBus.send(event: AccessTokenRequestModel(accessToken: token.accessToken))
    }
}
```

### VPNDetectionUtil
Используется для определения включен ли впн

### ApplicationLifecycleUtil
Утилита позволяющая подписаться на методы жизненного цикла приложения. Обрабатывает три метода:
1. `UIApplication.didBecomeActiveNotification`
2. `UIApplication.willEnterForegroundNotification`
3. `UIApplication.willResignActiveNotification`

**Пример использования**
```swift
...
applicationLifecycleUtil.onApplicationWillResignActive = { [weak self] in
    self?.pause(withUpdateIsPlaying: true)
}

applicationLifecycleUtil.onApplicationDidBecomeActive = { [weak self] in
    self?.pause(withUpdateIsPlaying: false)
}

applicationLifecycleUtil.onApplicationWillEnterForeground = { [weak self] in
    self?.update()
}
```

### WebCacheCleanerUtil
Очищает `URLCache`, `HTTPCookieStorage` и `WKWebsiteDataStore`

### JailbreakDetectionUtil
Используется для проверки безопасности устройства на наличие `Jailbreak`

### HapticFeedbackUtil
Используется для удобного создания и вызова событий с виброоткликом

**Пример использования**
```swift
...
.onTapGesture {
    HapticFeedbackGenerator.generate(.selection)
}

...
.onLongPressGesture {
    HapticFeedbackGenerator.generate(.notification(.success))
    onLongPressAction()
}
```
