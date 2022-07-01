# SwiftUIStore

A simple implementation of non-consumable in app purchases in SwiftUI. 

At launch, either call Store.configure, or use MonetizedWindowGroup to instantiate your scene.  MonetizedWindowGroup will call Store.configure for you, and will also pass the store object as an environment object to your views.
Your configuration dictionary can use the following keys:
Store.Configuration.NoAdsIdentifier for a "remove ads" product ID
Store.Configuration.FeatureIdentifiers for all other product IDs.

To give the user access to the store, add a *StoreButton* to your view.

On iOS, the store page includes the ability to advertise addtional products. To do so, do the following:
1. Obtain the identifier from App Store Connect / etc.
2. Obtain the icon (with rounded corners) for the product you wish to advertise, and add it to your app's asset catalog
3. In your code, create an *ExternalProduct* with the identifier, display name of the product, and the name of the icon asset for that product
4. Pass your array of *ExternalProduct*s to the *StoreButton*, and it will take care of the rest


If you have an IAP which removes advertisements, just pass the appropriate key to the configuration dictionary, and call store.hasAdsRemoved to determine if this particular product has been purchased. 
