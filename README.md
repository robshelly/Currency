# Currency

A simple iOS currency conversion app written in Swift, using the Fixer.io API (http://fixer.io)

Completed as an assignment for Mac Programming. The following changes/features were implemented:
 
* A number of extra currencies were added
* A decimal keypad with a toolbar containing a _Done_ button was configured for input
* The frame was configured to move up when the keypad appears if it would obscure the input field
* The _Convert_ button was removed in lieu iof automatically convert when the _Done_ button it pressed
* A table view was configured to display currencies
* The _Refresh_ button was removed in lieu of using _pull-to-refresh_ on the table view
* Activity indicator was removed in lieu of the activity indicator implemented by the table view.
* Asynchronous API call was refactored to remove deprecated method
* Splash screen and icons were added to the app
