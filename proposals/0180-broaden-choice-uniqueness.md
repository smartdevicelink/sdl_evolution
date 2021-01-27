# Broaden Choice Uniqueness

* Proposal: [SDL-0180](0180-broaden-choice-uniqueness.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: Core / iOS / Java Suite / JavaScript Suite

## Introduction
This proposal broadens choice and sub-menu uniqueness to allow the choice set system (`CreateInteractionChoiceSet` / `PerformInteraction`) and menu system (`AddCommand` / `AddSubMenu`) primary text to be identical. 

## Motivation
Currently choice set choices and menu commands must have unique primary text (`Choice.menuName`, `AddCommand.menuParams.menuName`, `AddSubMenu.menuName`). However, this is an unnecessary and harmful restriction that should be lifted. For example, if a POI or Navigation app wishes to display a list of nearby restaurants, they cannot use the primary text for the restaurant name if there are multiple "McDonalds" restaurants. This restriction is harmful to the usability of such apps.

### Use-Case 1 (Choice Sets)
1. The app supports searching nearby restaurants.
2. The user uses a search / `PerformInteraction (Keyboard)` feature to input "McDonalds"
3. There is more than one McDonalds restaurant nearby, so the app wishes to create a `PerformInteraction` with the following choices:
   1. `Choice.menuName = McDonalds`, `Choice.secondaryText = 0.9 mi`
   2. `Choice.menuName = McDonalds`, `Choice.secondaryText = 1.7 mi`

This will result in a failure when attempting to show the `PerformInteraction`.

### Use-Case 2 (Menus)
The developer wishes to display use the menu system like the following:

| Nearby Restaurants (`AddCommand`) |
| --------------------------------- |
| McDonalds \ 0.3 miles away (`AddCommand`) |
| McDonalds \ 1.4 miles away \ Supports ordering from your car! (`AddSubmenu`) |
| McDonalds \ 2.4 miles away (`AddCommand`) |

Where the "McDonalds" items are menu items related as sub-menu items of the "Nearby Restaurants" main menu items, either `AddCommand`s or `AddSubmenu` interchangeably.

## Proposed solution
The primary text is not used as any sort of a key (the `choiceId` / `cmdId` / `menuID` is), and so this restriction can be removed in Core's code. The app library choice set managers must then also be updated to work in a backwards compatible manner with the lifting of this restriction.

In the mobile libraries, if it is detected that we are working with an SDL system that does not support duplicate primary text (based on the RPC version), we should append "(1)", "(2)", etc. after duplicate primary texts in the following way:

1. Choice
2. Choice (1)
3. Choice (2)

Because `AddCommand` and `AddSubmenu` only supports a primary text and icon on many versions of SDL, it should be clear in documentation that it is the developer's responsibility to make commands clear to the user and not confusing.

## Potential downsides
1. This will add complexity to the app library choice set managers to work in a backward compatible way.
2. The core team will need to target fixes to remove the uniqueness requirement for choices and menu items.
3. If menu or choice set items are very long, preventing the duplicate by appending ` (x)` may result in the string being too long for the menu space available. This will not be handled in the initial version of this update.
4. If the system is in use in a country that does not use Indo-Arabic numerals (1, 2, 3, 4...), Indo-Arabic numerals will still be used as the de-duplication method. Other numbering systems will not be handled in the initial version of this update.

## Impact on existing code
This will require a documentation update to tell developers how the system will work on various RPC versions, but will not require a minor version change on any platform.

## Alternatives considered
1. Other methods of fixing duplicates in a backward compatible way are available instead of ` (x)`. For example: ` - x`, or other options.
2. We could automatically reduce the length of the primary text string to account for the appended de-duplication string. For example, instead of turning "McDonalds" into "McDonalds (1)", if that string is now too long, we could turn it into "McD... (1)" or whatever is necessary to fit into the text. This would mitigate downside (3) and will be considered for future updates to this feature.
3. We could allow the developer to specify a series of strings that could be appended as a de-duplicator. This would allow for custom de-duplication and could mitigate downside 4. This will be considered for future updates to this feature.
