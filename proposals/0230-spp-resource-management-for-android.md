# SPP resource management for Android

* Proposal: [SDL-0230](0230-spp-resource-management-for-android.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **Returned for Revisions**
* Impacted Platforms: Java Suite

## Introduction

RFCOMM is a connection-oriented, streaming transport over Bluetooth, which is known as Serial Port Profile (SPP) in Android. 
SDL Proxy uses BluetoothServerSocket to listen on a SPP channel, and it is used for primary transport.
On an Android device, the number of SPP resources is limited, and BluetoothServerSocket fails to accept connections when SPP channel runs out of available resources.
Current SDL Proxy does not handle that case very well. This proposal is to improve the SPP resource management in SDL Android.

## Motivation

This proposal addresses two issues regarding SPP resource management.

1. It improves user experience of an edge case where SPP resources are exhausted and an app cannot communicate with head unit. Right now, that error is not notified to the app. A user has no way to figure out why connection fails.
2. MultiplexingTransport has legacy mode, which won't be used in normal case. It reduces the SPP resource consumption by disabling the legacy mode. Right now, legacy mode is used if SdlProxy failed to find the target RouterService.

## Proposed solution

### Detect the case where BluetoothServerSocket fails to accept a connection from head unit. 
Even though we could detect the case, we cannot increase the number of available SPP resources, because they are used by other apps.
All we can do in this case is notify users that SPP channel runs out of available resources, and let users close some apps that may use the BluetoothSocket. It's not practical to show SPP service records that are used by Bluetooth adapter. It's sufficient just to notify users that we're running out of resources.

Prior to detecting the error, we can define the runnable interface as the listener in MultiplexBluetoothTransport class:
```java
    private Runnable mSocketErrorListener;
```
and define the setter:
```java
    public void setSocketErrorListener(Runnable onError) {
        mSocketErrorListener = onError;
    }
```

In SdlRouterService, we can implement the runnable something like below:
```java
    bluetoothTransport.setSocketErrorListener(new Runnable() {
        @Override
        public void run() {
            if (mNotificationDialogListener != null) {
                mNotificationDialogListener.onRequestShowDialog(NotificationDialogListener.MessageType.ERROR_OUT_OF_SPP_RESOURCE);
            }
        }
    });
```

mNotificationListener is the interface defined below:
```java
    public interface NotificationDialogListener {
        /**
         * Type of the message in the dialog.
         */
        enum MessageType {
            /**
             * This message indicates that SdlRoterService fails to start SPP services due to out-of-
             * resources issue. The user needs to close other apps which use BluetoothSocket.
             */
            ERROR_OUT_OF_SPP_RESOURCE,
            // there may be other message types
        }

        /**
         * This method is called on the main thread when RouterService wants to show a dialog.
         *
         * @param type  Indicates the message which will be shown by the dialog.
         */
        void onRequestShowDialog(MessageType type);
    }

	private NotificationDialogListener mNotificationDialogListener;
	public void setNotificationDialogListener(NotificationDialogListener listener) {
		mNotificationDialogListener = listener;
    }
``` 
SDL application can override SdlRouterService and set the notification listener. 
The implementation is up to the app, but pseudo-code looks like below:

```java
	private class MyNotificationDialogListener implements NotificationDialogListener {
		private Context mContext;
		myNotificationListener(Context context) {
			mContext = context;
		}
		@Override
		public void onRequestShowDialog(MessageType type) {
			if (type.equals(MessageType.ERROR_OUT_OF_SPP_RESOURCE)) {
				Intent intent = new Intent(ERROR_OUT_OF_SPP_RESOURCE);
				intent.setClassName(mContext.getPackageName(), getReceiverClassName())
				mContext.sendBroadcast(intent);
			}
		}
	}
	
	...
	@Override
    public void onCreate() {
	    ...
	    mMyNotificationListener = new MyNotificationDialogListener(getApplicationContext);
        setNotificationDialogListener(mMyNotificationListener);
    }
```
We can do whatever we would like to do in the broadcast receiver, which runs in app's main process.

And finally, we can detect and notify the error something like below in MultiplexBluetoothTransport class:
```java
    private class AcceptThread extends Thread {
	    ....
        public void run() {
            while (mState != STATE_CONNECTED) {
                try {
                    socket = mmServerSocket.accept();
                } catch(IOException e) {
                    Log.e(TAG, "Socket Type: " + mSocketType + "accept() failed");
                    MultiplexBluetoothTransport.this.stop(STATE_ERROR);
                    if (mSocketErrorListener != null) {
                        new Handler(Looper.getMainLooper()).post(mSocketErrorListener);
                    }
                    return;
                }
            }
        }
    }
```

### Reduce the number of BluetoothServerSockets that may not be required

In production code, MultiplexTransport is assumed, so SDL is assumed to use single BluetoothServerSocket. When SdlProxy fails to find the target RouterService, however, it falls back to legacy mode, which consumes another BluetoothServerSocket:
```java
    private synchronized void enterLegacyMode(final String info){
        if(legacyBluetoothTransport != null && legacyBluetoothHandler != null){
            return; //Already in legacy mode
        }

        if(transportListener.onLegacyModeEnabled(info)) {
            if(Looper.myLooper() == null){
                Looper.prepare();
            }
            legacyBluetoothHandler = new LegacyBluetoothHandler(this);
            legacyBluetoothTransport = new MultiplexBluetoothTransport(legacyBluetoothHandler);
            if(contextWeakReference.get() != null){
                contextWeakReference.get().registerReceiver(legacyDisconnectReceiver,new IntentFilter(BluetoothDevice.ACTION_ACL_DISCONNECTED) );
            }
        }else{
            new Handler().post(new Runnable() {
                @Override
                public void run() {
                    transportListener.onError(info + " - Legacy mode unacceptable; shutting down.");
                }
            });
        }
    }
```

This happens when it fails to find the RouterService that is connected with head unit.
If legacyMode is required for backward compatibility, the proposed solution is to add a flag to MultiplexTransportConfig, and enable legacy mode when it is requested by an app:
```java
public class MultiplexTransportConfig extends BaseTransportConfig{
    boolean legacyModeAllowed = false; // disallow LegacyMode by default.

    /**
     * Some apps never want to use legacy mode. This allows them to do so.
     * @param legacyModeAllowed
     */
    public void setLegacyModeAllowed(boolean legacyModeAllowed) {
        this.legacyModeAllowed = legacyModeAllowed;
    }

    /**
     * getLegacyModeAllowed (getter)
     * @return
     */
    public boolean getLegacyModeAllowed() {
        return this.legacyModeAllowed;
    }
}
```
```enterLegacyMode``` checks to see ```transportListener.onLegacyModeEnabled```, and we can check the flag in ```onLegacyModeEnabled``` something like below:
```java
in SdlProtocol:

        public boolean onLegacyModeEnabled(String info) {
            //Await a connection from the legacy transport
            if(transportConfig.getLegacyModeAllowed() && requestedPrimaryTransports!= null && requestedPrimaryTransports.contains(TransportType.BLUETOOTH)
                    && !transportConfig.requiresHighBandwidth()){
                Log.d(TAG, "Entering legacy mode; creating new protocol instance");
                reset();
                return true;
            }else{
                Log.d(TAG, "legacy mode is not allowed");
                return false;
            }
        }
```

## Potential downsides

It is not the downside, but the application should be responsible for implementing the notification listener when SPP resource runs out. The implementation guide should be updated accordingly.


## Impact on existing code

If an application relies on legacy mode in some case, the application needs to turn on legacyModeAllowed flag explicitly by calling ```MultiplexTransportConfig.setLegacyModeAllowed(true)```

## Alternatives considered

It's not certain how many production apps rely on legacy mode to work, but if we can mark legacy mode as the deprecated feature, ```enterLegacyMode``` function can be cleaned up without adding legacyModeAllowed flag in MultiplexTransportConfig.
