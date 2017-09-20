# Android SDL Internal Interface

* Proposal: [SDL-NNNN](NNNN-android_proxy_interface.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Awaiting Review**
* Impacted Platforms: [Android]

## Introduction
The internal SDL interface will help reduce the dependency on the SDLProxyBase class and allow us to move away from it in the future when we introduce a more enhanced framework.

## Motivation
The proxy object is passed around the Android library constantly. This forces a maintenance burden around SDLProxyBase and the managers that reference it. Creating a simple interface that the proxy implements will reduce the dependency on the actual proxy class. It will also help create a consistent interface to the proxy so that different managers won't introduce new methods that essentially do the same thing.

## Proposed solution
A new interface would be introduced ISdl. This interface should only be used for managers within the library itself. The `SdlProxyBase` class would implement this for now and all managers connected to it would keep this interface as the reference over the proxy object itself when possible. As needs develop we can add more methods to the interface that make sense on a common/wide-scale need. Then when we move to an enhanced framework we will not have to recode the majority of managers to keep a reference to the new life cycle manager or similar, instead we can reuse the interface in the main manager.

```java
/**
 * We don't include startRPCService, startHybridService, or startControlService as they are inherently started.
 * <b>This interface is for internal classes only. No developer should be using this interface directly as breaking changes may occur.</b>
 */
public interface ISdl{
    /**
     * Starts the connection with the module
     */
    void start();

    /**
     * Ends connection with the module
     */
    void stop();

    /**
     * Method to check if the session is connected
     * @return if there is a connected session
     */
    boolean isConnected();

    /**
     * Add a service listener for a specific service type
     * @param serviceType
     * @param sdlServiceListener
     */
    void addServiceListener(SessionType serviceType, ISdlServiceListener sdlServiceListener);

    /**
     * Remote a service listener for a specific service type
     * @param serviceType
     * @param sdlServiceListener
     */
    void removeServiceListener(SessionType serviceType, ISdlServiceListener sdlServiceListener);

    /**
     * Starts the video streaming service
     * @param parameters
     */
    void startVideoService(VideoStreamingParameters parameters);

    /**
     * Stops the video service if open
     */
    void stopVideoService();

    /**
     * Starts the Audio streaming service
     */
    void startAudioService();

    /**
     * Stops the audio service if open
     */
    void stopAudioService();

    /**
     * Pass an RPC message through the proxy to be sent to the connected module
     * @param message
     */
    void sendRPC(RPCMessage message);

    /**
     * Set an OnRPCNotificationListener for specified notification
     * @param notificationId
     * @param listener
     */
    void setNotificationListener(FunctionID notificationId, OnRPCNotificationListener listener);
}


```

## Potential downsides
- None that could be observed.

## Impact on existing code
- The new interface will be introduced and the `SdlProxyBase` will implement it
- The `VirtualDisplayEncoder` will be the first module to use the interface

## Alternatives considered
- Including the ServiceListener in the `startVideoService` and `startAudioService` methods. This might be a cleaner API, however, it isn't clear when the listener's should be removed. Adding it to the end service methods wouldn't work as the manager might want to know when the service actually ends, not just request it to end.
