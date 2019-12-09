# Start APT of SDL App by pressing PTT button

* Proposal: [SDL-NNNN](NNNN-Start-APT-of-SDL-App-by-pressing-PTT-Button.md)  
* Author: [Shohei Kawano](https://github.com/Shohei-Kawano)  
* Status: Awating Review  
* Impacted Platforms: [ Core / iOS / Java Suite / HMI ]  

## Introduction

Add `PUSH_TO_TALK` as ButtonName. Its purpose is to provide voice agent apps a trigger for voice recognition and improve their user experience.  
The proposal of [SDL-135](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0135-PushToTalk-hardkey-support.md) and Motivation are the same. Since it was not my proposal, I am creating a new item.  

## Motivation

SDL already supports head unit's native Voice Recognition (VR) via `AddCommand/PerformInteraction` with vrCommands.  
On the other hands, some voice agent apps such as Alexa and Clova have VR feature by themselves. These apps hope to use some kind of trigger to start their VR, either using AudioPassThru or mobile phone's microphone.  

## Proposed solution

Add `PUSH_TO_TALK` as ButtonName.  

When a user presses a push-to-talk (PTT) button, the HMI notifies the SDL App of a PTT button event depending on the condition.  

It is recommended to follow the table below for conditions and operations.  
 ( As a premise, button events are sent only to the HMI LEVEL FULL / LIMITED SDL app. )

|condition1 : PTT button subscription status|Condition2 : HMI Status|Contidion3 : LongPress/ShortPress|Behavior|
|:-:|:-:|:-:|:-:|
|Not Subscribed|-|ShortPress|Start NativeVR|
|Not Subscribed|-|LongPress|Start NativeVR|
|Subscribed|Not FULL/LIMITED|ShortPress|Start NativeVR|
|Subscribed|Not FULL/LIMITED|LongPress|Start NativeVR|
|Subscribed|FULL|ShortPress|Send PTT Button Event|
|Subscribed|FULL|LongPress|Send PTT Button Event|
|Subscribed|LIMITED|ShortPress|Start NativeVR|
|Subscribed|LIMITED|LongPress|Send PTT Button Event|

In addition to the above conditions, if there are multiple SDL apps that subscribe to the PTT button, the HMI controls the ButtonEvent notification destination according to the HMI level of each SDL app.  
* When there is an SDL App whose HMILevel is FULL, ButtonEvent is notified only to that SDL App  
* If there is no SDL App with HMI Level FULL and there are multiple Limited SDL Apps, the HMI determines the destination SDL App by displaying a list of SDL App to the user.  


## Potential downsides

Old apps will not subscribe to `PUSH_TO_TALK` key. So, all behavior in old apps are not affected.  
Old head units will not return success to subscribeButton(`PUSH_TO_TALK`). So not affected.  
Since it is difficult for the user to recognize the long press operation, the operation method needs to be announced.  

## Impact on existing code

It is necessary to add ButtonName: `PUSH_TO_TALK` to Core, iOS and Java Suite.  
HMI needs to implement behavior control based on conditions.  

## Alternatives considered

Nothing.  