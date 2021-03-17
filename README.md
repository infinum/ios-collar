# AnalyticsCollector

[![Version](https://img.shields.io/cocoapods/v/AnalyticsCollector.svg?style=flat)](https://cocoapods.org/pods/AnalyticsCollector)
[![License](https://img.shields.io/cocoapods/l/AnalyticsCollector.svg?style=flat)](https://cocoapods.org/pods/AnalyticsCollector)
[![Platform](https://img.shields.io/cocoapods/p/AnalyticsCollector.svg?style=flat)](https://cocoapods.org/pods/AnalyticsCollector)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* Swift 5.1
* Xcode 11.0
* iOS 11.0

## Installation

AnalyticsCollector is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AnalyticsCollector', :git => 'https://github.com/infinum/ios-analytics-collector'
```
## Usage

##### 1. In your analytics manager add support for analytics collecting:

```swift
import AnalyticsCollector

// Events
AnalyticsCollectionManager.shared.log(event: "some_event", parameters: [
    "param1": "value1",
    "param2": "value2"
])

// User properties
AnalyticsCollectionManager.shared.setUserProperty("some_value", forName: "user_property_key")

// Screen views
AnalyticsCollectionManager.shared.track(screenName: "Home", screenClass: "HomeViewController")
```

##### 2. At the point where you want to display collected logs, you can just put the following line:

```swift
AnalyticsCollectionManager.shared.showLogs(from: viewController)
```

##### 3. If you want to display popup every time event/user property/screen view is tracked,  you can just put the following lines:

```swift
// Also controllable from settings screen inside logs view
LogItemPopupQueue.shared.enabled = true
// Popup dismisses on tap or after defined number of seconds
LogItemPopupQueue.shared.showOnView = { UIApplication.shared.keyWindow }
```

If you would like to receive notifications when new logs are added to the list, your app can observe `AnalyticsCollectionManager.Notification.didUpdateLogs` notification.

## Author

Filip Gulan, filip.gulan@infinum.com

## Credits

Maintained and sponsored by [Infinum](http://www.infinum.com).

![Infinum logo](https://cloud.githubusercontent.com/assets/1422973/24369980/9c36b0a6-12da-11e7-898a-b711ed7ca52f.png)

## License

AnalyticsCollector is available under the MIT license. See the LICENSE file for more info.
