# Mobile Manager Dynamic Menu Cell Updating

* Proposal: [SDL-0210](0210-mobile-dynamic-menu-cell-updating.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Accepted with Revisions**
* Impacted Platforms: [iOS / Android / Cloud]

## Introduction

Update the naïve menu updating with a new dynamic add / removal system of menu cells to use a more robust method that intelligently adds and removes menu cells, thereby cutting down on the amount of RPCs needed to update an SDL menu.

## Motivation

Currently, updating the menu through the menu manager (even if the menu is only updated to add or remove a single cell) requires that the entire menu be deleted and added again. 

The code should be improved to allow for updating the menu by dynamically determining which cells need to be deleted and which cells need to be added.

## Proposed solution

To solve this problem, a way will need to be determined to look at the old menu array, the new menu array, and determine which cells need to be added, deleted, or moved based on the differences between the arrays.

The first problem to be solved is how to determine equality of cells. We don't currently do this for `SDLMenuCell`, but we do for `SDLChoiceCell`. The implementation of equality in `SDLMenuCell` will be very close to `SDLChoiceCell`; we will use the properties' values to create a hash and then compare those hashes.

The second problem is to determine which adds and removals are necessary to turn the old / current menu array into the new menu array. Submenus will also need to be considered. However, there is no API to simply move a menu cell. Moving a cell requires it to be removed and re-added, and if the cell has submenu cells, all those cells will be automatically removed and will need to be re-added as well.

### Algorithm Steps

1. Mark all cells in the old list as marked for deletion, all cells in the new list as marked for addition.
2. Loop through both lists and unmark cells that occur in the same order in both lists.
3. Create `DeleteCommand`s for all cells still marked for deletion; create `AddCommand`s for all cells still marked for addition, inserting them in the correct places using the `position` parameter.
4. Score this run by the additions. A change requiring 4 additions would have a score of 4.
5. Start a new run by removing the first item from the current menu and running steps 1 to 4 based on this new current menu and the target menu. However, if no items are found in the target list, all remaining runs are cancelled.
6. Repeat steps 1 to 5 until the current menu has zero items remaining or no items are found in the target list.
7. Compare the scores of the various runs and use the run that has the lowest score.
8. Send the commands and set the new list as the current menu.

In the average case scenario, this algorithm would be O(n*log(n)).

All deletions can happen concurrently, but additions must happen sequentially (waiting for a response before the next request is sent) starting from position 0 and moving up.

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

   A is found in position 1 (0 based)
   
   B begins searching in position 2, is not found.

   C begins searching in position 2, is found in position 3.

   We've reached the end of the new menu, additional searching is canceled.
   
   B is marked for deletion and addition at position 0
   
   D is marked for deletion and addition at position 2

   Run 1 score is 2

   Run 2 - B is found in position 0, C in 3, D is not checked - score of 2

   Run 3 - C is found in 3, score of 3

   Run 4 - D is found in 2, score of 3

   Run 1 will be used

5. Old Menu [A,B,C,D]

   New Menu [B,C,D,A]

   Run 1: A is found in position 3 (0 based) - score of 3

   Run 2: B is found in position 0, C is found in position 1, D is found in position 2 - score of 1

   Run 3: Score of 2

   Run 4: Score of 3

   Run 2 will be used.

#### Submenus

Submenus work similarly. Any menu cell that is staying in the menu which contains subcells will have the subcells checked for the same consistency as the top-level menu. Subcells will be marked for addition or deletion in the same way.

If a menu cell is removed, all subcells will be removed by default because of the way that the `DeleteSubMenu` command works. Therefore, any cell that needs to be moved will need to have all of its submenus deleted.

## Potential downsides

1. This method is more intensive and complicated than the current method of deleting all old cells and adding all new cells. However, for simple changes (e.g. adding one menu item to the end of a menu of 80 commands) this method is vastly faster to send the singular `AddCommand` than to send 80 `DeleteCommand`s and 81 `AddCommand`s.

## Impact on existing code

This would not cause any version change for any affected platform.

## Alternatives considered

1. Leave it the way it is. The naïve approach is very easy, but requires far too many RPCs to be sent for simple tasks.
