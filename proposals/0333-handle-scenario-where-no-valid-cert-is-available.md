# Handle Scenario Where no Valid Cert is Available

* Proposal: [SDL-0333](0333-handle-scenario-where-no-valid-cert-is-available.md)
* Author: [Collin McQueen](https://github.com/iCollin)
* Status: **Returned for Revisions**
* Impacted Platforms: [Core]

## Introduction
This proposal defines how Core should respond to a request to start a protected service when it does not have a valid certificate to complete a handshake.

## Motivation
Currently, if an app requests a protected session while SDL Core does not have a valid certificate the request will be pending until Core either is able to retrieve a valid certificate through PTU or if the whole PTU retry sequence fails. In the default configuration, the PTU retry sequence can take up to 17 minutes, which means that if an app attempts to start a protected service early in Core's lifecycle it may take quite a while for the app to receive a response. This could cause a poor user experience.

## Proposed solution
When SDL Core receives a request to start a protected service but does not have a valid certificate, it will create a timer to ensure the handshake isn't pending for too long.

### Changes to smartDeviceLink.ini
A new variable will be created to configure how long SDL Core should wait before timing out a pending handshake.
The following lines will be added to the `[Policy]` section:
```
; Time in milliseconds for a handshake to wait for a PTU
HandshakeTimeout = 15000
```

### Changes to Start Service Process

#### When SDL Core does have valid certificate
In the case SDL Core does have valid certificate the Start Service process will go on exactly as it has before.

#### When SDL Core does not have valid certificate
In the case SDL Core has no certificate or has invalid certificate, either because SDL Core was unable to retrieve the certificate due date or the certificate is expired, it will attempt to retrieve a new certificate via PTU. When this happens, Core will also start a timer to ensure that the request isn't pending for too long. When this timer expires, Core will reply to the app which requested the protected service and notify the HMI to let it know the service request is no longer pending.

If a PTU is completed and Core receives a valid certificate before the `HandshakeTimeout` timer expires, SDL Core will reply as it had before and remove the created timer from memory.

![handleScenarioWhereNoValidCertIsAvailable](https://user-images.githubusercontent.com/12716076/117061498-4a15c000-acf0-11eb-9907-ebc733d236ba.png)

### Changes to OnPermissionsChange
In order to notify an application when a valid certificate is found, changes are proposed to the `OnPermissionsChange` notification:

```
    <function name="OnPermissionsChange" functionID="OnPermissionsChangeID" messagetype="notification" since="2.0">
        <description>Provides update to app of which policy-table-enabled functions are available</description>
        <param name="permissionItem" type="PermissionItem" minsize="0" maxsize="500" array="true" mandatory="true">
            <description>Change in permissions for a given set of RPCs</description>
        </param>
        <param name="requireEncryption" type="Boolean" mandatory="false" since="6.0"/>
+       <param name="encryptionReady" type="Boolean" mandatory="false" since="x.x">
+           <description>If true, encryption is ready. If false, encryption is not ready. If omitted, mobile assumes encryption ready.</description>
+       </param>
    </function>
```

In the case an app's StartService was NAK'd because Core did not have a valid certificate, when the app receives `OnPermissionsChange` with `encryptionReady = true` it will know that it may retry its StartService.

## Potential downsides
The author did not identify any potential downsides to this proposal.

## Impact on existing code
This would require code changes to SDL Core to handle the new INI parameter and to create the new timer and callback within the Security Manager.

## Alternatives considered

#### Reply to pending Start Service requests on PTU Retry

After a failed PTU attempt, Core will finish all pending handshakes as failures.

The proposed solution was selected because it more directly addresses the issue by defining a maximum time any start service request may be awaiting certificates.
