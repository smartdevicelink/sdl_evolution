# Arguments initialText and hintText for SDL Keyboard

* Proposal: [SDL-0168](0169-initial-and-hint-text-for-keyboard.md)
* Author: [MarekForys](https://github.com/mforys) (TomTom)
* Status: **In Review**
* Impacted Platforms: [Core, Android, iOS]


## Introduction

SDL Keyboard may be started with argument initialText, but it's displayed in iOS version as blue hint/description in the input field of SDL Keyboard. In the case of Android this initial text is never displayed.

There should be a possibility of using initial and hint/description text as well.
All available documentation is here: [SDLPerformInteraction](https://smartdevicelink.com/en/docs/iOS/master/Classes/SDLPerformInteraction/).


## Motivation

Sometimes a user wants to continue to input text which is already partially filled in within their device's input text field, then after connecting to SDL the text field is totally empty. Another scenario is when some text is filled into SDL keyboard then we press Enter and we launch Keyboard again. Input text field is blank and previously entered text is gone.


## Proposed solution

When creating an SDL Keyboard we should give two text arguments: initialText and hintText. Argument hintText should just replace current initialText. Flow for initialText must be developed in all submodules from scratch.

So the perfect description of these arguments should be like this:

* initialText - text which is prefilled to input text field of Keyboard
* hintText - text which is a hint or description of the content which should be entered into input text field

Possible usage should be like:

```objc
- (instancetype)initWithInitialChunks:(nullable NSArray<SDLTTSChunk *> *)initialChunks initialText:(NSString *)initialText hintText:(NSString *)hintText
```

## Potential downsides

None.


## Impact on existing code

All apps which already use initialText argument will be fixed, unless initialText is not used as a regular hint.


## Alternatives considered

The easier option is to just use the current parameter initialText and use it as a text which should be prefilled into Text Field of the Keyboard.
Although it seems the interesting feature of a hint/descriptive welcome text (dark blue), which is already implemented can be lost then.
So it's better to use both arguments.
