# SDL Device Listener

* Proposal: [SDL-0301](0301-SDL-device-listener.md)
* Author: [Joey Grover](https://github.com/joeygrover)
* Status: **Accepted with Revisions**
* Impacted Platforms: [ Java Suite ]


## Introduction

The SDL Android library relies on a complex multiplexing system that operates through a foreground service. This service is started based on the connection of the Media and Phone bluetooth profiles. Since SDL is set up in a way that the mobile device acts as the listening server of a bluetooth SPP connection, the router service must be started and wait for incoming connections without knowing if anything will connect to it. This leads to the service having to start in the foreground for all bluetooth connections. One possible way to avoid this is by introducing a new prerequisite before starting the router service. This is done by adding a new class called `SDLDeviceListener` that will be activated in the `SDLBroadcastReceiver` to decide if the router service should be started or not.

## Motivation

Due to the fact that the original server side bluetooth transport solution can't be altered, it's important that we try to mitigate the unnecessary starting of a foreground service. This is because when starting a foreground service, the application must include putting a notification into the top level notification drawer. An icon will be shown to the user, with a message that has been included in the library. The issue is that most users do not have SDL enabled hardware, so when they see this notification they wonder what it is and how to get rid of it.

The SDL library already attempts to prevent the user from seeing the notification. This is done by quickly entering the foreground as required by the Android OS, then within 10 milliseconds, the service exits the foreground, notification is removed, and notification channel is deleted. However, based on testing different phones it was obvious that this has a multitude of different results. Some phones do exactly as expected and the notification is cleared before presented to the user. Other devices and OS versions will leave the notification in the tray for roughly 5 seconds until it is removed. The project maintainers have refactored the logic to avoid this for the majority of device and OS combinations, but some devices do not honor the APIs correctly. 

Because of these adverse situations, the library should alter its logic that handles the starting of the `SdlRouterService`. This can be accomplished by creating a new gatekeeper class that prevents the service from ever being started until there has been a confirmed SDL connection via the standard SDL UUID. This logic can be inserted into the `SdlBroadcastReceiver` without a lot of overhead to existing code.

## Proposed solution

The solution will be to create a temporary bluetooth server socket in the broadcast receiver that receives the bluetooth connection intents. A new thread will be spawned off that which will handle the listening. If a connection is made with the device, the bluetooth connection will be closed, and then the `SdlRouterService` will be started up directly to the foreground. A timeout handler will be present to keep the socket alive for a short duration without allowing it to run forever. Once the timeout expires, if there was no connection made, the socket will stop listening and the router service will not be started. In either case the MAC address will be saved into preferences with the results of a successful connection or not. 

On the next connection with that same device, via the MAC address, we can avoid this step if the device has been recognized as an SDL enabled device. If the device has not made a connection, the timeout window can be shortened. 

Leaving a small window of time to allow for connections at this stage is very important. The first time a device is connected, it might be plausible the SDL connection was just too slow and the following connection might catch the right timeout. The goal is to make sure there isn't a missed SDL enabled device while taking into consideration that most users do not interact with such devices.


### Flow

<img src="../assets/proposals/NNNN-SDL-device-listener/flow_chart.png" alt="POI app service example" class="inline" height= "75%" width= "75%" /> 

### SDLDeviceListener

This class will be a small, scoped class that will be instantiated into the `SdlBroadcastReceiver` code base. See the Appendix for the sample code.

#### Which apps create the SDLDeviceListener?

One of the main reasons the `SdlRouterService` functionality was created was to avoid the case where an Android device didn't have enough RFCOMM channels to support each app hosting their own. Obviously this proposal doesn't want to run into that same situation. Therefore, each app will use the same logic it does now to start an `SdlRouterService`, but instead of each app starting the service, only the app that has the service to be started will be the one to instantiate an `SDLDeviceListener` instance. All other apps will simply return out of that logic block. This will keep the RFCOMM channels used to only 1 per bluetooth connection. There is the caveat that if any older apps are installed, the old logic must be followed, so this feature will be dynamically enabled over time.

### SdlRouterService instantly stays in the foreground

Because we have confirmed the IVI system is a device that supports SDL, the `SdlRouterService` can be started in the foreground and left there for the longer duration before timeout. The current timeout for this case would be set to 30 seconds. This could be accomplished by adding a new extra to the intent that starts the `SdlRouterService` such as:

```java
	intent.putExtra("CONFIRMED_SDL_DEVICE", true);
```

If the `SdlRouterService` receives this flag it will stay in foreground. This could be changed in the future to allow the service to stay in the foreground even longer than 30 seconds if necessary. 

### Saving Bluetooth devices after binding to `SdlRouterService`

In order to prevent future cases where the app that spins up an `SDLListener` doesn't know the device even though it has connected in the past, the library should save the MAC address received from the trusted `SdlRouterService` after it binds for an SDL session. This will allow all apps to be aware of that device in the future and speed up the process. This should happen in the `TransportManager` class.

## Potential downsides

- There is a chance that the first time a user connects their mobile device to an SDL enabled IVI system the router service will not connect. Subsequent connections, however, should be very likely.
- Because older apps will still start the router service like normal, the updated flow will be less impactful until all the users apps have updated to the new scheme.
- Since the `SdlRouterService` operates on a different process, there is no way to transfer the shared preference objects without explicitly doing so with other means such as intents, binding, etc. This means each app will have to learn about the bluetooth devices it encounters over time. However, it should be rather quick since apps will save the MAC address after binding to a trusted router service anyways.
- If a user swipes away the app from the Recent Apps screen during the listening period after a device connects, the `SDLDeviceListener` will be closed prematurely. The probability that a user will be doing this within 30 seconds of a device connected that is SDL enabled is very low and therefore shouldn't be an issue. On the next connection the process will try again and could succeed. 


## Impact on existing code

- The `SdlBroadcastReceiver` will need logic refactored to handle the new class `SdlListener` so that it would move its normal flow into a different method/callback. 

## Alternatives considered
- No other solutions considered

## Appendix

### `SdlDeviceListener` Sample Code

```java
ublic class SdlDeviceListener {

    private static final String TAG = "SdlDeviceListener";
    private static final String SDL_DEVICE_STATUS_SHARED_PREFS = "sdl.device.status";
    private static final Object LOCK = new Object();

    private final WeakReference<Context> contextWeakReference;
    private final Callback callback;
    private final BluetoothDevice connectedDevice;
    private MultiplexBluetoothTransport bluetoothTransport;
    private TransportHandler bluetoothHandler;
    private Handler timeoutHandler;
    private Runnable timeoutRunner;


    public SdlDeviceListener(Context context, BluetoothDevice device, Callback callback){
        this.contextWeakReference = new WeakReference<>(context);
        this.connectedDevice = device;
        this.callback = callback;
    }

    public void start(){
        if(hasSDLConnected(connectedDevice.getAddress())){
            Log.d(TAG, "Already connected to device, starting RS");
            //This device has connected to SDL previously, it is ok to start the RS right now
            callback.onTransportConnected(new TransportRecord(TransportType.BLUETOOTH,connectedDevice.getAddress()));
            return;
        }

        // set timeout = if first time seeing BT device, 30s, if not 15s
        int timeout = isFirstStatusCheck(connectedDevice.getAddress()) ? 30000 : 15000;
        //Set our preference as false for this device for now
        setSDLConnectedStatus(connectedDevice.getAddress(),false);
        initBluetoothHandler();
        bluetoothTransport = new MultiplexBluetoothTransport(bluetoothHandler);
        bluetoothTransport.start();
        timeoutRunner = new Runnable() {
            @Override
            public void run() {
                if(bluetoothTransport != null){
                    int state =  bluetoothTransport.getState();
                    if (state != MultiplexBluetoothTransport.STATE_CONNECTED){
                        Log.d(TAG, "No bluetooth connection made");
                        bluetoothTransport.stop();
                        //bluetoothTransport.stop(MultiplexBluetoothTransport.STATE_ERROR);
                    } //else BT is connected still; it will close itself
                }
            }
        };
        timeoutHandler = new Handler(Looper.getMainLooper());
        timeoutHandler.postDelayed(timeoutRunner, timeout);
    }

    private void initBluetoothHandler(){
        bluetoothHandler = new TransportHandler(this);
    }

    private static class TransportHandler extends Handler{

        final WeakReference<SdlDeviceListener> provider;

        TransportHandler(SdlDeviceListener provider){
            this.provider = new WeakReference<>(provider);
        }

        @Override
        public void handleMessage(@NonNull Message msg) {
            if(this.provider.get() == null){
                return;
            }
            SdlDeviceListener sdlDeviceListener = this.provider.get();
            switch (msg.what) {

                case SdlRouterService.MESSAGE_STATE_CHANGE:
                    TransportRecord transportRecord = (TransportRecord) msg.obj;
                    switch (msg.arg1) {
                        case MultiplexBaseTransport.STATE_CONNECTED:
                            sdlDeviceListener.setSDLConnectedStatus(transportRecord.getAddress(),true);
                            boolean keepConnectionOpen = sdlDeviceListener.callback.onTransportConnected(transportRecord);
                            if( !keepConnectionOpen ) {
                                sdlDeviceListener.bluetoothTransport.stop();
                                sdlDeviceListener.bluetoothTransport = null;
                                sdlDeviceListener.timeoutHandler.removeCallbacks(sdlDeviceListener.timeoutRunner);
                            }
                            break;
                        case MultiplexBaseTransport.STATE_CONNECTING:
                            // Currently attempting to connect - update UI?
                            break;
                        case MultiplexBaseTransport.STATE_LISTEN:
                            break;
                        case MultiplexBaseTransport.STATE_NONE:
                            // We've just lost the connection
                            sdlDeviceListener.callback.onTransportDisconnected(transportRecord);
                            break;
                        case MultiplexBaseTransport.STATE_ERROR:
                            sdlDeviceListener.callback.onTransportError(transportRecord);
                            break;
                    }
                    break;

                case com.smartdevicelink.transport.SdlRouterService.MESSAGE_READ:
                    //service.onPacketRead((SdlPacket) msg.obj);
                    break;
            }
        }
    }


    /**
     * Set the connection establishment status of the particular device
     * @param address address of the device in question
     * @param hasSDLConnected true if a connection has been established, false if not
     */
    private void setSDLConnectedStatus(String address, boolean hasSDLConnected){
        synchronized (LOCK) {
            Context context = contextWeakReference.get();
            if (context != null) {
                Log.d(TAG, "Saving connected status - " + address + " : " + hasSDLConnected);
                SharedPreferences preferences = context.getSharedPreferences(SDL_DEVICE_STATUS_SHARED_PREFS, Context.MODE_PRIVATE);
                SharedPreferences.Editor editor = preferences.edit();
                editor.putBoolean(address, hasSDLConnected);
                editor.commit();
            }
        }
    }

    /**
     * Checks to see if a device address has connected to SDL before.
     * @param address the mac address of the device in question
     * @return if this is the first status check of this device
     */
    private boolean isFirstStatusCheck(String address){
        synchronized (LOCK) {
            Context context = contextWeakReference.get();
            if (context != null) {
                SharedPreferences preferences = context.getSharedPreferences(SDL_DEVICE_STATUS_SHARED_PREFS, Context.MODE_PRIVATE);
                return !preferences.contains(address);
            }
            return false;
        }
    }
    /**
     * Checks to see if a device address has connected to SDL before.
     * @param address the mac address of the device in question
     * @return if an SDL connection has ever been established with this device
     */
    private boolean hasSDLConnected(String address){
        synchronized (LOCK) {
            Context context = contextWeakReference.get();
            if (context != null) {
                SharedPreferences preferences = context.getSharedPreferences(SDL_DEVICE_STATUS_SHARED_PREFS, Context.MODE_PRIVATE);
                return preferences.contains(address) && preferences.getBoolean(address, false);
            }
            return false;
        }
    }

    public interface Callback{
        /**
         *
         * @param transportRecord
         * @return if the connection should stay open
         */
        boolean onTransportConnected(TransportRecord transportRecord);
        void onTransportDisconnected(TransportRecord transportRecord);
        void onTransportError(TransportRecord transportRecord);
    }
}
```
