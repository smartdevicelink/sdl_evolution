# Add RPC Conflict Management

* Proposal: [SDL-0315](0315-Add-RPC-Conflict-Management.md)
* Author: [Akihiro Miyazaki (Nexty)](https://github.com/Akihiro-Miyazaki)
* Status: **Returned for Revisions**
* Impacted Platforms: [ Core / HMI / Policy Server ]

## Introduction
This proposal is to add a function to SDL Core that manages concurrent RPC conflicts according to priority. This will allow OEMs to receive the expected request from SDL Core during RPC conflict by modifying the configuration in the policy table in which the priority is set.


## Motivation
When multiple apps operate, ON-screen (ONS) messages and text-to-speech (TTS) RPCs are requested together. However, the current SDL Core does not have the function to manage these conflicts. Thus, all requests are notified to the middleware and managed by the OEMs themselves. For instance, ONS and TTS conflicts are managed by prioritizing the latter RPC. The figure below demonstrates the sequence process when `PerformAudioPassThru` occurs during `ScrollableMessage`.

<b>Figure 1.</b> Conflict between `ScrollableMessage` and `PerformAudioPassThru`
![Figure1_Conflict_between_ScrollableMessage_and_PerformAudioPassThru_1.png](../assets/proposals/0315-Add-RPC-Conflict-Management/Figure1_Conflict_between_ScrollableMessage_and_PerformAudioPassThru_1.png)

The example above shows that the latter RPC `PerformAudioPassThru` is displayed and aborts `ScrollableMessage`. However, this kind of method has the following problems.
1. Since there is no guideline for RPC conflicts, implementations vary for each OEMs, thus, it is hard to standardize.
2. Management of RPC conflicts with OEMs may increase the difficulty of implementing middleware.

To solve these problems, we propose to add a new RPC conflict management function to SDL Core.

## Proposed solution
To implement the RPC conflict management, we will add a new RPC conflict management module, `InterruptManager` to SDL Core, and add `InterruptManagerConfig` to policy table.

RPC priority table and `App Priority` table are specified in `InterruptManagerConfig`. RPC priority table and `App Priority` table are tables that each set the priority of RPC and app. By modifying `InterruptManagerConfig`, an OEM can receive the expected request from SDL Core during RPC conflict. On the other hand, `InterruptManager` reads `InterruptManagerConfig` in policy table during the SDL Core startup and builds the two tables mentioned above based on their settings. When an RPC conflict occurs, the `InterruptManager` first determines the RPC with a high priority according to the RPC priority table. However, if two competing RPCs have the same priority, then the RPC with the higher priority is determined according to the `App Priority` priority table. Therefore, only one modal RPC to be displayed at a time.

#### RPC Conflict Management Configuration Table
The following tables described in InterruptManagerConfig in the Policy table are explained below.

- RPC priority table
- `AppPriority` table
- HMI status table

The RPC priority will be determined by the order below. Priority order will shift from 1 to 2, from 2 to 3 and from 3 to 4, if the RPCs are same priority.

1. Apps with app priority EMERGENCY.
2. RPC Priority
3. App Priority (non-emergency)
4. HMI Status

<b>RPC Priority Table</b><br>
The RPC priority table describes the priority of each RPC. When multiple RPCs occur at the same time, the RPC with the higher priority is determined according to the RPC priority table. The target RPCs in this proposal are ONS and TTS. ONS RPCs include such as `Alert` and `PerformInteraction`. The RPC priority table can set the priority for each ONS RPC. On the other hand, there are two types of TTS RPCs, TTS with ONS and TTS only. TTS with ONS RPCs shall follow the processed priority of the ONS RPC, while TTS only RPCs can set the priority individually.

Below are the default settings of RPC priority table.

<b>Table 1.</b> Default settings of RPC priority table

| RPC_Name (String)        | Priority (INT) | Note (String)     |
|:-:                      |:-:            |:-:               |
| BC.DialNumber           | 1             | Highest priority |
| UI.Alert                | 2             |                  |
| UI.PerformAudioPassThru | 2             |                  |
| UI.PerformInteraction   | 3             |                  |
| UI.ScrollableMessage    | 3             |                  |
| UI.Slider               | 3             |                  |
| TTS.Speak w/o ONS       | 3             | Lowest priority  |

OEMs can modify the RPC priority table and adjust the RPC priority to their specifications.

The table below shows how the RPC will be determined by the priority set during RPC conflict based on the default settings above (Table 1).

<b>Table 2.</b> Priority result of Table 1

![Table_2_Priority_result_of_Table1.png](../assets/proposals/0315-Add-RPC-Conflict-Management/Table_2_Priority_result_of_Table1.png)

(* 1): For RPCs with the same priority, the `App priority` table, which is described later, will be used to determine the priority.

Below shows the Json example for the RPC priority table:
```json
  "RpcPriority":{
    "BC.DialNumber": 1,
    "UI.Alert": 2,
    "UI.PerformAudioPassThru": 2,
    "UI.PerformInteraction": 3,
    "UI.ScrollableMessage": 3,
    "UI.Slider": 3,
    "TTS.SPEAK": 3
}
```

OEMs can modify any RPC priority. For example, if the priority of `UI.PerformInteraction` is modified to "1", its RPC priority will be the same as `BC.DialNumber`.

```json
"RpcPriority":{
    "BC.DialNumber": 1,
    "UI.Alert": 2,
    "UI.PerformAudioPassThru": 2,
    "UI.PerformInteraction": 1,
    "UI.ScrollableMessage": 3,
    "UI.Slider": 3,
    "TTS.SPEAK": 3
}
```

OEMs can delete any RPC priority. For example, if the priority of `UI.Slider` is deleted as shown below, its priority will be the same as a normal RPC and will be lower than any RPC in the RPC priority table.

```json
"RpcPriority":{
    "BC.DialNumber": 1,
    "UI.Alert": 2,
    "UI.PerformAudioPassThru": 2,
    "UI.PerformInteraction": 3,
    "UI.ScrollableMessage": 3,
    "TTS.SPEAK": 3
}
```


OEMs can restore the deleted `UI.Slider` and modify its priority. For example, if the priority of `UI.Slider` is modified to "2", its priority will be the same as `UI.Alert` and `UI.PerformAudioPassThru`.

```json
"RpcPriority":{
  	"BC.DialNumber": 1,
    "UI.Alert": 2,
	"UI.PerformAudioPassThru": 2,
	"UI.PerformInteraction": 3,
	"UI.ScrollableMessage": 3,
	"UI.Slider": 2,
	"TTS.SPEAK": 3
}
```


<b>`App Priority` Table</b><br>
`App Priority` priority table describes the priority for each app. When a conflict between RPCs with the same priority in the RPC priority table occurs, the RPC with the higher priority is determined according to `App Priority` table. Below are the default settings of `App Priority` table.

<b>Table 3.</b> Default settings of `App Priority` table

| `app priority` (String) | Priority (INT) | Note (String)     |
|:-:                  |:-:            |:-:               |
| EMERGENCY           | 0             | Top priority     |
| NAVIGATION          | 1             | Highest priority |
| VOICE_COMMUNICATION | 2             |                  |
| COMMUNICATION       | 3             |                  |
| NORMAL              | 4             |                  |
| NONE                | 5             | Lowest priority  |

OEMs can modify the `App priority` table and adjust the priority of application according to their own specifications. In fact, since EMERGENCY is set independently as the highest priority, the priority is determined by the items excluding EMERGENCY.
For RPCs with the same priority, the HMI Status table, which is described later, will be used to determine the priority.


<b>HMI Status Table</b><br>
HMI Status table describes the priority for each app level. When a conflict between RPCs with the same priority in the RPC priority table and `App priority` table occurs, the RPC with the higher priority is determined according to HMI Status table. Below are the default settings of HMI Status table.

<b>Table 4.</b> Default settings of HMI Status table

| HMI Level (String) | Priority (INT) | Note (String)    |
|:-:                 |:-:             |:-:               |
| FULL               | 1              | Highest priority |
| LIMITED            | 2              |                  |
| BACKGROUND         | 3              |                  |
| NONE               | 4              | Lowest priority  |

If two RPCs with the same priority are sent, the second RPC sent will be prioritized.


#### RPC Conflict Management Module
The following explains functions of `InterruptManager`.

<b>1.Loading of configuration table</b><br>
`InterruptManagerConfig` is loaded from policy table during the startup of SDL Core.

<b>2.RPC conflict management processing sequence</b><br>
The processing sequence during ONS RPCs conflict is shown below.


<b>Figure 2.</b> ONS RPCs conflict

![Figure2_ONS_RPCs_conflict.png](../assets/proposals/0315-Add-RPC-Conflict-Management/Figure2_ONS_RPCs_conflict.png)

The processing sequence during TTS RPC conflict is shown below.

<b>Figure 3.</b> TTS RPCs conflict

![Figure3_TTS_RPCs_conflict.png](../assets/proposals/0315-Add-RPC-Conflict-Management/Figure3_TTS_RPCs_conflict.png)


## Potential downsides

1. This would be a complex system that takes control of RPC conflict management away from the HMI - where it is currently located - and puts it into a new, centralized system. At the least that means that OEMs will have to do quite a bit of HMI work to remove those old systems. This also means that re-implementing many current HMI-based RPC conflict management systems will be impossible and OEMs will have to work with this new system.
2. Implementing this feature will force only one modal RPC to ever be displayed for every OEM implementing SDL.

## Impact on existing code

1. Add `InterruptManager` to the SDL Core source code to manage RPC conflicts.
2. Add `InterruptManagerConfig` that sets RPC priority to the policy table file.
3. Remove the existing RPC conflict management systems from the HMI.
3. Add guidelines for OEMs such as `InterruptManagerConfig` placement and setting method on SDL Developer Portal (smartdevicelink.com).


## Alternatives considered
None.
