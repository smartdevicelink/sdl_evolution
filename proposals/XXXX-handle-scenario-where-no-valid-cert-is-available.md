# Handle Scenario Where no Valid Cert is Available

* Proposal: [SDL-XXXX](XXXX-handle-scenario-where-no-valid-certs-are-available.md)
* Author: [Collin McQueen](https://github.com/iCollin)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction
This proposal defines how Core should respond to a request to start a protected service when it does not have a valid certificate to complete a handshake.

## Motivation
Currently, if an app requests a protected session while SDL Core does not have a valid certificate the request will be pending until Core either is able to retrieve a valid certificate through PTU or if the whole PTU retry sequence fails. In the default configuration, the PTU retry sequence can take up to 17 minutes, which means that if an app attempts to start a protected service early in Core's lifecycle it will take quite a while for the app to receive a response. This could cause a poor user experience.

## Proposed solution
We will add a new INI parameter `Policy.HandshakeTimeout` which is set to 15000 by default. When `SecurityManagerImpl::PostponeHandshake` is called and `waiting_for_certificate_` is true, a single shot timer will be created with a delay of `Policy.HandshakeTimeout`. The timer's callback will call `SecurityManagerImpl::NotifyListenersOnHandshakeDone(connection_key, SSLContext::Handshake_Result_Fail)` and remove the `connection_key` from `awaiting_certificate_connections_` if the connection is still pending when the timeout is reached.

### Changes to smartDeviceLink.ini
The following lines will be added to the `[Policy]` section:
```
; Time in milliseconds for a handshake to wait for a PTU
HandshakeTimeout = 15000
```

### Changes to Start Service Process

#### When SDL Core does have valid certificate
In the case SDL Core does have valid certificate the Start Service process will go on exactly as it has before.

#### When SDL Core does not have valid certificate
In the case SDL Core has no certificate or has invalid certificate, either because SDL Core was unable to retrieve the certificate due date or the certificate is expired, SDL Core calls `SecurityManager::PostponeHandshake`. 

Currently, `PostponeHandshake` will add the pending connection to a vector, `awaiting_certificate_connections_` where the connection will remain pending in a `ServiceEvent` state of `REQUEST_RECEIVED` until either a PTU successfully retrieves a valid certificate, or the entire retry sequence finishes. (which by default takes up to seventeen minutes) This potential long pending service start could result in a poor user experience.

By creating a timer when `PostponeHandshake` is called, we can limit the amount of time a start service will be pending when a valid certificate is not available. This timer would have a timeout configurable in `smartDeviceLink.ini` under the section `Policy` named `HandshakeTimeout`. This timer's callback would first remove the pending connection from the `awaiting_certificate_connections_` vector and then indirectly call `HandshakeHandler::ProcessFailedHandshake` with `ServiceStatus::CERT_INVALID`. If the service may be unprotected, the service will be able to start after 15 seconds instead of after the entire retry sequence finishes, if the service is force protected, the user will receive feedback that the StartService failed after 15 seconds instead of after the entire retry sequence is complete. In both situations, the user experience is improved by limiting the time this connection can be in a pending state.

If a PTU is completed and Core receives a valid certificate before the `HandshakeTimeout` timer expires, SDL Core will reply as it had before and remove the created timer from memory.

![handleScenarioWhereNoValidCertIsAvailable](https://user-images.githubusercontent.com/12716076/117061498-4a15c000-acf0-11eb-9907-ebc733d236ba.png)

## Potential downsides
There is the possibility a service will be NAK'd which could be ACK'd later on.

## Impact on existing code
This would require code changes to SDL Core to handle the new INI parameter and to create the new timer and callback within the Security Manager.

## Alternatives considered

#### Reply to pending Start Service requests on PTU Retry

We will add a new INI parameter `Policy.FailHandshakeAfterRetries` which is set to `2` by default. When `PolicyManagerImpl::OnPTUIterationTimeout` is called it will check if `retry_sequence_index_` is greater than or equal to this `Policy.FailHandshakeAfterRetries` value. If true, `SecurityManagerImpl::waiting_for_certificate_` will be set to false and all `SecurityManagerImpl::awaiting_certificate_connections_` will have `OnHandshakeDone(connection_key, SSLContext::Handshake_Result_Fail)` called.

The proposed solution was selected because it more directly addresses the issue by defining a maximum time any start service request may be awaiting certificates.

#### Reply to pending Start Service requests on every PTU Retry

This would be the same as the above solution but without the INI parameter, instead taking action every time `PolicyManagerImpl::OnPTUIterationTimeout` is called.
