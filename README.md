# Overview & Setup    

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
