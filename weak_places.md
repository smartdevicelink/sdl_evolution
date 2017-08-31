# Problems in current testing approaches 

## Maintenence of ATF is complicated due to hight cupling of ATF nodes

Integration of SDL cost contains from:
 - ajustment of sdl core costs (if required)
 - integration verification costs 


## Unable to make SDL deployment preconditions for script run

SDL configurations are not managed and not deployed automaticaly.

Impact :

Verification of different SDL configuration only possible in manual mode. [verification cost]
Unable to create one unified test set for some SDL feature. 
Unable to Test already runned SDL
Current verification approach requires deep knowlage of SDL in order to check integration quality on OEM platform.
SDL required a lot of resources for CI system integration and reporting
Poor versioning of the ATF which leads to problems with defects analysys and scripts reusability
Creating new scripts required deep knowlage and expirience in current ATF arhitecture.


## Complex maintanese procedure of test sets

# Benefits

Possibility to automaticaly verify SDL integration on OEM platform without MobileApp and\or HMI. 
Seamless Integration ATF into CI system.
Clear tracebility of ATF, scripts and SDL versions 
ATF facade will simplify creating new test scripts
Unified approach for test scritps and test sets creation
Proposed arhitecture allows flexible integration of ATF into existing SDL verification infrastructure on OEM manifecture side



Order
 - Efforts by groups
 - ATF mission is to simplify work by intgration
 - Current problemts that impact 
 - I propose new arhitecture that will impoove intagration on OEM
 - Benefits
 - New arhitecture is good 
 

remove ```cost```
