# Allow navigation apps to access information about WiFi networks


* Proposal: [SDL-0291](0291-allows-navigation-apps-to-access-information-about-Wi-Fi-networks.md)
* Author: [Zhou Xin](https://github.com/zhouxin627)
* Status: **In Review**
* Impacted Platforms: [Java Suite]

## Introduction
This proposal requires all current navigation apps to include a new permission (android.permission.ACCESS_WIFI_STATE) to benefit from the issue fix as follows:
https://github.com/smartdevicelink/sdl_java_suite/pull/1259


## Motivation
Currently, there are some issues with navigation apps when users enable WiFi after the navigation apps are activated.

For example:
1. SDL failed to start video streaming if users enable WiFi on the head unit after the NaviAPP is activated.
https://github.com/smartdevicelink/sdl_java_suite/issues/1235
2. SDL failed to start video streaming if users enable WiFi on the phone more than 150s after the NaviAPP is activated.
https://github.com/smartdevicelink/sdl_java_suite/issues/1236

Basically, the problem is that NaviAPPs start video streaming unsuccessfully in the following use cases:

1. Activate the NaviAPP, then enable WiFi on the head unit within 150 seconds.
2. Activate the NaviAPP, wait more than 150 seconds, then enable WiFi on the head unit.
3. Activate the NaviAPP, wait more than 150 seconds, then enable WiFi on the phone

The root cause of the problem is that, in the above three situations, there is no mechanism to trigger the reestablishment of secondary transport (TCP) for `VideoStreaming` in Java Suite currently.
There is a complete solution to these problems.
It would help SDL greatly improve the user experience on `VideoStreaming` via BT+WiFi.

To listen to WiFi state change, we register a receiver that receives WiFi state change to the transport layer, and then modify the timing of request TCP connection when receiving WiFi state change.

Please refer to Appendix section for sample code.

The implementation of WIFI state receiver is as follows.
```Java
    private BroadcastReceiver wifiBroadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if(intent != null){
                String action = intent.getAction();
                if (WifiManager.NETWORK_STATE_CHANGED_ACTION.equals(action)) {
                    NetworkInfo info = intent.getParcelableExtra(WifiManager.EXTRA_NETWORK_INFO);
                    if (info != null) {
                        boolean isWifiConnected = info.getState().equals(NetworkInfo.State.CONNECTED);
                        if (mIsWifiConnected != isWifiConnected) {
                            mIsWifiConnected = isWifiConnected;
                            if (transportListener != null) {
                                transportListener.onWifiStateUpdate(mIsWifiConnected);
                            }
                        }
                    }
                } else if (WIFI_AP_STATE_CHANGED_ACTION.equals(action)) {
                    int state = intent.getIntExtra("wifi_state", 0);
                    mIsWifiAPStateEnabled = state == WIFI_AP_STATE_ENABLED;
                }
            }
        }
    };
```
The new permission `android.permission.ACCESS_WIFI_STATE` is required to use the above mentioned API.

### Sequence diagram
<img src="../assets/proposals/0291-allows-navigation-apps-to-access-information-about-Wi-Fi-networks/sequence_diagram.png" alt="sequence diagram" class="inline" height= "75%" width= "75%" /> 

## Proposed solution
Add manifest permission to navigation apps that allows them to access information about WiFi networks.

```xml
    <!-- Required to check if WiFi is enabled -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
+   <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

## Potential downsides
No downsides were identified.

## Impact on existing code
This will be a minor version change to the Java Suite Library.

## Alternatives considered
No alternatives were identified.

## Appendix
### Sample Code
#### VideoStreamManager.java
```java
    @Override
    public void start(CompletionListener listener) {
+       this.listener = listener;
+       hasStarted = false;
        isTransportAvailable = internalInterface.isTransportForServiceAvailable(SessionType.NAV);
        getVideoStreamingParams();
        checkState();
        super.start(listener);
    }
...
    @Override
    protected void onTransportUpdate(List<TransportRecord> connectedTransports, boolean audioStreamTransportAvail, boolean videoStreamTransportAvail){
        isTransportAvailable = videoStreamTransportAvail;
        if(internalInterface.getProtocolVersion().isNewerThan(new Version(5,1,0)) >= 0){
            if(videoStreamTransportAvail){
+               if (hasStarted && listener != null && getState() == SETTING_UP) {
+                   // When the TCP connection is disconnected, the stateMachine will be set to SETTING_UP in 4.11.0.
+                   start(listener);
+               } else {
                    checkState();
+               }
            }
        }else{
            //The protocol version doesn't support simultaneous transports.
            if(!videoStreamTransportAvail){
                //If video streaming isn't available on primary transport then it is not possible to
                //use the video streaming manager until a complete register on a transport that
                //supports video
                transitionToState(ERROR);
            }
        }
    }
```
#### TransportManager.java
```java
    public class TransportManager extends TransportManagerBase{
        private static final String TAG = "TransportManager";
+       private static final String WIFI_AP_STATE_CHANGED_ACTION = "android.net.wifi.WIFI_AP_STATE_CHANGED";
+       private static final int WIFI_AP_STATE_ENABLED = 13;

        TransportBrokerImpl transport;
...
        @Override
        public void start(){
            if(transport != null){
                if (!transport.start()){
                    //Unable to connect to a router service
                    if(transportListener != null){
                        transportListener.onError("Unable to connect with the router service");
                    }
                }
            }else if(legacyBluetoothTransport != null){
                legacyBluetoothTransport.start();
            }

+           if(contextWeakReference.get() != null) {
+               IntentFilter intentFilter = new IntentFilter();
+               intentFilter.addAction(WifiManager.NETWORK_STATE_CHANGED_ACTION);
+               intentFilter.addAction(WIFI_AP_STATE_CHANGED_ACTION);
+               contextWeakReference.get().registerReceiver(wifiBroadcastReceiver, intentFilter);
+           }
        }

        @Override
        public void close(long sessionId){
            if(transport != null) {
                transport.removeSession(sessionId);
                transport.stop();
            }else if(legacyBluetoothTransport != null){
                legacyBluetoothTransport.stop();
                legacyBluetoothTransport = null;
            }

+           if(contextWeakReference != null){
+               contextWeakReference.get().unregisterReceiver(wifiBroadcastReceiver);
+           }
        }
...
+       private BroadcastReceiver wifiBroadcastReceiver = new BroadcastReceiver() {
+           @Override
+           public void onReceive(Context context, Intent intent) {
+               if(intent != null){
+                   String action = intent.getAction();
+                   if (WifiManager.NETWORK_STATE_CHANGED_ACTION.equals(action)) {
+                       NetworkInfo info = intent.getParcelableExtra(WifiManager.EXTRA_NETWORK_INFO);
+                       if (info != null) {
+                           boolean isWifiConnected = info.getState().equals(NetworkInfo.State.CONNECTED);
+                           if (mIsWifiConnected != isWifiConnected) {
+                               mIsWifiConnected = isWifiConnected;
+                               if (transportListener != null) {
+                                   transportListener.onWifiStateUpdate(mIsWifiConnected);
+                               }
+                           }
+                       }
+                   } else if (WIFI_AP_STATE_CHANGED_ACTION.equals(action)) {
+                       int state = intent.getIntExtra("wifi_state", 0);
+                       mIsWifiAPStateEnabled = state == WIFI_AP_STATE_ENABLED;
+                   }
+               }
+           }
+       };
```
#### SdlProtocolBase.java
```java
    private boolean isSecondaryTransportAvailable(boolean onlyHighBandwidth){
        if (supportedSecondaryTransports != null) {
            for (TransportType supportedSecondary : supportedSecondaryTransports) {
                if(!onlyHighBandwidth || supportedSecondary == TransportType.USB || supportedSecondary == TransportType.TCP) {
                    if (transportManager != null && transportManager.isConnected(supportedSecondary, null)) {
                        //A supported secondary transport is already connected
                        return true;
                    } else if (secondaryTransportParams != null && secondaryTransportParams.containsKey(supportedSecondary)
+                           && (transportManager != null && (transportManager.isWifiConnected() || transportManager.isWifiAPStateEnabled()))) {
                        //A secondary transport is available to connect to
                        return true;
                    }
                }
            }
        }
        // No supported secondary transports
        return false;
    }

    public void startService(SessionType serviceType, byte sessionID, boolean isEncrypted) {
...
                //If the secondary transport isn't connected yet that will have to be performed first

                List<ISecondaryTransportListener> listenerList = secondaryTransportListeners.get(secondaryTransportType);
                if(listenerList == null){
                    listenerList = new ArrayList<>();
                    secondaryTransportListeners.put(secondaryTransportType, listenerList);
                }
+               else {
+                   listenerList.clear();
+               }
...
    @SuppressWarnings("FieldCanBeLocal")
    final TransportManagerBase.TransportEventListener transportEventListener = new TransportManagerBase.TransportEventListener() {
...
        @Override
        public void onTransportDisconnected(String info, TransportRecord disconnectedTransport, List<TransportRecord> connectedTransports) {
            if (disconnectedTransport == null) {
                Log.d(TAG, "onTransportDisconnected");
                if (transportManager != null) {
                    transportManager.close(iSdlProtocol.getSessionId());
                }
                iSdlProtocol.shutdown("No transports left connected");
                return;
            } else {
                Log.d(TAG, "onTransportDisconnected - " + disconnectedTransport.getType().name());
+               if (disconnectedTransport.getType() == TransportType.TCP && secondaryTransportParams != null) {
+                   if (activeTransports.containsValue(disconnectedTransport)
+                           && (transportManager != null && (transportManager.isWifiConnected() || transportManager.isWifiAPStateEnabled()))) {
+                       // If the established TCP connection is disconnected, the corresponding IP and port are invalid and should be removed from the list.
+                       // Otherwise, isTransportForServiceAvailable is always true after disconnection.
+                       // Do not remove when WiFi is connected or access point is enabled on mobile device, because the app needs to use it when connected again.
+                       secondaryTransportParams.remove(TransportType.TCP);
+                   }
+               }
            }
...
        @Override
        public boolean onLegacyModeEnabled(String info) {
            //Await a connection from the legacy transport
            if(requestedPrimaryTransports!= null && requestedPrimaryTransports.contains(TransportType.BLUETOOTH)
                    && !SdlProtocolBase.this.requiresHighBandwidth){
                Log.d(TAG, "Entering legacy mode; creating new protocol instance");
                reset();
                return true;
            }else{
                Log.d(TAG, "Bluetooth is not an acceptable transport; not moving to legacy mode");
                return false;
            }
        }

+       @Override
+       public void onWifiStateUpdate(boolean isWifiConnected) {
+           Log.d(TAG, "onWifiStateUpdate: isWifiConnected = " + isWifiConnected);
+           if (isWifiConnected) {
+               notifyDevTransportListener();
+           }
+       }
    };
...
        /**
         * Directing method that will push the packet to the method that can handle it best
         * @param packet a control frame packet
         */
        private void handleControlFrame(SdlPacket packet) {
            Integer frameTemp = packet.getFrameInfo();
            Byte frameInfo = frameTemp.byteValue();
...
            } else if (frameInfo == FrameDataControlFrameType.TransportEventUpdate.getValue()) {

                // Get TCP params
                String ipAddr = (String) packet.getTag(ControlFrameTags.RPC.TransportEventUpdate.TCP_IP_ADDRESS);
                Integer port = (Integer) packet.getTag(ControlFrameTags.RPC.TransportEventUpdate.TCP_PORT);

                if(secondaryTransportParams == null){
                    secondaryTransportParams = new HashMap<>();
                }

                if(ipAddr != null && port != null) {
                    String address = (port != null && port > 0) ? ipAddr + ":" + port : ipAddr;
                    secondaryTransportParams.put(TransportType.TCP, new TransportRecord(TransportType.TCP,address));

                    //A new secondary transport just became available. Notify the developer.
                    notifyDevTransportListener();
+               } else {
+                   // Remove secondaryTransportParams when head unit WiFi is disconnected.
+                   secondaryTransportParams.remove(TransportType.TCP);
                }

            }
```
#### TransportManagerBase.java
```java
public abstract class TransportManagerBase {
    private static final String TAG = "TransportManagerBase";

    final Object TRANSPORT_STATUS_LOCK;

    final List<TransportRecord> transportStatus;
    final TransportEventListener transportListener;
+   boolean mIsWifiConnected;
+   boolean mIsWifiAPStateEnabled;
...
    public void requestSecondaryTransportConnection(byte sessionId, TransportRecord transportRecord){
        //Base implementation does nothing
    }

+   public boolean isWifiConnected() {
+       return mIsWifiConnected;
+   }
+
+   public boolean isWifiAPStateEnabled() {
+       return mIsWifiAPStateEnabled;
+   }
...
    public interface TransportEventListener{
        /** Called to indicate and deliver a packet received from transport */
        void onPacketReceived(SdlPacket packet);

        /** Called to indicate that transport connection was established */
        void onTransportConnected(List<TransportRecord> transports);

        /** Called to indicate that transport was disconnected (by either side) */
        void onTransportDisconnected(String info, TransportRecord type, List<TransportRecord> connectedTransports);

        // Called when the transport manager experiences an unrecoverable failure
        void onError(String info);
        /**
         * Called when the transport manager has determined it needs to move towards a legacy style
         * transport connection. It will always be bluetooth.
         * @param info simple info string about the situation
         * @return if the listener is ok with entering legacy mode
         */
        boolean onLegacyModeEnabled(String info);

+       /** Called to indicate that WiFi was connected/disconnected (by mobile device) */
+       void onWifiStateUpdate(boolean isWifiConnected);
    }
}
```
