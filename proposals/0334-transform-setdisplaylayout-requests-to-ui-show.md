# Transform SetDisplayLayout requests into UI.Show for HMIs

* Proposal: [SDL-0334](0334-transform-setdisplaylayout-requests-to-ui-show.md)
* Author: [Shobhit Adlakha](https://github.com/ShobhitAd)
* Status: **Accepted with Revisions**
* Impacted Platforms: [Core]

## Introduction

This proposal is to make modifications in sdl_core to transform incoming `SetDisplayLayout` requests from applications into `UI.Show` requests to send to the HMI.

## Motivation

The `SetDisplayLayout` RPC was deprecated as a part of the changes for the [Widget Support](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md#setdisplaylayout) feature. In that proposal, a new `templateConfiguration` parameter was added to the `Show` RPC to allow it to take over the responsibilities of `SetDisplayLayout`. Given that `UI.Show` can now handle switching the display layout and changing the color schemes in the HMI, it would make sense to use `UI.Show` instead of having multiple implementations for the same functionality.

## Proposed solution

The proposed solution is to transform incoming `SetDisplayLayout` requests into `UI.Show` requests to be sent to the HMI. This will require the following changes to `set_display_layout_request.cc`

#### Change 1: Construct `UI.Show` request from `SetDisplayLayout` params

A `SetDisplayLayout` request can be transformed into a `UI.Show` request by using the `displayLayout`,`dayColorScheme`, `nightColorScheme` parameters from the original request in the `templateConfiguration` struct for the `UI.Show` request.

```c++
void SetDisplayLayoutRequest::Run() {
...
  smart_objects::SmartObject show_msg_params =
        smart_objects::SmartObject(smart_objects::SmartType_Map);

  if (msg_params.keyExists(strings::display_layout)) {
    new_layout = msg_params[strings::display_layout].asString();
+    show_msg_params[strings::template_configuration][strings::template_layout] = new_layout;
  }

...

  if (msg_params.keyExists(strings::day_color_scheme)) {
    SDL_LOG_DEBUG("Allow Day Color Scheme Change");
    app->set_day_color_scheme(msg_params[strings::day_color_scheme]);
+    show_msg_params[strings::template_configuration][strings::day_color_scheme] = msg_params[strings::day_color_scheme];
  }

  if (msg_params.keyExists(strings::night_color_scheme)) {
    SDL_LOG_DEBUG("Allow Night Color Scheme Change");
    app->set_night_color_scheme(msg_params[strings::night_color_scheme]);
+    show_msg_params[strings::template_configuration][strings::night_color_scheme] = msg_params[strings::night_color_scheme];
  }


-  (*message_)[strings::msg_params][strings::app_id] = app->app_id();
+  show_msg_params[strings::app_id] = app->app_id();
  

  MessageHelper::PrintSmartObject(show_msg_params);
  StartAwaitForInterface(HmiInterfaces::HMI_INTERFACE_UI);
  SendHMIRequest(hmi_apis::FunctionID::UI_Show,
                 &show_msg_params,
                 true);
}
```

#### Change 2: Send `UI.Show` request to the HMI in place of a `UI.SetDisplayLayout` request

```c++
void SetDisplayLayoutRequest::Run() {
...
  StartAwaitForInterface(HmiInterfaces::HMI_INTERFACE_UI);
-  SendHMIRequest(hmi_apis::FunctionID::UI_SetDisplayLayout,
-                 &((*message_)[strings::msg_params]),
+  SendHMIRequest(hmi_apis::FunctionID::UI_Show,
+                 &show_msg_params,
                 true);
}
```


#### Change 3: Transform `UI.Show` response to `SetDisplayLayout` response for application

While the HMI will return a `UI.Show` response for the transformed request, the application will still expect a `SetDisplayLayout` response.
This will require changes to transform the returned `UI.Show` response into a `SetDisplayLayout` response for the application.

```c++
SetDisplayLayoutRequest::SetDisplayLayoutRequest(
    const application_manager::commands::MessageSharedPtr& message,
    ApplicationManager& application_manager,
    app_mngr::rpc_service::RPCService& rpc_service,
    app_mngr::HMICapabilities& hmi_capabilities,
    policy::PolicyHandlerInterface& policy_handler)
    : CommandRequestImpl(message,
                         application_manager,
                         rpc_service,
                         hmi_capabilities,
                         policy_handler) {
+                           subscribe_on_event(hmi_apis::FunctionID::UI_Show);
                         }
...
void SetDisplayLayoutRequest::on_event(const event_engine::Event& event) {
...
  const smart_objects::SmartObject& message = event.smart_object();
  switch (event.id()) {
-    case hmi_apis::FunctionID::UI_SetDisplayLayout: {
+    case hmi_apis::FunctionID::UI_Show: {
...
}
```

## Potential downsides

These changes will prevent us from directly testing the `UI.SetDisplayLayout` RPC.

## Impact on existing code

This change will only impact the existing code for the `SetDisplayLayout` RPC request in `set_display_layout_request.cc`.

## Alternatives considered

The only alternative would be to continue sending `UI.SetDisplayLayout` requests to the HMI.
