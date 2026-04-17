# Inseat iOS SDK Documentation

This document provides comprehensive documentation for the Inseat iOS SDK methods and errors.

## Table of Contents

- [Installing Package Dependency](#installing-package-dependency)
- [Configuring Permissions](#configuring-permissions)
- [Initialization Methods](#initialization-methods)
- [Synchronization Methods](#synchronization-methods)
- [Data Management Methods](#data-management-methods)
- [Shop Information Methods](#shop-information-methods)
- [Currency Methods](#currency-methods)
- [Product Management Methods](#product-management-methods)
- [Order Management Methods](#order-management-methods)
- [Promotion Management Methods](#promotion-management-methods)
- [Utilities Methods](#utilities-methods)
- [Permission Methods](#permission-methods)
- [Error Types](#error-types)
- [Data Models](#data-models)

---

## Installing Package Dependency

### SPM Authentication

Inseat Swift Package contains private dependencies. You must add `.netrc` file into user's root directory for authentication. Include the following content into your file:

```
machine app-cdn.immflyretail.live
login {your login}
password {your password}
```

After that SPM will be able to download private dependencies successfully.


### Configure Xcode

1. Click `File`, and then select `Add Package Dependencies` from the menu.
2. In the modal window:

- Paste the following URL into the search box in the upper-right corner: https://github.com/ImmflyRetail/inseat-sdk-ios
- Select `inseat-sdk-ios` from the list
- Click `Add Package`

3. From the `Choose Package Products for inseat-sdk-ios` modal window:

- Click `Add to Target` and select your app from the list
- Click `Add Package`


### Configuring Permissions

1. Configure `Info.plist`

1.1 Add usage descriptions

- `NSBluetoothPeripheralUsageDescription`
- `NSBluetoothAlwaysUsageDescription`
- `NSLocalNetworkUsageDescription`

1.2 Add NSBonjourServices

```xml
<key>NSBonjourServices</key>
<array>
    <string>_http-alt._tcp.</string>
</array>
```

So your raw plist file should look like:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Uses Bluetooth to connect and sync with POS devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Uses Bluetooth to connect and sync with POS devices</string>
<key>NSLocalNetworkUsageDescription</key>
<string>Uses WiFi to connect and sync with POS devices</string>
<key>NSBonjourServices</key>
<array>
  <string>_http-alt._tcp.</string>
</array>
```


2. Add the following 'Background Modes' in `Signing & Capabilities`:

```
Acts as Bluetooth LE Accessory
Used Bluetooth LE accessories
```


3. (Optional) Set Protection Entitlement

- If enabling the `Data Protection entitlement`, allow access after the end user has unlocked their device for the first time after a system restart by setting the entitlement to `NSFileProtectionCompleteUntilFirstUserAuthentication`.
- For more information, see the official Apple documentation for [Data Protection Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.default-data-protection).

---


## SDK Methods Summary

| Method Name               | Description                                                             |
| ------------------------- | ----------------------------------------------------------------------- |
| `initialize`              | Initializes the Inseat SDK with configuration parameters                |
| `start`                   | Starts syncing data with POS devices via BLE mesh network               |
| `stop`                    | Stops syncing data with POS devices and shuts down the SDK service      |
| `syncProductData`         | Downloads and caches product data from the server API using HTTP ETag caching          |
| `lastProductSyncDate`     | Returns the date of the last successful `syncProductData` call (200 or 304)     |
| `lastProductUpdateDate`   | Returns the date of the last `syncProductData` call that downloaded new data (200 OK) |
| `observeShop`             | Subscribes to shop status updates and receives real-time notifications  |
| `fetchShop`               | Fetches shop data once (one-time operation)                             |
| `observeMenus`            | Subscribes to menu updates and receives real-time notifications         |
| `fetchMenus`              | Fetches available shop menus once                                       |
| `setUserData`             | Sets the selected menu for filtering products                           |
| `observeCategories`       | Subscribes to category updates and receives real-time notifications     |
| `fetchCategories`         | Fetches available shop categories once                                  |
| `fetchCurrencies`         | Fetches available operating currencies once                             |
| `observeProducts`         | Subscribes to product updates and receives real-time notifications      |
| `fetchProducts`           | Fetches available shop products once                                    |
| `createOrder`             | Creates an order and sends it to the POS application                    |
| `observeOrders`           | Subscribes to order status updates and receives real-time notifications |
| `cancelOrder`             | Cancels an existing order and sends information to the POS application  |
| `fetchPromotions`         | Fetches all available promotions for the current shop                   |
| `fetchPromotionCategories`| Fetches all available promotions for the current shop                   |
| `applyPromotions`         | Calculates applied promotions based on list of cart items and selected currency  |
| `applyPromotion`          | Tries to apply one concrete promotion based on a list of cart items and selected currency. This method is supposed to be used when constructing promotion from Promotion Builder UI flow.    |
| `setLoggingDestinations`  | Specified the logging output destination for Inseat SDK                 |
| `checkPermissions`        | Checks if the SDK has necessary permissions to operate                  |


## Initialization Methods

### `initialize`

**Description:**

- Initializes the Inseat SDK with the provided configuration parameters. This method should be called when the app is launched before accessing any other method.
- On the first call the SDK fetches metadata from the API (Ditto configuration + product data URLs) and caches the response for **7 days**. Subsequent calls within that window skip the network request and initialize from cache instantly. The cache is automatically refreshed after 7 days or on app reinstall.

**Signature:**

```swift
func initialize(configuration: Configuration) async throws
```

**Parameters:**

- `configuration` - Configuration object containing:
  - `apiKey` - API key for authentication
  - `supportedICAOs` - Array of supported ICAO codes (uppercased)
  - `environment` - Environment type (`.test` or `.live`)
  - `shopAutoCloseTimeoutInSeconds` - Timeout for shop being open (default: 120 seconds)
  - `orderConfirmationTimeoutDelayInSeconds` - Timeout for order operations (default: 120 seconds)

**Return Type:** 

- `Void` (throws on error)

**Errors:** 

- `InseatError.initializationError(.initializationFailure)`

**Example:**

```swift
let configuration = Configuration(
    apiKey: "{API_KEY}",
    supportedICAOs: ["{ICAO_UPPERCASED}"],
    environment: .live
)
try await InseatAPI.shared.initialize(configuration: configuration)
```

---

## Synchronization Methods

### `start`

**Description:** 

- Starts syncing data with POS devices via BLE mesh network.

**Signature:**

```swift
func start() async throws
```

**Return Type:** 

- `Void` (throws on error)

**Errors:** 

- `InseatError.initializationError(.notInitialized)`
- `InseatError.synchronizationError(.syncActivationFailure)`
- `InseatError.synchronizationError(.subscriptionRegistrationFailure)`

**Example:**

```swift
try InseatAPI.shared.start()
```

### `stop`

**Description:** 

- Stops syncing data with POS devices and shuts down the SDK service.

**Signature:**

```swift
func stop()
```

**Return Type:** 

- `Void`

**Errors:** 

- None

**Example:**

```swift
InseatAPI.shared.stop()
```

---

## Data Management Methods

### `syncProductData` (completion-based)

**Description:**

- Downloads and caches product data from the API using **HTTP ETag caching**. On the first call the full payload is downloaded and the server's `ETag` is stored. On subsequent calls the SDK sends `If-None-Match` with the stored ETag — if the content has not changed the server responds with `304 Not Modified` (no data transfer) and the call completes immediately. If new data has been published the server responds with `200 OK`, the payload is processed, a new ETag is stored, and `lastProductSyncDate` is updated.

**Signature:**

```swift
func syncProductData(completion: ((Result<Void, InseatError>) -> Void)?)
```

**Parameters:**

- `completion` - Optional callback with result

**Return Type:** 

- `Void` (result via completion callback)

**Errors:** 

- `InseatError.initializationError(.notInitialized)`
- `InseatError.networkError(.downloadFailure)`
- `InseatError.serializationError(.decodingFailure)`

**Example:**

```swift
InseatAPI.shared.syncProductData { result in
    print("Did sync data with result='\(result)'")
}
```

### `syncProductData` (concurrent)

**Description:**

- Downloads and caches product data from the API using **HTTP ETag caching**. On the first call the full payload is downloaded and the server's `ETag` is stored. On subsequent calls the SDK sends `If-None-Match` with the stored ETag — if the content has not changed the server responds with `304 Not Modified` (no data transfer) and the call completes immediately. If new data has been published the server responds with `200 OK`, the payload is processed, a new ETag is stored, and `lastProductSyncDate` is updated.

**Signature:**

```swift
func syncProductData() async throws
```

**Return Type:** 

- `Void`

**Errors:** 

- `InseatError.initializationError(.notInitialized)`
- `InseatError.networkError(.downloadFailure)`
- `InseatError.serializationError(.decodingFailure)`

**Example:**

```swift
do {
    try await InseatAPI.shared.syncProductData()
} catch {
    print("[ERROR]: product sync failed due to error: \(error)")
}
```

### `lastProductSyncDate`

**Description:**

- Returns the date of the last `syncProductData` call that completed successfully, including calls that resulted in `304 Not Modified` (content unchanged). Returns `nil` if `syncProductData` has never been called successfully. Can be used to display when the SDK last checked for new product data.

**Signature:**

```swift
var lastProductSyncDate: Date? { get }
```

**Return Type:**

- `Date?` — Date of last successful sync attempt, or `nil` if never synced

**Example:**

```swift
if let lastSync = InseatAPI.shared.lastProductSyncDate {
    print("Last sync: \(lastSync.formatted(.dateTime.month(.abbreviated).day().year().hour().minute().second()))")
}
```

### `lastProductUpdateDate`

**Description:**

- Returns the date of the last `syncProductData` call that downloaded new data from the API (`200 OK`). Returns `nil` if new data has never been received (e.g. fresh install or all syncs returned `304 Not Modified`). Only updated when content actually changed on the server. Can be used to display when product data was last refreshed.

**Signature:**

```swift
var lastProductUpdateDate: Date? { get }
```

**Return Type:**

- `Date?` — Date of last actual data download, or `nil` if never received new data

**Example:**

```swift
if let lastUpdate = InseatAPI.shared.lastProductUpdateDate {
    print("Last update: \(lastUpdate.formatted(.dateTime.month(.abbreviated).day().year().hour().minute().second()))")
}
```

---

## Shop Information Methods

### `observeShop`

**Description:** 

- Subscribes to shop status updates and receives real-time notifications.

**Signature:**

```swift
func observeShop(observer: @escaping (Shop?) -> Void) throws -> Observer
```

**Parameters:**

- `observer` - Callback function triggered when shop object is updated

**Return Type:** 

- `Observer` - Observer instance that must be retained in memory

**Errors:** 

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.observerRegistrationError)`

**Example:**

```swift
shopObserver = try InseatAPI.shared.observeShop { shop in
    guard let shop = shop else {
        // If 'shop' is nil it means that flight hasn't been opened yet.
        return
    }
    switch shop.status {
    case .open:
        ...

    case .order:
        ...

    case .closed:
        ...

    @unknown default:
        break
    }
    
    // Do whatever you prefer with 'crewLastSeen' date. It indicates the last known time when POS application was active.
    let lastSeenDate = shop.crewLastSeen
}
```

**IMPORTANT:**
The Observer stays active while you hold a strong reference to it, for example as a property in a class. The same is true for any other observing functionality of Inseat.

```swift
// Observer is cancelled after this reference is removed from memory.
private var shopObserver: Observer?
```


### `fetchShop`

**Description:**

- Fetches shop data once (one-time operation).

**Signature:**

```swift
func fetchShop() async throws -> Shop?
```

**Return Type:** 

- `Shop?` - Optional Shop object

**Errors:** 

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.fetchingError)`

**Example:**

```swift
let shop = try await InseatAPI.shared.fetchShop()
```


### `observeMenus`

**Description:**

- Subscribes to menu updates and receives real-time notifications.

**Signature:**

```swift
func observeMenus(observer: @escaping ([Menu]) -> Void) throws -> Observer
```

**Parameters:**

- `observer` - Callback function triggered when menus are updated (returns all menus, not just updated ones)

**Return Type:**

- `Observer` - Observer instance that must be retained in memory

**Errors:**

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.observerRegistrationError)`

**Example:**

```swift
menusObserver = try InseatAPI.shared.observeMenus { menus in
    ...
}
```


### `fetchMenus`

**Description:**

- Fetches available shop menus once.

**Signature:**

```swift
func fetchMenus() async throws -> [Menu]
```

**Return Type:**

- `[Menu]` - Array of Menu objects

**Errors:**

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.fetchingError)`

**Example:**

```swift
let menus = try await InseatAPI.shared.fetchMenus()
```


### `setUserData`

**Description:**

- Sets the selected menu for filtering products. Categories and products will be filtered based on the selected menu.

**Signature:**

```swift
func setUserData(_ userData: UserData)
```

**Parameters:**

- `userData` - UserData object containing menu selection

**Return Type:**

- `Void`

**Errors:**

- None

**Example:**

```swift
// First, fetch menus.
let menus = try await InseatAPI.shared.fetchMenus()
// Then choose your selected menu.
let selectedMenu = ...
let userData = UserData(menu: selectedMenu)
InseatAPI.shared.setUserData(userData)
```


### `observeCategories`

**Description:**

- Subscribes to category updates and receives real-time notifications. Categories are automatically filtered by the selected menu.

**Signature:**

```swift
func observeCategories(observer: @escaping ([Category]) -> Void) throws -> Observer
```

**Parameters:**

- `observer` - Callback function triggered when categories are updated (returns all categories, not just updated ones)

**Return Type:**

- `Observer` - Observer instance that must be retained in memory

**Errors:**

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.observerRegistrationError)`

**Example:**

```swift
categoriesObserver = try InseatAPI.shared.observeCategories { categories in
    ...
}
```


### `fetchCategories`

**Description:**

- Fetches available shop categories once.

**Signature:**

```swift
func fetchCategories() async throws -> [Category]
```

**Return Type:**

-  `[Category]` - Array of Category objects

**Errors:**

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.fetchingError)`

**Example:**

```swift
let categories = try await InseatAPI.shared.fetchCategories()
```

---

## Currency Methods

### `fetchCurrencies`

**Description:**

- Fetches available operating currencies once. Use this method to retrieve the list of currencies supported by the current shop.

**Signature:**

```swift
func fetchCurrencies() async throws -> [OperatingCurrency]
```

**Return Type:**

- `[OperatingCurrency]` - Array of OperatingCurrency objects

**Errors:**

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.fetchingError)`

**Example:**

```swift
let currencies = try await InseatAPI.shared.fetchCurrencies()
```

---

## Product Management Methods

### `observeProducts`

**Description:** 

- Subscribes to product updates and receives real-time notifications.

**Signature:**

```swift
func observeProducts(category: Category? = nil, observer: @escaping ([Product]) -> Void) throws -> Observer
```

**Parameters:**

- `category` - optional argument to filter products by selected category and its subcategories
- `observer` - Callback function triggered when products are updated (returns all products, not just updated ones)

**Return Type:** 

- `Observer` - Observer instance that must be retained in memory

**Errors:**

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.observerRegistrationError)`

**Example:**

```swift
productsObserver = try InseatAPI.shared.observeProducts { products in
    ...
}
```


### `fetchProducts`

**Description:**

- Fetches available shop products once.

**Signature:**

```swift
func fetchProducts(category: Category? = nil) async throws -> [Product]
```

**Parameters:**

- `category` - optional argument to filter products by selected category and its subcategories

**Return Type:** 

- `[Product]` - Array of Product objects

**Errors:**

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.fetchingError)`

**Example:**

```swift
let products = try await InseatAPI.shared.fetchProducts()
```

---

## Order Management Methods

### `createOrder`

**Description:**

- Creates an order and sends it to the POS application.

**Signature:**

```swift
func createOrder(_ order: Order) async throws
```

**Parameters:**

- `order` - Order object containing all order information

**Return Type:** 

- `Void` (throws on error)

**Errors:**

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.insertError)`

**Example:**

```swift
guard let shiftId = try await InseatAPI.shared.fetchShop()?.shiftId else {
    return
}
let order = Inseat.Order(
    id: UUID().uuidString,
    shiftId: shiftId,
    seatNumber: seatNumber,
    status: .placed,
    items: cart.items.map {
        Inseat.Order.Item(
            id: $0.id,
            name: $0.name,
            quantity: $0.quantity,
            price: Inseat.Order.Price(amount: $0.unitPrice)
        )
    },
    appliedPromotions: cart.appliedPromotions,
    orderCurrency: cart.currency.code,
    totalPrice: .init(amount: cart.totalPrice),
    createdAt: Date(),
    updatedAt: Date()
)

try await InseatAPI.shared.createOrder(order)
```


### `observeOrders`

**Description:**

- Subscribes to order status updates and receives real-time notifications.

**Signature:**

```swift
func observeOrders(observer: @escaping ([Order]) -> Void) throws -> Observer
```

**Parameters:**

- `observer` - Callback function triggered when orders are updated (returns all orders, not just updated ones)

**Return Type:**

-`Observer` - Observer instance that must be retained in memory

**Errors:**

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.observerRegistrationError)`

**Example:**

This observer is triggered when status changed for any order created on current device.

```swift
ordersObserver = try InseatAPI.shared.observeOrders { orders in
    ...
}
``` 


### `cancelOrder`

**Description:**

- Cancels an existing order and sends this information to the POS application.

**Signature:**

```swift
func cancelOrder(id: Order.ID) async throws
```

**Parameters:**

- `id` - Order ID (String type alias)

**Return Type:**

- `Void` (throws on error)

**Errors:**

- `InseatError.initializationError(.notInitialized)`
- `InseatError.storeError(.updateError)`

**Example:**

```swift
try await InseatAPI.shared.cancelOrder(id: orderId)
```


---

## Promotion Management Methods

### `fetchPromotions`

**Description:** 

- Fetches all available promotions for the current shop.

**Signature:**

```
func fetchPromotions() async throws -> [Promotion]
```

**Return Type:**

- `[Promotion]` - Array of Promotion objects

**Errors:**

- `InseatError.initializationError(.notInitialized)`  

**Example:**

```swift
let promotions = try await InseatAPI.shared.fetchPromotions()
```

### `fetchPromotionCategories`

**Description:** 

- Fetches all available promotion categories for the current shop.

**Signature:**

```
func fetchPromotionCategories() async throws -> [PromotionCategory]
```

**Return Type:**

- `[PromotionCategory]` - Array of PromotionCategory objects

**Errors:** 

- `InseatError.initializationError(.notInitialized)`  

**Example:**

```swift
let allPromotionCategories = try await InseatAPI.shared.fetchPromotionCategories()
```


### `applyPromotions`

**Description:** 

- Calculates applied promotions based on list of cart items and selected currency.

**Signature:**

```
func applyPromotions(to cartItems: [CartItem], currency: String) async throws -> PromotionResult
```

**Parameters:**

- `cartItems` - list of current cart/basket items
- `currency` - currently selected shop currency  

**Return Type:**

- `PromotionResult` - Result object with array of applied promotions  

**Errors:** 

- `InseatError.initializationError(.notInitialized)`  

**Example:**

```swift
let result = try await InseatAPI.shared.applyPromotions(to: cartItems, currency: selectedCurrency.code)
let appliedPromotions = result.appliedPromotions
```

### `applyPromotion`

**Description:** 

- Tries to apply one concrete promotion based on a list of cart items and selected currency. This method is supposed to be used when constructing promotion from Promotion Builder UI flow.

**Signature:**

```
func applyPromotion(promotion: Promotion, to cartItems: [CartItem], currency: String) async throws -> PromotionResult
```

**Parameters:**

- `promotion` - promotion object which we try to apply to the cart/basket
- `cartItems` - list of current cart/basket items
- `currency` - currently selected shop currency
  

**Return Type:** 

- `PromotionResult` - Result object with array of applied promotions (no other promotion except that one from input parameters can be returned here).  

**Errors:**

- `InseatError.initializationError(.notInitialized)`

**Example:**

```swift
let result = try await InseatAPI.shared.applyPromotions(promotion: promotion, to: cartItems, currency: selectedCurrency.code)
let appliedPromotions = result.appliedPromotions
```

---

## Permission Methods

### `checkPermissions`

**Description:** 

- Checks if the SDK has the necessary permissions to operate (Bluetooth, Local Network).

**Signature:**

```swift
func checkPermissions(options: PermissionCheckOptions = .default) async -> PermissionCheckResult
```

**Parameters:**

- `options` - Permission check options (default: `.default`)

**Return Type:** 

- `PermissionCheckResult` - Result indicating success or failure with missing permissions

**Errors:** 

- None (returns result enum)

**Example:**

```swift
let result = try await InseatAPI.shared.checkPermissions()
switch result {
case .success:
    // all permissions granted
    break
    
case .failure(let missingPermissions):
    break
}
```

---

## Utilities

### `setLoggingDestinations`

**Description:**

- Specified the logging output destination for Inseat SDK. The default log destination is ‘​​ConsoleLoggingDestination’.

**Signature:**

```
func setLoggingDestinations(_ destinations: [LoggingDestination])
```

**Parameters:**

- `destinations` - Array of logging destinations

**Return Type:**

- None

**Errors:**

- None

**Example:**

```swift
final class YourCustomLoggingDestination: LoggingDestination {

    func log(_ level: Inseat.LogLevel, _ message: String) {
        // ...
    }    
}

InseatAPI.shared.setLoggingDestinations([
    ConsoleLoggingDestination(),
    YourCustomLoggingDestination()
])
```

---

## Error Types

### `InseatError`

#### `initializationError(InitializationErrorReason)`

- `.notInitialized` - SDK is not initialized  
- `.initializationFailure` - Failed to configure sync layer

#### `synchronizationError(SynchronizationErrorReason)`

- `.syncActivationFailure` - Failed to start sync  
- `.subscriptionRegistrationFailure` - Failed to register subscriptions

#### `networkError(NetworkErrorReason)`

- `.downloadFailure` - Data download attempt failed

#### `storeError(StoreErrorReason)`

- `.observerRegistrationError` - Failed to register observer  
- `.fetchingError` - Failed to fetch data  
- `.insertError` - Failed to insert data  
- `.updateError` - Failed to update data  
- `.deleteError` - Failed to delete data  
- `.evictError` - Failed to evict data

#### `serializationError(SerializationErrorReason)`

- `.resourceNotExist` - Resource not found  
- `.decodingFailure` - Failed to decode data

---

## Data Models

### `Menu`

Represents a menu item.

- **key**: `String` — Unique identifier for the menu item.
- **icao**: `String` — ICAO code.
- **companyId**: `Int` — Company identifier.
- **displayName**: `[DisplayName]` — List of display names for the menu item in different locales.

### `DisplayName`

- **locale**: `String` — Locale code (e.g., "en", "es").
- **text**: `String` — Display name text in the specified locale.

### `Product`

Represents a product.

- **id**: `Int` — Product identifier.
- **masterId**: `Int` — Product master identifier.
- **categoryId**: `Int` — Category identifier.
- **name**: `String` — Product name.
- **description**: `String` — Product description.
- **type**: `Product.ProductType` — Product type.
- **image**: `UIImage?` — Product image.
- **prices**: `[Money]` — List of prices.
- **quantity**: `Int` — Available quantity in stock.
- **startDate**: `Date` — Availability start date.
- **endDate**: `Date` — Availability end date.

### `Product.ProductType`

Represents the Product type.

- **regular**: Standard product
- **virtual**: Virtual product
- **voucher**: Voucher

### `Category`

Represents a category.

- **categoryId**: `Int` — Category identifier.
- **name**: `String` — Category name.
- **sortOrder**: `Int?` — Sort order.
- **subcategories**: `[Category]` — List of subcategories (recursive structure).

### `Shop`

Represents a shop.

- **id**: `String` — Shop identifier.
- **shiftId**: `String` — Shift identifier.
- **status**: `Status` — Shop status (`open`, `order`, `closed`).
- **createdAt**: `Date` — Creation date.
- **crewLastSeen**: `Date` — Last crew seen timestamp.

### `Promotion`

Represents a promotion.

- **id**: `Promotion.ID` — Promotion's identifier.
- **name**: `String` — Promotion's name.
- **description**: `String` — Promotion's description.
- **image**: `UIImage?` — Promotion's image.
- **startDate**: `Date` — Promotion's start date.
- **endDate**: `Date` — Promotion's end date.
- **triggerType**: `Promotion.TriggerType` — Required condition to be satisfied for triggering the promotion.
- **discountType**: `Promotion.DiscountType` — Discount type: can be money based (immediate price discount - see 'percentage', 'amount', 'fixedPrice') or not (see 'coupon').
- **loyaltyPoints**: `Promotion.LoyaltyPoint?` — Miles points

### `CartItem`

Represents a product.

- **id**: `Int` — Product identifier.
- **masterId**: `Int` — Product master identifier.
- **name**: `String` — Product name.
- **quantity**: `Int` — Product quantity in the cart / basket.
- **prices**: `[Money]` — List of prices.

### `UserData`

Represents user data in the SDK.

- **menu**: `Menu` — Currently selected menu for the user.

### `Configuration`

Represents SDK configuration.

- **apiKey**: `String` — API key for authentication.
- **supportedICAOs**: `[String]` — Array of supported ICAO codes.
- **environment**: `Environment` — Environment type (`.test` or `.live`).
- **shopAutoCloseTimeoutInSeconds**: `TimeInterval` — Timeout for shop automatic closure (default: 120 seconds).
- **orderConfirmationTimeoutInSeconds**: `TimeInterval` — Timeout for order operations (default: 120 seconds).

### `Environment`

Represents the SDK environment.

- **test**: Test environment
- **live**: Production environment

### `Order`

Represents an order.

- **id**: `String` — Unique identifier for the order.
- **shiftId**: `String` — Shift identifier.
- **seatNumber**: `String` — Seat number.
- **status**: `Status` — Status of the order (`placed`, `received`, `preparing`, `cancelledByPassenger`, `cancelledByCrew`, `cancelledByTimeout`, `completed`).
- **items**: `[Order.Item]` — List of order items.
- **appliedPromotions**: `[Order.AppliedPromotion]` — List of promotions applied to the order.
- **orderCurrency**: `String` — Currency code.
- **totalPrice**: `Order.Price` — Total price.
- **createdAt**: `Date` — Creation date.
- **updatedAt**: `Date` — Last update date.

### `Order.Item`

- **id**: `Int` — Item identifier.
- **name**: `String` — Item name.
- **quantity**: `Int` — Quantity ordered.
- **price**: `Order.Price` — Price per unit.

### `Order.Price`

- **amount**: `Decimal` — Price amount.

### `Order.AppliedPromotion`

- **promotion**: `Order.AppliedPromotion.Promotion` — promotion data such as promotion's `id`, `name`
- **benefitType**: `Order.AppliedPromotion.BenefitType` - type of benefit triggered by promotion: `discount` or `coupon`
- **discountType**: `Order.AppliedPromotion.DiscountType` - type of discount triggered by promotion: `percentage`, `amount`, `fixedPrice` or `coupon`
- **includedProducts**: `Order.AppliedPromotion.ProductData` - products included into promotion
- **loyaltyPoints**: `Int` - amount of loyalty points received for triggering the promotion

### `OperatingCurrency`

Represents an operating currency supported by the shop.

- **id**: `Int` — The currency identifier from the back-office.
- **code**: `String` — ISO 4217 currency code (e.g. "EUR").
- **name**: `String` — Human-readable name of the currency (e.g. "Euro").
- **symbol**: `String` — The currency symbol (e.g. "$", "£").
- **sortOrder**: `Int?` — Sort order of the currency within the currency selector.

### `Observer`

Object that manages subscription lifecycle - must be retained in memory to continue receiving updates.

### `Money`

- **amount**: `Decimal` — Price amount.
- **currency**: `String` — Price currency code.
