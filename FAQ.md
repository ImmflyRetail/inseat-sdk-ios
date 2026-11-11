# Inseat iOS SDK — Use Cases & FAQ

This document explains how to integrate the Inseat iOS SDK into an app with its own UI: step-by-step use cases with code, followed by answers to the questions integrators most often ask.

For the full list of methods, parameters and data models, see the [API reference](README.md).

## Table of Contents

- [How the SDK works](#how-the-sdk-works)
- [Use Cases](#use-cases)
  - [1. Start the SDK on app launch](#1-start-the-sdk-on-app-launch)
  - [2. Check and request permissions](#2-check-and-request-permissions)
  - [3. Show the shop status](#3-show-the-shop-status)
  - [4. Show menus, categories, products and currencies](#4-show-menus-categories-products-and-currencies)
  - [5. Build a basket and apply promotions](#5-build-a-basket-and-apply-promotions)
  - [6. Place an order and track its status](#6-place-an-order-and-track-its-status)
  - [7. Cancel an order](#7-cancel-an-order)
  - [8. Keep product data up to date](#8-keep-product-data-up-to-date)
  - [9. Collect SDK logs](#9-collect-sdk-logs)
  - [10. Stop and restart the SDK](#10-stop-and-restart-the-sdk)
- [FAQ](#faq)
  - [Setup & Initialization](#setup--initialization)
  - [Catalog & Menu](#catalog--menu)
  - [Shop Status](#shop-status)
  - [Basket, Promotions & Checkout](#basket-promotions--checkout)
  - [Orders](#orders)
  - [Permissions & Connectivity](#permissions--connectivity)
  - [Building your own UI](#building-your-own-ui)
  - [Errors & Troubleshooting](#errors--troubleshooting)

---

## How the SDK works

The SDK connects the passenger's app with the crew's POS device on board:

| Data | Comes from | When | Internet needed |
|---|---|---|---|
| **Product data** (menus, categories, products, promotions, currencies) | Inseat API, then stored on the device | While the device has internet | Yes |
| **Shop status, stock and orders** | Crew's POS device, over Bluetooth and the local network | After `start()` is called | No |

**The shop** appears when the crew opens a flight on the POS device. Its status tells you whether passengers can browse, order, or neither.

> **Important:** after `start()`, keep an `observeShop()` observer alive for the whole session. Stock and order status updates for the current flight only start syncing once the SDK has seen the shop through `observeShop()`. Without it, products stay at quantity 0 and orders never receive status updates.

All data is read from the local store, so `fetch*` methods return immediately and `observe*` methods call you back whenever the data changes.

---

## Use Cases

### 1. Start the SDK on app launch

Call these methods in this order, once per app launch:

1. `initialize()`: sets up the SDK. Needs internet on the first launch after install.
2. `syncProductData()`: downloads the product catalog. Needs internet; returns quickly if nothing changed.
3. `start()`: starts syncing with the crew's POS device.
4. `observeShop()`: keep this observer alive; it's what makes stock and orders sync (see [Show the shop status](#3-show-the-shop-status)).

```swift
import Inseat

@MainActor
final class InseatService {

    static let shared = InseatService()

    func launch() async {
        let configuration = Configuration(
            apiKey: "{API_KEY}",
            supportedICAOs: ["{ICAO_UPPERCASED}"],
            environment: .live,
            shopAutoCloseTimeoutInSeconds: 120,         // optional, default 120
            orderConfirmationTimeoutDelayInSeconds: 120 // optional, default 120
        )

        do {
            try await InseatAPI.shared.initialize(configuration: configuration)
        } catch {
            // Usually no internet on the first launch after install, or a wrong API key.
            // Nothing else will work until this succeeds; retry later.
            return
        }

        do {
            try await InseatAPI.shared.syncProductData()
        } catch {
            // Not fatal: the SDK keeps using the catalog from the last successful sync.
        }

        do {
            try await InseatAPI.shared.start()
        } catch {
            // Sync with the crew's device couldn't start. See "Errors & Troubleshooting".
        }

        // Required for stock and order sync. Keep the observer for the whole session.
        shopObserver = try? InseatAPI.shared.observeShop { shop in
            // Update your shop status UI.
        }
    }

    private var shopObserver: Observer?
}
```

Notes:

- Call `initialize()` before any other SDK method. Most methods throw `InseatError.initializationError(.notInitialized)` until it has finished successfully; `setUserData()` and `stop()` silently do nothing. The only methods that work before initialization are `checkPermissions()` and `setLoggingDestinations()`.
- Calling `initialize()` again after it succeeded is ignored, so it's safe to call on every launch.
- If `initialize()` fails, you can call it again.
- After the first successful `initialize()`, the SDK refreshes its configuration every 7 days when online, and otherwise keeps using the last one it downloaded. So later launches work offline.

### 2. Check and request permissions

The SDK needs Bluetooth and Local Network access to talk to the crew's device. Before anything else, add the usage descriptions, `NSBonjourServices` and Background Modes described in [Configuring Permissions](README.md#configuring-permissions).

Use `checkPermissions()` to find out what's missing and show your own explanation screen:

```swift
let result = await InseatAPI.shared.checkPermissions()

switch result {
case .success:
    // Bluetooth access granted.
    break

case .failure(let missingPermissions):
    for permission in missingPermissions {
        switch (permission.type, permission.reason) {
        case (_, .notDetermined):
            // Not asked yet: show your explanation screen, then trigger the system prompt.
            break
        case (_, .denied):
            // Denied: explain why it's needed and link to the app's Settings page.
            if let url = URL(string: UIApplication.openSettingsURLString) {
                await UIApplication.shared.open(url)
            }
        default:
            break
        }
    }
}
```

Notes:

- By default only Bluetooth is checked. iOS has no API to read the Local Network permission without using the network, so checking it **shows the system permission alert** if the user hasn't been asked yet. Only opt in when you're ready to show that alert:

  ```swift
  let options = PermissionCheckOptions(requiresLocalNetworkStatusCheck: true)
  let result = await InseatAPI.shared.checkPermissions(options: options)
  ```

  With this option the call **waits until the passenger answers the alert**, so don't block your UI on it. Local Network is only ever reported as `.denied`; `.notDetermined` applies to Bluetooth only.

- The system prompts also appear on their own the first time `start()` uses Bluetooth and the local network. Calling `checkPermissions()` first lets you explain them to the passenger beforehand.
- `checkPermissions()` checks whether access is **granted**, not whether Bluetooth is **switched on**. See [How do I check whether Bluetooth is switched on?](#how-do-i-check-whether-bluetooth-is-switched-on)

### 3. Show the shop status

Observe the shop and update your UI based on its status:

```swift
private var shopObserver: Observer?

func observeShop() throws {
    shopObserver = try InseatAPI.shared.observeShop { shop in
        guard let shop else {
            // No flight opened by the crew yet: show "Shop not available".
            return
        }
        switch shop.status {
        case .open:
            // Passengers can browse the catalog but can't order yet.
            break
        case .order:
            // Passengers can browse and place orders.
            break
        case .closed:
            // Shop closed: hide or disable ordering.
            break
        @unknown default:
            break
        }
    }
}
```

Notes:

- Keep the returned `Observer` in a property for the whole session, even on screens that don't show the shop status. When it's released, the callback stops, and so does stock and order syncing for the flight.
- If the crew's device hasn't been seen for longer than `shopAutoCloseTimeoutInSeconds` (120 seconds by default), the SDK reports the shop as `.closed`, whatever the crew last set.
- `shop.crewLastSeen` is the last time the crew's device was in touch, if you want to show it.

### 4. Show menus, categories, products and currencies

```swift
private var categoriesObserver: Observer?
private var productsObserver: Observer?

func selectMenu() async throws {
    // 1. Pick the menu for this passenger (for example by flight or cabin), before registering observers.
    let menus = try await InseatAPI.shared.fetchMenus()
    if let menu = menus.first {
        InseatAPI.shared.setUserData(UserData(menu: menu))
    }
}

func loadCatalog() async throws {
    // 2. Currencies the passenger can pay in, in display order.
    let currencies = try await InseatAPI.shared.fetchCurrencies()

    // 3. Categories for the selected menu's airline.
    categoriesObserver = try InseatAPI.shared.observeCategories { categories in
        // Each category has its subcategories (one level deep).
    }

    // 4. Products, optionally for one category and its subcategories.
    productsObserver = try InseatAPI.shared.observeProducts(category: nil) { products in
        // product.prices has one price per currency.
        // product.quantity is the stock on this flight (see notes).
    }
}
```

Notes:

- Use `observe*` for screens that stay on screen (stock and products change during the flight). Use `fetch*` for one-off reads.
- Select the menu with `setUserData()` before reading categories and products, otherwise products from every menu are returned. `setUserData()` applies the menu asynchronously, so a `fetch*` called on the very next line may still use the previous menu. Set the menu once (for example at start-up) and read the catalog afterwards.
- If the passenger switches menu later, you don't need to register the observers again: `observeProducts()` and `observeCategories()` deliver the new menu's data automatically. Only an `observeProducts()` registered for a specific `category` keeps that category, so register it again with a category from the new menu.
- Products are filtered by the selected menu. Categories and currencies are filtered by the menu's airline (`companyId`), so all menus of the same airline share them.
- `product.quantity` is the stock on the current flight. While the shop is `nil`, ignore `product.quantity`: until the crew opens the shop it is always `0`. Decide what the passenger can do (browse only, order, or nothing) from the shop's `status` only, never from `quantity` (see [Show the shop status](#3-show-the-shop-status)).
- Once the crew opens a flight, the product list and prices come from what the crew loaded for that flight.
- To show the price in the passenger's currency, pick it from `product.prices` by currency code:

  ```swift
  let price = product.prices.first { $0.currency == selectedCurrency.code }
  ```

### 5. Build a basket and apply promotions

The SDK doesn't store the basket: your app keeps it. Turn each basket line into a `CartItem`, and ask the SDK which promotions apply every time the basket or currency changes.

```swift
struct BasketLine {
    let product: Product
    var quantity: Int
}

func cartItems(from lines: [BasketLine]) -> [CartItem] {
    lines.map {
        CartItem(
            id: $0.product.id,
            masterId: $0.product.masterId,
            name: $0.product.name,
            quantity: $0.quantity,
            prices: $0.product.prices
        )
    }
}

func basketTotals(lines: [BasketLine], currency: OperatingCurrency) async throws
    -> (subtotal: Decimal, saving: Decimal, total: Decimal, promotions: [AppliedPromotion]) {

    let result = try await InseatAPI.shared.applyPromotions(
        to: cartItems(from: lines),
        currency: currency.code
    )

    let subtotal = lines.reduce(Decimal.zero) { sum, line in
        let unitPrice = line.product.prices.first { $0.currency == currency.code }?.amount ?? .zero
        return sum + unitPrice * Decimal(line.quantity)
    }

    let saving = result.appliedPromotions.reduce(Decimal.zero) { sum, promotion in
        switch promotion.benefitType {
        case .discount(let totalSaving):
            return sum + totalSaving.amount
        case .coupon:
            return sum // A printed coupon after the order, no immediate saving.
        }
    }

    return (subtotal, saving, subtotal - saving, result.appliedPromotions)
}
```

Notes:

- Every item in the basket must have a price in the selected currency. If one doesn't, `applyPromotions()` returns no promotions.
- Use `fetchPromotions()` and `fetchPromotionCategories()` to show a list of available promotions.
- For a "build your own deal" screen, use `applyPromotion(promotion:to:currency:)` to check one specific promotion against the items the passenger picked. It applies that promotion at most once and ignores all others.
- The promotion methods never fail on missing data: if something goes wrong they return an empty list. They only throw `.notInitialized`.

### 6. Place an order and track its status

```swift
private var ordersObserver: Observer?

func placeOrder(lines: [BasketLine], currency: OperatingCurrency, seatNumber: String) async throws {
    guard let shop = try await InseatAPI.shared.fetchShop(), shop.status == .order else {
        // Shop isn't taking orders: tell the passenger.
        return
    }

    let totals = try await basketTotals(lines: lines, currency: currency)

    let order = Inseat.Order(
        id: UUID().uuidString,
        shiftId: shop.shiftId,
        seatNumber: seatNumber,
        items: lines.map { line in
            Inseat.Order.Item(
                id: line.product.id,
                name: line.product.name,
                quantity: line.quantity,
                price: Inseat.Order.Price(
                    amount: line.product.prices.first { $0.currency == currency.code }?.amount ?? .zero
                )
            )
        },
        appliedPromotions: totals.promotions,
        orderCurrency: currency.code,
        totalPrice: Inseat.Order.Price(amount: totals.total)
    )

    try await InseatAPI.shared.createOrder(order)
    // The order is saved and will be sent to the crew. It is NOT confirmed yet.
}

func observeOrders() throws {
    ordersObserver = try InseatAPI.shared.observeOrders { orders in
        for order in orders {
            switch order.status {
            case .placed:               break // Waiting for the crew to receive it.
            case .received:             break // Crew has the order.
            case .preparing:            break // Crew is preparing it.
            case .completed:            break // Delivered and paid.
            case .cancelledByPassenger: break
            case .cancelledByCrew:      break
            case .cancelledByTimeout:   break // Crew never received it; ask the passenger to try again.
            case .refunded:             break
            @unknown default:           break
            }
        }
    }
}
```

Notes:

- `createOrder()` succeeding means the order was saved on the device. Whether the crew accepted it only shows up in `observeOrders()`.
- The SDK doesn't check the shop status or the totals you pass: check `shop.status == .order` and calculate the total yourself, as above.
- `status`, `createdAt` and `updatedAt` are set by the SDK: a new order is stored as `.placed`, with the current time as both dates.
- If an order stays `.placed` for longer than the order confirmation timeout (120 seconds by default), the SDK changes it to `.cancelledByTimeout`. This only happens while the SDK is started; orders that ran out of time while it was stopped or the app was closed are cancelled as soon as `start()` is called again. Set the timeout with `orderConfirmationTimeoutDelayInSeconds` in `Configuration`.
- Use a unique identifier for every order (preferably `UUID().uuidString`).
- Register `observeOrders()` whenever it's needed, for example each time the orders screen opens. It reads the orders stored on the device, including ones placed before the app was closed. Status updates keep syncing in the background while the SDK is started and `observeShop()` is alive, whether or not an `observeOrders()` observer is registered.
- Status updates arrive in the background while the SDK is started, with or without an `observeOrders()` observer. Order syncing begins once `observeShop()` has received the current shop in this app session (see [How the SDK works](#how-the-sdk-works)).

### 7. Cancel an order

```swift
try await InseatAPI.shared.cancelOrder(id: order.id)
// observeOrders then reports the order as .cancelledByPassenger.
```

The SDK doesn't stop you from cancelling an order in any status, so only offer the cancel button while the crew hasn't started on it: when the status is `.placed` or `.received`.

### 8. Keep product data up to date

Call `syncProductData()` on every launch and when the app comes back to the foreground with internet. It only downloads data when something changed on the server.

```swift
try await InseatAPI.shared.syncProductData()

let lastChecked = InseatAPI.shared.lastProductSyncDate     // last successful check, changed or not
let lastChanged = InseatAPI.shared.lastProductUpdateDate   // last time new data was downloaded
```

Open `observe*` callbacks are called again after a sync that downloaded changes. While the new data is being saved they may be called several times, briefly with empty or partial lists, so don't treat a single empty callback as "no products". Promotions can't be observed: call `fetchPromotions()` again after a sync.

### 9. Collect SDK logs

By default the SDK logs to the console. To send its logs to your own logging tool:

```swift
final class AppLoggingDestination: LoggingDestination {
    func log(_ level: LogLevel, _ message: String) {
        // Forward to your logger, e.g. only .error and .critical in production.
    }
}

InseatAPI.shared.setLoggingDestinations([
    AppLoggingDestination()
])
```

`setLoggingDestinations()` replaces the default console output, so print the messages in your destination too if you still want them in the Xcode console.

Include these logs when reporting a problem to Immfly.

### 10. Stop and restart the SDK

```swift
InseatAPI.shared.stop()          // stops syncing with the crew's device
try await InseatAPI.shared.start() // resumes syncing
```

`stop()` only stops syncing. The SDK stays initialized, so you can still read local data and call `start()` again later without calling `initialize()`. While stopped, new orders aren't sent to the crew, statuses don't update, and orders aren't cancelled by timeout until `start()` is called again.

---

## FAQ

### Setup & Initialization

#### In what order should I call `initialize()`, `syncProductData()` and `start()`?

`initialize()` first, then `syncProductData()`, then `start()`, then register `observeShop()` and keep it. Only `initialize()` must finish before the others. See [Start the SDK on app launch](#1-start-the-sdk-on-app-launch).

#### Why do I get `initializationError(.notInitialized)`?

You called an SDK method before `initialize()` finished successfully, or `initialize()` threw an error. Wait for `initialize()` to return before calling anything else, and retry it if it failed.

#### Why does `initialize()` fail with `initializationError(.initializationFailure)`?

On the first launch after install, `initialize()` downloads its configuration from the Inseat API. It fails if the device has no internet, the server doesn't respond within 10 seconds, or the API key is wrong for the selected environment. Retry when the device is online. After one successful `initialize()`, later launches reuse the downloaded configuration when offline.

#### Does the passenger need internet?

Only for the first `initialize()` after install and for `syncProductData()`. Browsing, the shop status and ordering on board work without internet, through Bluetooth and the local network.

#### What's the difference between `.test` and `.live`?

| Environment | Inseat API server | API key | Use for |
|---|---|---|---|
| `.test` | Test | Your test API key | Development and QA builds |
| `.live` | Production | Your live API key | The App Store build |

When you switch environment or API key on a device, **delete and reinstall the app**, otherwise it can keep using the previous environment's configuration.

#### How do I stop the SDK, and can I use it again afterward?

Call `stop()`. You can call `start()` again at any time without calling `initialize()` again. See [Stop and restart the SDK](#10-stop-and-restart-the-sdk).

#### How do I know when the catalog last changed vs. when it was last checked?

| Property | Updated when | `nil` until |
|---|---|---|
| `lastProductUpdateDate` | New data was downloaded | The first sync that downloads data |
| `lastProductSyncDate` | The SDK checked successfully, even if nothing had changed | The first successful sync |

### Catalog & Menu

#### How do I fetch the menu, categories and products?

See [Show menus, categories, products and currencies](#4-show-menus-categories-products-and-currencies).

#### Why don't some products show up?

Check these, in order:

1. **No product data yet.** `syncProductData()` must have succeeded at least once.
2. **Another menu is selected.** Only products from the menu set with `setUserData()` are returned.
3. **Category too deep.** Only products in level 1 or level 2 categories are returned. Products in a third-level category are left out.
4. **Not on this flight.** Once the crew opens a flight, only the products loaded for that flight are returned.
5. **Category from the previous menu.** An existing `observeProducts()` observer updates by itself when the menu changes, but if it was registered for a specific `category`, it keeps that category. Register it again with a category from the new menu.

Sold-out products are still returned, with `quantity == 0`. Before the crew opens a flight every product has `quantity == 0`.

#### How do I choose which menu is shown to the passenger?

Fetch the menus with `fetchMenus()`, pick one, and pass it to `setUserData(UserData(menu:))` before reading the catalog. Products and promotions are then filtered by that menu; categories and currencies by the menu's airline. If you change the menu later, existing observers deliver the new menu's data without being registered again (except a category-filtered `observeProducts()`). See the notes in [use case 4](#4-show-menus-categories-products-and-currencies).

#### How do I get the currencies the passenger can pay in?

Call `fetchCurrencies()`. The list is already sorted in the order to display it. Use `currency.code` to pick product prices and to apply promotions.

### Shop Status

#### How do I know if the shop is open, closed or taking orders?

Observe the shop and check its `status`:

| Shop | Browse | Order | Meaning |
|---|---|---|---|
| `nil` | No | No | The crew hasn't opened a flight yet |
| `.open` | Yes | No | Browse only |
| `.order` | Yes | Yes | Browse and order |
| `.closed` | No | No | Shop closed |

See [Show the shop status](#3-show-the-shop-status).

#### How do I tell when the crew was last active?

Read `shop.crewLastSeen`. The crew's device updates it regularly while it's in touch. If it's older than `shopAutoCloseTimeoutInSeconds`, the SDK reports the shop as `.closed`.

#### Why does the shop show as closed when the crew says it's open?

The passenger's device hasn't heard from the crew's device for longer than `shopAutoCloseTimeoutInSeconds`. Check the [sync checklist](#why-doesnt-the-app-sync-with-the-crews-device).

### Basket, Promotions & Checkout

#### How do I build a basket before checkout?

Your app keeps the basket. Convert it to `[CartItem]` to apply promotions and to `Order.Item`s to place the order. See [Build a basket and apply promotions](#5-build-a-basket-and-apply-promotions).

#### How do I apply promotions to a basket?

Call `applyPromotions(to:currency:)` every time the basket or currency changes, and pass the returned `appliedPromotions` into the order.

#### Can more than one promotion apply to the same basket?

Yes, with `applyPromotions()`:

| Method | Promotions checked | Times each can apply |
|---|---|---|
| `applyPromotions(to:currency:)` | All of them | As many times as the basket allows |
| `applyPromotion(promotion:to:currency:)` | Only the one you pass | At most once |

Each basket item counts towards at most one product-based promotion and one spend-based promotion.

#### Why does `applyPromotions()` return nothing?

Either no promotion's conditions are met, or at least one basket item has no price in the selected currency.

#### What's the difference between a discount and a coupon promotion?

| Type | Changes the basket total? | What the passenger gets | What you do |
|---|---|---|---|
| `.discount` | Yes, right away | A lower price | Subtract `totalSaving` from the basket total |
| `.coupon` | No | A printed coupon after the order is completed | Show the coupon offer; keep the full price |

### Orders

#### How do I place an order, and how do I know if it succeeded?

Call `createOrder()`. If it doesn't throw, the order was saved on the device. Whether the crew accepted it shows up in `observeOrders()` as `.received`, or as `.cancelledByTimeout` if the crew never got it. See [Place an order and track its status](#6-place-an-order-and-track-its-status).

#### What statuses can an order have?

| Status | Meaning |
| --- | --- |
| `.placed` | Created by the passenger, waiting for the crew |
| `.received` | Received by the crew |
| `.preparing` | Being prepared by the crew |
| `.completed` | Delivered and paid |
| `.cancelledByPassenger` | Cancelled with `cancelOrder()` |
| `.cancelledByCrew` | Cancelled by the crew |
| `.cancelledByTimeout` | Not received by the crew in time |
| `.refunded` | Refunded by the crew |

#### How do I show past and current orders?

Use `observeOrders()`. It returns orders created **on this device** in the **last 24 hours**, including those placed before the app was closed.

#### How do I show previous orders after the app is relaunched?

Orders are stored on the device, so they survive the app being closed or killed. Run the usual start-up sequence (`initialize()`, `start()`, `observeShop()`) and keep the `observeShop()` observer: that resumes syncing with the crew's device, so pending orders keep receiving status updates. Register `observeOrders()` whenever you show the orders; it reads them from the device.

```swift
try await InseatAPI.shared.initialize(configuration: configuration)
try await InseatAPI.shared.start()
shopObserver = try InseatAPI.shared.observeShop { shop in
    // Update the shop status UI
}
ordersObserver = try InseatAPI.shared.observeOrders { orders in
    // Show the orders, pending ones included
}
```

Notes:

- The 24-hour window is based on the order's original `createdAt`, counted back from when `observeOrders()` is called.
- Orders belong to the app's `identifierForVendor`. If the user uninstalls every app from your team, iOS resets it and the previous orders aren't shown anymore. In the rare case iOS doesn't provide `identifierForVendor` (for example right after a device restart, before first unlock), orders from that session won't reappear after a relaunch.

#### How do I cancel an order?

Call `cancelOrder(id:)`. Only offer it while the order is `.placed` or `.received`. See [Cancel an order](#7-cancel-an-order).

#### Why was my order cancelled by timeout?

The crew's device didn't receive it within the order confirmation timeout (120 seconds by default), usually because the two devices weren't in touch or no `observeShop()` observer was alive. Check the [sync checklist](#why-doesnt-the-app-sync-with-the-crews-device).

### Permissions & Connectivity

#### What permissions does the SDK need?

Bluetooth and Local Network. Add the Info.plist keys and Background Modes from [Configuring Permissions](README.md#configuring-permissions), then use `checkPermissions()` as shown in [Check and request permissions](#2-check-and-request-permissions).

#### How do I check whether Bluetooth is switched on?

The SDK only checks whether access is granted. To check whether Bluetooth is on, use Core Bluetooth directly:

```swift
import CoreBluetooth

final class BluetoothStateMonitor: NSObject, CBCentralManagerDelegate {
    private var manager: CBCentralManager!
    var onChange: ((Bool) -> Void)?

    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        onChange?(central.state == .poweredOn)
    }
}
```

Creating a `CBCentralManager` asks for Bluetooth permission if it hasn't been asked yet.

#### Why doesn't the app sync with the crew's device?

The SDK doesn't report connection problems as errors. When the shop stays `nil` or `.closed`, or orders are cancelled by timeout, check:

1. Bluetooth and Local Network access are granted (`checkPermissions()`).
2. Bluetooth is switched on.
3. The Info.plist contains the usage descriptions and `NSBonjourServices` with `_http-alt._tcp.`.
4. The Background Modes "Acts as Bluetooth LE Accessory" and "Uses Bluetooth LE accessories" are enabled.
5. `start()` was called and didn't throw.
6. An `observeShop()` observer is registered after `start()` and kept in memory.
7. The flight's ICAO code is in `supportedICAOs`, in upper case.
8. The app and the crew's device use the same environment (`.test` or `.live`). If you switched environment on this device, reinstall the app.
9. The crew has opened a flight in the last 24 hours, and their device is nearby and active (`shop.crewLastSeen`).

If all of these are fine, collect the SDK logs (see [Collect SDK logs](#9-collect-sdk-logs)) and share them with Immfly.

### Building your own UI

#### Which screens do I need to build?

- A permissions explanation screen ([use case 2](#2-check-and-request-permissions))
- Shop status handling: not available / browse only / ordering ([use case 3](#3-show-the-shop-status))
- Menu selection, category list and product list with sold-out state ([use case 4](#4-show-menus-categories-products-and-currencies))
- A currency selector
- The basket, with totals, savings and promotions ([use case 5](#5-build-a-basket-and-apply-promotions))
- A promotions list, and optionally a "build your deal" screen
- Checkout with seat number entry ([use case 6](#6-place-an-order-and-track-its-status))
- An orders list with live statuses and cancellation ([use cases 6 and 7](#7-cancel-an-order))

### Errors & Troubleshooting

#### What errors can the SDK throw, and how should I handle them?

SDK methods throw `InseatError`. A few never throw: `checkPermissions()`, `stop()`, `setUserData()` and `setLoggingDestinations()`. The promotion methods (`fetchPromotions()`, `fetchPromotionCategories()`, `applyPromotions()`, `applyPromotion()`) only throw `.notInitialized` and return an empty result on any other problem.

| Error | When | What to do |
| --- | --- | --- |
| `initializationError(.notInitialized)` | A method was called before `initialize()` succeeded | Call `initialize()` first and wait for it |
| `initializationError(.initializationFailure)` | `initialize()` couldn't download its configuration or set up storage | Retry when online; check the API key and environment |
| `synchronizationError(.syncActivationFailure)` | `start()` couldn't start syncing | Retry `start()`; collect logs if it keeps failing |
| `synchronizationError(.subscriptionRegistrationFailure)` | `start()` couldn't subscribe to shop data | Retry `start()`; collect logs if it keeps failing |
| `networkError(.downloadFailure)` | `syncProductData()` couldn't download data | Retry when online; the previous catalog stays available |
| `serializationError(.decodingFailure(source:))` | Downloaded data couldn't be read | Collect logs and contact Immfly |
| `storeError(.observerRegistrationError)` | An `observe*` method failed | Retry; collect logs if it keeps failing |
| `storeError(.fetchingError)` | A `fetch*` method failed | Retry; collect logs if it keeps failing |
| `storeError(.insertError)` | `createOrder()` couldn't save the order | Show an error and let the passenger try again |
| `storeError(.updateError)` | `cancelOrder()` couldn't update the order | Show an error and let the passenger try again |

#### Why did my observer stop receiving updates?

The `Observer` returned by an `observe*` method was released. Keep it in a property for as long as you want updates, and call `cancel()` or set it to `nil` to stop them.

```swift
private var productsObserver: Observer?  // keep a strong reference
```

#### Where do I find the SDK logs?

In the Xcode console by default, unless you replaced it with `setLoggingDestinations()`. To send them to your own logging tool, see [Collect SDK logs](#9-collect-sdk-logs).
