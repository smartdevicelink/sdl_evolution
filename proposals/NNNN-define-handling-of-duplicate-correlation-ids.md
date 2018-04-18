# Define Handling of Duplicate Correlation IDs

* Proposal: [SDL-NNNN](NNNN-define-handling-of-duplicate-correlation-ids.md)
* Author: [Jacob Keeler](https://github.com/jacobkeeler)
* Status: **Awaiting review**
* Impacted Platforms: [Core / Protocol]

## Introduction

This proposal is for the clarification of the SDL protocol behavior in the case that an app sends multiple messages with the same correlation ID.

## Motivation

Currently, SDL Core does not reject messages when they have the same correlation ID as a pending message, and this behavior can result in ambiguous responses from SDL Core. Logically, this scenario should result in an `INVALID_ID` response from Core, but this behavior is not currently defined in the protocol explicitly. The current behavior also appears to be responsible for [a crash in SDL Core](https://github.com/smartdevicelink/sdl_core/issues/2009) under specific circumstances.

## Proposed solution

The proposed solution to this issue is to explicitly define the protocol expectations in this case, stating that messages with duplicate correlation IDs will be rejected if the original message is still waiting for a response. SDL Core's behavior would be changed accordingly, responding with an `INVALID_ID` result code in such a scenario.

## Potential downsides

This could result in issues developing with any apps which aren't currently following the standard of incrementing the correlation ID with every request, but allowing apps to continue doing this only hides the previous issues mentioned with the current implementation.

## Impact on existing code

### Protocol Spec

This change would require the following addition to the description of the Correlation ID field in the protocol spec:

```
  <tr>
    <td>Correlation ID</td>
    <td>32 bits</td>
-   <td>The Correlation ID is used to map a request to its response. In Protocol Version 1, when the Binary Header did not exist, the Correlation ID was included as part of the JSON and has a max value of 65536</td>
+   <td>The Correlation ID is used to map a request to its response. In Protocol Version 1, when the Binary Header did not exist, the Correlation ID was included as part of the JSON and has a max value of 65536. 
+   If an app sends a request with a duplicate Correlation ID to another request sent by that app that hasn't yet received a response, the request will be rejected with an `INVALID_ID` response.</td>
  </tr>
```

### SDL Core

All of the necessary changes to SDL Core are shown in [this PR](https://github.com/smartdevicelink/sdl_core/pull/2101/files), the main change being in `request_controller.cc`:

```
-    request_controller_->waiting_for_response_.Add(request_info_ptr);
+    if (!request_controller_->waiting_for_response_.Add(request_info_ptr)) {
+      commands::CommandRequestImpl* cmd_request =
+          dynamic_cast<commands::CommandRequestImpl*>(request_ptr.get());
+      if (cmd_request != NULL) {
+        cmd_request->SendResponse(
+            false, mobile_apis::Result::INVALID_ID, "Duplicate correlation_id");
+      }
+      continue;
+    }
```

The `Add` function in this case fails if a message with the same identifier (which is constructed from the `App ID` and `Correlation ID`) is already waiting for a response.

## Alternatives considered

1. Change just the Core implementation, leaving the Protocol Spec as is with the assumption that the [current description](https://github.com/smartdevicelink/protocol_spec#5211-binary-header-fields) of the Correlation ID field is clear enough on this matter:
  > The Correlation ID is used to map a request to its response. In Protocol Version 1, when the Binary Header did not exist, the Correlation ID was included as part of the JSON and has a max value of 65536
  
2. Leave the Core implementation as is, leaving the ambiguous responses if an app chooses to send multiple messages with the same Correlation ID.