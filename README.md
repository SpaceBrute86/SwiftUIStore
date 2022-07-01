# SwiftUIStore

A simple implementation of non-consumable in app purchases in SwiftUI. 

If you use MonetizedWindowGroup to instantiate your scene, the shared store object will be automatically initialized at launch, and passed as an environment object to your views. 

To give the user access to the store, add a *StoreButton* to your view.

If you have an IAP which removes advertisements, call   
Store.shared.noAdsIdentifier = "YOUR_NO_ADS_IAP_IDENTIFIER"
as early as possible. Then to determine if the user has purchased this, jsut call store.hasAdsRemoved

On iOS, the store page includes the ability to advertise addtional products. To do so, do the following:
1. Obtain the identifier from App Store Connect / etc.
2. Obtain the icon (with rounded corners) for the product you wish to advertise, and add it to your app's asset catalog
3. In your code, create an *ExternalProduct* with the identifier, display name of the product, and the name of the icon asset for that product
4. Pass your array of *ExternalProduct*s to the *StoreButton*, and it will take care of the rest

