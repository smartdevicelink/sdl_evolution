# Handle Scenario Where no Valid Certs are Available

* Proposal: [SDL-XXXX](XXXX-handle-scenario-where-no-valid-certs-are-available.md)
* Author: [Collin McQueen](https://github.com/iCollin)
* Status: **Awaiting review**
* Impacted Platforms: [Core]

## Introduction
This proposal defines how Core should respond to a request to start a protected service when it does not have valid certificates to complete a handshake.

## Motivation
Currently, if an app requests a protected session while SDL Core does not have valid certificates the request will be pending until Core either is able to retrieve valid certificates through PTU or if the whole PTU retry sequence fails. In the default configuration, the PTU retry sequence can take up to 17 minutes, which means that if an app attempts to start a protected service early in Core's lifecycle it will take quite a while for the app to receive a response. This could cause a poor user experience.

## Proposed solution
We will add a new INI parameter `Policy.HandshakeTimeout` which is set to 15000 by default. When `SecurityManagerImpl::PostponeHandshake` is called and `waiting_for_certificate_` is true, a single shot timer will be created with a delay of `Policy.HandshakeTimeout`. The timer's callback will call `SecurityManagerImpl::NotifyListenersOnHandshakeDone(connection_key, SSLContext::Handshake_Result_Fail)` and remove the `connection_key` from `awaiting_certificate_connections_` if the connection is still pending when the timeout is reached.

## Potential downsides
There is the possibility a service will be NAK'd which would have been ACK'd later on.

## Impact on existing code
This would require code changes to SDL Core to handle the new INI parameter and to create the new timer and callback within the Security Manager.

## Alternatives considered

#### Reply to pending Start Service requests on PTU Retry

We will add a new INI parameter `Policy.FailHandshakeAfterRetries` which is set to `2` by default. When `PolicyManagerImpl::OnPTUIterationTimeout` is called it will check if `retry_sequence_index_` is greater than or equal to this `Policy.FailHandshakeAfterRetries` value. If true, `SecurityManagerImpl::waiting_for_certificate_` will be set to false and all `SecurityManagerImpl::awaiting_certificate_connections_` will have `OnHandshakeDone(connection_key, SSLContext::Handshake_Result_Fail)` called.

The proposed solution was selected because it more directly addresses the issue by defining a maximum time any start service request may be awaiting certificates.

#### Reply to pending Start Service requests on every PTU Retry

This would be the same as the above solution but without the INI parameter, instead taking action every time `PolicyManagerImpl::OnPTUIterationTimeout` is called.
