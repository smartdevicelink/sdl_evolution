# Mobile Manager Dynamic Menu Cell Updating

* Proposal: [SDL-NNNN](NNNN-mobile-dynamic-menu-cell-updating.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [iOS / Android / Web]

## Introduction

Update the naïve menu updating with a new dynamic add / removal system of menu cells to use a more robust method that intelligently adds and removes menu cells, thereby cutting down on the amount of RPCs needed to update an SDL menu.

## Motivation

Currently, updating the menu through the menu manager in any way (even if the menu is only updated to add or remove a single cell) requires that the entire menu be deleted and added again. We should update our code to allow for updating the menu and dynamically determining which cells need to be deleted and which cells need to be added.

## Proposed solution

To solve this problem, we need a way to look at the old menu array, the new menu array, and determine adding / removing cells based on the differences.

The first problem to be solved is to determine equality of cells. We don't currently do this for `SDLMenuCell`, but we do for `SDLChoiceCell`. The implementation of equality in `SDLMenuCell` will be very close to `SDLChoiceCell`, using the properties' values to create a hash and comparing those hashes.

The second problem is to determine which adds and removals are necessary to turn the old / current menu array into the new menu array. We also need to consider sub-menus. Additionally complicating this issue is that existing menu cells cannot be moved, they must be removed and re-added, and if they have submenu cells, all those cells need to be removed and re-added as well.

### Algorithm Steps

1. Mark all cells in the old list as marked for deletion, all cells in the new list as marked for addition.
2. Loop through both lists and unmark cells that occur in the same order in both lists.
3. Create `DeleteCommand`s for all cells still marked for deletion; create `AddCommand`s for all cells still marked for addition, inserting them in the correct places using the `position` parameter.
4. Send the commands and set the new list as the current menu.

In the average case scenario, this algorithm would be O(n*log(n)).

#### Examples

1. Old Menu [A,B,C,D]
   
   New Menu [A,B,C,D,E]
   
   E remains marked for addition at position 4.

2. Old Menu [A,B,C,D]
   
   New Menu [A,B,C]
   
   D remains marked for deletion.

3. Old Menu [A,B,C]
   
   New Menu [D,E,F]
   
   A, B, and C remain marked for deletion
   
   D, E, and F remain marked for addition at positions 0, 1, and 2 respectively

4. Old Menu [A,B,C,D]
   
   New Menu [B,A,D,C]
   
   B is marked for deletion and addition at position 0
   
   D is marked for deletion and addition at position 2

#### Submenus

Submenus work very similarly. Any menu cell which is staying in the menu which contains subcells will have the subcells checked for the same consistency as the top-level menu. Subcells will be marked for addition or deletion in the same way.

If a menu cell is removed, all subcells will be removed by default because of the way that the `DeleteSubMenu` command works. Therefore, any cell that needs to be moved will 

## Potential downsides

1. This method is more intensive and complicated than the current method of deleting all old cells and adding all new cells. However, for simple changes (e.g. adding one menu item to the end of a menu of 80 commands), this method is vastly faster to send the singular `AddCommand` than to send 80 `DeleteCommand`s and 81 `AddCommand`s.

## Impact on existing code

This would not cause any version change for any affected platform.

## Alternatives considered

1. Leave it the way it is. The naïve approach is very easy, but requires far too many RPCs to be sent for simple tasks.