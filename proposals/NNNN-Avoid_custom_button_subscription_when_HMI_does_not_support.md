
# Avoid Custom button subscription in case HMI incompatibility

* Proposal: [SDL-NNNN](NNNN-Avoid_custom_button_subscription_when_HMI_does_not_support.md)
* Author: [Getmanets Irina](https://github.com/GetmanetsIrina)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction

In case HMI does not support `CUSTOM_BUTTON`, SDL should not try to subscribe application to it.

## Motivation

Now SDL does not check hmi_capabilities before subscription to `CUSTOM_BUTTON`. So it will try to subscribe each registered application to `CUSTOM_BUTTON` even if it is unsupported by HMI.

SDL should check hmi capabilities and subscribe application to `CUSTOM_BUTTON` if it is **supported by HMI only**.

## Proposed solution

On application registration SDL should check hmi capabilities.

In case `CUSTOM_BUTTON` is supported by hmi_capabilities :
SDL should send `Buttons.SubscribeButtons(CUSTOM_BUTTON)` to HMI and wait for response.


In case `CUSTOM_BUTTON` is not supported by hmi_capabilities :
SDL should **not** send `Buttons.SubscribeButtons(CUSTOM_BUTTON)` to HMI.

If HMI supports `CUSTOM_BUTTON` it should be in `Buttons[capabilities]` section of `hmi_capabilities.json` :

```
"Buttons": {
       "capabilities": [
        ...,
        {
               "name": "CUSTOM_BUTTON",
               "shortPressAvailable": true,
               "longPressAvailable": true,
               "upDownAvailable": true
           }
        ]
}
```


If HMI supports `CUSTOM_BUTTON`, response to `Buttons.GetCapabilities` should contain following structure :

```
"capabilities": [
        ...,
        {
               "name": "CUSTOM_BUTTON",
               "shortPressAvailable": true,
               "longPressAvailable": true,
               "upDownAvailable": true
           }
        ]
```


`Buttons.GetCapabilities` request has higher priority than `hmi_capabilities.json`.

## Potential downsides

N/A

## Impact on existing code

* SDL core needs to be updated

## Alternatives considered

N/A
