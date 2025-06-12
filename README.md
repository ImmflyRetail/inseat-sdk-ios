# Inseat iOS SDK Documentation

This document provides comprehensive documentation for the Inseat iOS SDK methods and errors.

## Table of Contents

- [Initialization Methods](#initialization-methods)
- [Synchronization Methods](#synchronization-methods)
- [Data Management Methods](#data-management-methods)
- [Shop Information Methods](#shop-information-methods)
- [Product Management Methods](#product-management-methods)
- [Order Management Methods](#order-management-methods)
- [Permission Methods](#permission-methods)
- [Error Types](#error-types)
- [Data Models](#data-models)
- [Installing Package Dependency](#installing-package-dependency)
- [Configuring Permissions](#configuring-permissions)
- [Public Interface](#public-interface)

---

## SDK Methods Summary

| Method Name        | Description                                                             |
| ------------------ | ----------------------------------------------------------------------- |
| `initialize`       | Initializes the Inseat SDK with configuration parameters                |
| `start`            | Starts syncing data with POS devices via BLE mesh network               |
| `stop`             | Stops syncing data with POS devices and shuts down the SDK service      |
| `syncProductData`  | Downloads and caches product data from the server API                   |
| `setUserData`      | Sets the selected menu for filtering products                           |
| `observeShop`      | Subscribes to shop status updates and receives real-time notifications  |
| `fetchShop`        | Fetches shop data once (one-time operation)                             |
| `fetchMenus`       | Fetches available shop menus once                                       |
| `fetchCategories`  | Fetches available shop categories once                                  |
| `observeProducts`  | Subscribes to product updates and receives real-time notifications      |
| `fetchProducts`    | Fetches available shop products once                                    |
| `createOrder`      | Creates an order and sends it to the POS application                    |
| `observeOrders`    | Subscribes to order status updates and receives real-time notifications |
| `cancelOrder`      | Cancels an existing order and sends information to the POS application  |
| `checkPermissions` | Checks if the SDK has necessary permissions to operate                  |

## Initialization Methods

### `initialize`

**Description:** Initializes the Inseat SDK with the provided configuration parameters. This method should be called when the app is launched.

**Signature:**

```swift
func initialize(configuration: Configuration) throws
```

**Parameters:**

- `configuration` - Configuration object containing:
  - `apiKey` - API key for authentication
  - `supportedICAOs` - Array of supported ICAO codes (e.g. ["WZZ", "WAZZ"])
  - `environment` - Environment type (`.test` or `.live`)
  - `orderConfirmationTimeoutDelayInSeconds` - Timeout for order operations (default: 120 seconds)

**Return Type:** `Void` (throws on error)

**Errors:** `InseatError.initializationError(.initializationFailure)`, `InseatError.initializationError(.internalConfigurationFailure)`

---

## Synchronization Methods

### `start`

**Description:** Starts syncing data with POS devices via BLE mesh network.

**Signature:**

```swift
func start() throws
```

**Return Type:** `Void` (throws on error)

**Errors:** `InseatError.initializationError(.notInitialized)`, `InseatError.synchronizationError(.syncActivationFailure)`, `InseatError.synchronizationError(.subscriptionRegistrationFailure)`, `InseatError.initializationError(.tombstonesActivationFailure)`

### `stop`

**Description:** Stops syncing data with POS devices and shuts down the SDK service.

**Signature:**

```swift
func stop()
```

**Return Type:** `Void`

**Errors:** None

---

## Data Management Methods

### `syncProductData`

**Description:** Downloads and caches product data from the server API.

**Signature:**

```swift
func syncProductData(completion: ((Result<Void, InseatError>) -> Void)?)
```

**Parameters:**

- `completion` - Optional callback with result

**Return Type:** `Void` (result via completion callback)

**Errors:** `InseatError.initializationError(.notInitialized)`, `InseatError.networkError(.downloadFailure)`, `InseatError.serializationError(.decodingFailure)`

### `setUserData`

**Description:** Sets the selected menu for filtering products.

**Signature:**

```swift
func setUserData(_ userData: UserData)
```

**Parameters:**

- `userData` - UserData object containing menu selection

**Return Type:** `Void`

**Errors:** None

---

## Shop Information Methods

### `observeShop`

**Description:** Subscribes to shop status updates and receives real-time notifications.

**Signature:**

```swift
func observeShop(observer: @escaping (Shop?) -> Void) throws -> Observer
```

**Parameters:**

- `observer` - Callback function triggered when shop object is updated

**Return Type:** `Observer` - Observer instance that must be retained in memory

**Errors:** `InseatError.initializationError(.notInitialized)`, `InseatError.storeError(.observerRegistrationError)`

### `fetchShop`

**Description:** Fetches shop data once (one-time operation).

**Signature:**

```swift
func fetchShop() async throws -> Shop?
```

**Return Type:** `Shop?` - Optional Shop object

**Errors:** `InseatError.initializationError(.notInitialized)`, `InseatError.storeError(.fetchingError)`

### `fetchMenus`

**Description:** Fetches available shop menus once.

**Signature:**

```swift
func fetchMenus() async throws -> [Menu]
```

**Return Type:** `[Menu]` - Array of Menu objects

**Errors:** `InseatError.initializationError(.notInitialized)`, `InseatError.storeError(.fetchingError)`

### `fetchCategories`

**Description:** Fetches available shop categories once.

**Signature:**

```swift
func fetchCategories() async throws -> [Category]
```

**Return Type:** `[Category]` - Array of Category objects

**Errors:** `InseatError.initializationError(.notInitialized)`, `InseatError.storeError(.fetchingError)`

---

## Product Management Methods

### `observeProducts`

**Description:** Subscribes to product updates and receives real-time notifications.

**Signature:**

```swift
func observeProducts(observer: @escaping ([Product]) -> Void) throws -> Observer
```

**Parameters:**

- `observer` - Callback function triggered when products are updated (returns all products, not just updated ones)

**Return Type:** `Observer` - Observer instance that must be retained in memory

**Errors:** `InseatError.initializationError(.notInitialized)`, `InseatError.storeError(.observerRegistrationError)`

### `fetchProducts`

**Description:** Fetches available shop products once.

**Signature:**

```swift
func fetchProducts() async throws -> [Product]
```

**Return Type:** `[Product]` - Array of Product objects

**Errors:** `InseatError.initializationError(.notInitialized)`, `InseatError.storeError(.fetchingError)`

---

## Order Management Methods

### `createOrder`

**Description:** Creates an order and sends it to the POS application.

**Signature:**

```swift
func createOrder(_ order: Order) async throws
```

**Parameters:**

- `order` - Order object containing all order information

**Return Type:** `Void` (throws on error)

**Errors:** `InseatError.initializationError(.notInitialized)`, `InseatError.storeError(.insertError)`

### `observeOrders`

**Description:** Subscribes to order status updates and receives real-time notifications.

**Signature:**

```swift
func observeOrders(observer: @escaping ([Order]) -> Void) throws -> Observer
```

**Parameters:**

- `observer` - Callback function triggered when orders are updated (returns all orders, not just updated ones)

**Return Type:** `Observer` - Observer instance that must be retained in memory

**Errors:** `InseatError.initializationError(.notInitialized)`, `InseatError.storeError(.observerRegistrationError)`

### `cancelOrder`

**Description:** Cancels an existing order and sends this information to the POS application.

**Signature:**

```swift
func cancelOrder(id: Order.ID) async throws
```

**Parameters:**

- `id` - Order ID (String type alias)

**Return Type:** `Void` (throws on error)

**Errors:** `InseatError.initializationError(.notInitialized)`, `InseatError.storeError(.updateError)`

---

## Permission Methods

### `checkPermissions`

**Description:** Checks if the SDK has the necessary permissions to operate (Bluetooth, Local Network).

**Signature:**

```swift
func checkPermissions(options: PermissionCheckOptions = .default) async -> PermissionCheckResult
```

**Parameters:**

- `options` - Permission check options (default: `.default`)

**Return Type:** `PermissionCheckResult` - Result indicating success or failure with missing permissions

**Errors:** None (returns result enum)

---

## Error Types

### `InseatError`

#### `initializationError(InitializationErrorReason)`

- `.notInitialized` - SDK is not initialized
- `.initializationFailure` - Failed to configure sync layer
- `.internalConfigurationFailure` - Failed to configure internal components
- `.tombstonesActivationFailure` - Failed to configure tombstones

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

### `Order`

Represents an order.

- **id**: `String` — Unique identifier for the order.
- **shiftId**: `String` — Shift identifier.
- **seatNumber**: `String` — Seat number.
- **status**: `Status` — Status of the order (`placed`, `received`, `preparing`, `cancelledByPassenger`, `cancelledByCrew`, `cancelledByTimeout`, `completed`).
- **items**: `[Order.Item]` — List of order items.
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

### `Product`

Represents a product.

- **id**: `Int` — Product identifier.
- **name**: `String` — Product name.
- **quantity**: `Int` — Available quantity.
- **image**: `UIImage?` — Product image.
- **prices**: `[Product.Price]` — List of prices.
- **categoryId**: `Int` — Category identifier.
- **startDate**: `Date?` — Availability start date.
- **endDate**: `Date?` — Availability end date.

### `Product.Price`

- **currencyCode**: `String` — Currency code.
- **amount**: `Decimal` — Price amount.

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
- **crewLastSeen**: `Date?` — Last crew seen timestamp.

### `UserData`

Represents user data in the SDK.

- **menu**: `Menu` — Currently selected menu for the user.

### `Configuration`

Represents SDK configuration.

- **apiKey**: `String` — API key for authentication.
- **supportedICAOs**: `[String]` — Array of supported ICAO codes.
- **environment**: `Environment` — Environment type (`.test` or `.live`).
- **orderConfirmationTimeoutInSeconds**: `TimeInterval` — Timeout for order operations (default: 120 seconds).

### `Environment`

Represents the SDK environment.

- **test**: Test environment
- **live**: Production environment

### `Observer`

Object that manages subscription lifecycle - must be retained in memory to continue receiving updates.

---

## Installing Package Dependency

1. Click `File`, and then select `Add Package Dependencies` from the menu.
2. In the modal window:

- Paste the following URL into the search box in the upper-right corner: https://github.com/ImmflyRetail/inseat-sdk-ios
- Select `inseat-sdk-ios` from the list
- Click `Add Package`

3. From the `Choose Package Products for inseat-sdk-ios` modal window:

- Click `Add to Target` and select your app from the list
- Click `Add Package`


## Configuring Permissions

1. Configure `Info.plist`

1.1 Add usage descriptions

- NSBluetoothPeripheralUsageDescription
- NSBluetoothAlwaysUsageDescription
- NSLocalNetworkUsageDescription

1.2 Add NSBonjourServices

```xml
<key>NSBonjourServices</key>
<array>
    <string>_http-alt._tcp.</string>
</array>
```

So your plist file should look like:

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



# Public Interface:

## Initialization

First of all, you need to import the `Inseat` module and initialize the SDK. It's required to call the `initialize` method before accessing anything else.

```swift
import Inseat

let configuration = Configuration(apiKey: "YOUR_API_KEY")
try InseatAPI.shared.initialize(configuration: configuration)
```


## Download latest data from the API

After the SDK has been initialized you can download product data from the API by using the `syncProductData` method. 

```swift
InseatAPI.shared.syncProductData { result in
    print("Did sync data with result='\(result)'")
}
```

This method saves downloaded data into the local cache automatically.


## Sync

In order to start / stop syncing with POS device, you need to use the following methods:

- `try InseatAPI.shared.start()`
- `InseatAPI.shared.stop()`


## Manage Shop

### Shop Status

Observe the shop status using: 

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

The Observer stays active while you hold a strong reference to it, for example as a property in a class. The same is true for any other observing functionality of Inseat.

```swift
// Observer is cancelled after this reference is removed from memory.
private var shopObserver: Observer?
```

In case you need to retrieve the current shop object::

```swift
let shop = try await InseatAPI.shared.fetchShop()
```


### Menus

First of all you can get the list of menus using:

```swift
let menus = try await InseatAPI.shared.fetchMenus() 
```

If you have more than one menu available then you need to choose one and assign selected menu into `UserData` object: 

```swift
let userData = UserData(menu: selectedMenu)
InseatAPI.shared.setUserData(userData)
```


### Products

- Fetch categories using:

```swift
let categories = try await InseatAPI.shared.fetchCategories()
```

- Fetch products using:

```swift
let products = try await InseatAPI.shared.fetchProducts()
```

- Observe products using:

```swift
productsObserver = try InseatAPI.shared.observeProducts { products in
    ...
}
```


### Orders

- Create order using:

```swift
guard let shiftId = try await InseatAPI.shared.fetchShop()?.shiftId else {
    return
}
let order = Inseat.Order(
    id: UUID().uuidString,
    shiftId: shiftId,
    seatNumber: cart.seatNumber,
    status: .placed,
    items: cart.items.map {
        Inseat.Order.Item(
            id: $0.id,
            name: $0.name,
            quantity: $0.quantity,
            price: Inseat.Order.Price(amount: $0.unitPrice.amount)
        )
    },
    orderCurrency: cart.totalPrice.currencyCode,
    totalPrice: .init(amount: cart.totalPrice.amount),
    createdAt: Date(),
    updatedAt: Date()
)
try await InseatAPI.shared.createOrder(order)
```

- Cancel order using:

```swift
try await InseatAPI.shared.cancelOrder(id: orderId)
```

- Observe own list of orders using:

```swift
ordersObserver = try InseatAPI.shared.observeOrders { orders in
    ...
}
``` 

this observer is triggered when status changed for any order created on current device.
