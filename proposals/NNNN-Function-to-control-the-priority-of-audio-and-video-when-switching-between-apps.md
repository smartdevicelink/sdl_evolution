# Function to control the priority of audio and video when switching between apps

* Proposal: [SDL-NNNN](NNNN-Function-to-control-the-priority-of-audio-and-video-when-switching-between-apps.md)
* Author: [Akihiro Miyazaki (Nexty)](https://github.com/Akihiro-Miyazaki)
* Status: **Awaiting review**
* Impacted Platforms: [ Core ]

## Introduction

The aim of this proposal is to add a function to SDL Core. The function allows OEMs to customize the status transition of audio and video when apps are switched. OEMs can control the status transition of apps when those are switched using a customized app status transition rule that is in an additional configuration file.

## Motivation

Switching apps is common SDL behavior. However, the app status transition rule is defined by the SDL Core, and OEMs can not customize the priority of audio and video when switching apps. Therefore, in some cases, it is difficult for OEMs to meet the specifications that they want to implement. For this reason, we propose adding a function which OEMs can set the priority control of audio and video according to the rules of status transition.

## Proposed solution

We propose adding new configuration file to the SDL Core that for defining customized the rule of status transition for audio and video by OEMs. Also we propose management rule of the file. OEMs can meet the specifications they want to implement by customizing and maintaining the configuration file.

Setting rules of configuration files are below.

- When the SDL is launched, the SDL Core loads two configration files, defaut configration and customized one by the OEM. Then the SDL Core selects one of the status transition rule with each situation.
- When an app is switched to other app, each status are changed into appropriate other status by referring those Apptypes and the status transition table.
- If the OEM's configuration file meets the specification of status transition as the SDL, the SDL Core uses the values in OEM's configuration file.
- If the OEM's configuration file does NOT meet the specification of status transition as the SDL, the SDL Core uses values in default configuration file.

The structure of status transition table is below. Table 1 shows the information in the configuration file to decide the transiton status of audio and video when the apps are swithed.

<b>Table 1.</b> Information of Status Transition Table

| Field | Description | Value |
| :-- | :-- | :-- |
| App1 | First launched app | MEDIA;<br>NAVIGATION;<br>PROJECTION(isMedia = True);<br>PROJECTION(isMedia = False);<br>OTHER; |
| App2 | Second launched app | MEDIA;<br>NAVIGATION;<br>PROJECTION(isMedia = True);<br>PROJECTION(isMedia = False);<br>OTHER; |
| App1 HMI_LEVEL | HMI Status of App1 after App2 is launched | BACKGROUND=0;<br>FULL=1;<br>LIMITED=2;<br>NONE=3; |
| App1 AUDIBLE | AUDIBLE Status of App1 after App2 is launched | NOT_AUDIBLE=0;<br>AUDIBLE=1; |
| App1 STREAMABLE | STREAMABLE Status of App1  after App2 is launched | NOT_STREAMABLE=0;<br>STREAMABLE=1; |
| App2 HMI_LEVEL | HMI Status of App2 after it is launched | BACKGROUND=0;<br>FULL=1;<br>LIMITED=2;<br>NONE=3; |
| App2 AUDIBLE | AUDIBLE Status of App2 it is launched | NOT_AUDIBLE=0;<br>AUDIBLE=1; |
| App2 STREAMABLE | STREAMABLE Status of App2 it is launched | NOT_STREAMABLE=0;<br>STREAMABLE=1; |

Note:
There are a total of 25 patterns of app combinations (App1 with 5 types x App2 with 5 types) by types.

The SDL specifications for the status transition are below. If OEMs define customized status transition rule, it is necessary to follow the rules below.

- Only one app can be FULL at the same time.
- Only one app can be STREAMABLE at the same time.
- In case two apps are same AppType, only one app can be AUDIBLE.

Setting samples are below.

<b>Table 2.</b> Example 1

| Field | Value |
| :-- | :-: |
| App1 | NAVIGATION |
| App2 | MEDIA |
| App1 HMI_LEVEL | 0<br>(BACKGROUND) |
| App1 AUDIBLE | 0<br>(NOT_AUDIBLE) |
| App1 STREAMABLE | 0<br>(NOT_STREAMABLE) |
| App2 HMI_LEVEL | 1<br>(FULL) |
| App2 AUDIBLE | 1<br>(AUDIBLE) |
| App2 STREAMABLE | 1<br>(STREAMABLE) |

In this case, the status of App1 becomes BACKGROUND, NOT_AUDIBLE and NOT_STREAMABLE after the App2 is launched.
At the same time, the status of App2 becomes FULL, AUDIBLE and STREAMABLE.
Head unit (HU) screen display switched to App2 and audio is played from App2.

<b>Table 3.</b> Example 2

| Field | Value |
| :-- | :-: |
| App1 | PROJECTION<br>(isMedia = False) |
| App2 | MEDIA |
| App1 HMI_LEVEL | 2<br>(LIMITED) |
| App1 AUDIBLE | 0<br>(NOT_AUDIBLE) |
| App1 STREAMABLE | 1<br>(STREAMABLE) |
| App2 HMI_LEVEL | 1<br>(FULL) |
| App2 AUDIBLE | 1<br>(AUDIBLE) |
| App2 STREAMABLE | 0<br>(NOT_STREAMABLE) |

In this case, the status of App1 becomes LIMITED, NOT_AUDIBLE after the App2 is launched, but STREAMABLE status is kept as STREAMABLE.
At the same time, the status of App2 becomes FULL, AUDIBLE and NOT_STREAMABLE.
HU screen display switched to App2 and basic audio is ready to be played from App2. App1 is not displayed on the screen, but playback of the video continues in background.

#### Error processing

When the SDL is launched, the SDL Core loads two configration files, defaut configration and customized one by the OEM. Basically, the SDL Core uses the OEM's configuration file. But if it does not meet the status transiton specification as SDL, the SDL Core discards OEM's configuration file and uses setting in default configuration file. Table 4 is example of the invalid the OEM customized status transiton (in this transiton rule, 2 apps can be set STREAMABE status at the same time). In this case, the SDL Core discards only the non-conforming part of the setting provided by the OEM's configuration file and uses the value of default one.

<b>Table 4.</b> OEM's specification of Status Transition (the case of error)

| Field | Value |
| :-- | :-: |
| App1 | NAVIGATION |
| App2 | MEDIA |
| App1 HMI_LEVEL | 2<br>(LIMITED) |
| App1 AUDIBLE | 1<br>(AUDIBLE) |
| App1 STREAMABLE | 1<br>(STREAMABLE) |
| App2 HMI_LEVEL | 1<br>(FULL) |
| App2 AUDIBLE | 1<br>(AUDIBLE) |
| App2 STREAMABLE | 1<br>(STREAMABLE) |

<b>Table 5.</b> Default Status Transition value of default configuration file

| Field | Value |
| :-- | :-: |
| App1 | NAVIGATION |
| App2 | MEDIA |
| App1 HMI_LEVEL | 2<br>(LIMITED) |
| App1 AUDIBLE | 1<br>(AUDIBLE) |
| App1 STREAMABLE | 1<br>(STREAMABLE) |
| App2 HMI_LEVEL | 1<br>(FULL) |
| App2 AUDIBLE | 1<br>(AUDIBLE) |
| App2 STREAMABLE | 0<br>(NOT_STREAMABLE) |

The Figure 1 shows the switching sequence of apps controlled by the status transition. The following rules are described in this sequence.

1. When the SDL is launched, the SDL Core loads default values of status transition from the default configuration file.
2. The SDL Core loads the configuration file customized by the OEM, and initializes the status transition table by following the rule.
3. When an app is switched to other app, these apps behavior after switching are applied by the status transition table.

<b>Figure 1.</b> Switching apps sequence

![Figure_1_app_switching_sequence.png](../assets/proposals/NNNN-Function-to-control-the-priority-of-audio-and-video-when-switching-between-apps/Figure_1_app_switching_sequence.png)

## Potential downsides

None.

## Impact on existing code

- These changes affect only the status transition of the SDL Core when apps are swithced.

## Alternatives considered

None.
