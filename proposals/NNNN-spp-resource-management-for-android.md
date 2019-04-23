# SPP resource management for Android

* Proposal: [SDL-NNNN](NNNN-spp-resource-management-for-android.md)
* Author: [Shinichi Watanabe](https://github.com/shiniwat)
* Status: **Awaiting review**
* Impacted Platforms: Android

## Introduction

RFCOMM is a connection-oriented, streaming transport over Bluetooth, which is known as Serial Port Profile (SPP) in Android. 
SDL Proxy uses BluetoothServerSocket for listening SPP channel, and it is used for primary transport. It is known that number of SPP resources is limited in Android device, and BluetoothServerSocket fails to accept connections when SPP channel runs out of available resource.
Current SDL Proxy does not handle that case very well. This proposal is to improve the SPP resource management in SDL Android.

## Motivation

This proposal addresses two issues regarding SPP resource management.

1. Detect the case where BluetoothServerSocket fails to accept a connection from head unit. Currently, we handle that case as the error case, but user has no way to know what happened.
2. Some BluetoothServerSocket are created, but will never be used. Such unused BluetoothServerSocket can be reduced.

## Proposed solution

We have to address two issues mentioned in the previous section.

### Detect the case where BluetoothServerSocket fails to accept a connection from head unit. 
Even though we could detect the case, we cannot increase the number of available SPP resources, because they are used by other apps.
All we can do in this case is to notify users that SPP channel runs out of available resources, and let users to close some apps that may use the BluetoothSocket. It's not practical to show SPP service records that are used by bluetooth adapter. It's suffice our needs to just notice users we're running out of resource.

Prior to detect the error, we can define the runnable interface as the listener in MultiplexBluetoothTransport class:
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
             * resource issue. The user needs to close other apps which uses BluetoothSocket.
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

### Reduce the number of BluetoothServerSocket that may not be required

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

This happens in production code if ir fails to find the connected RouterService.
If legacyMode is required for backward compatibility, the proposed solution is to add a flag to MultiplexTransportConfig, which indicates legacyMode is allowed or not:
```java
public class MultiplexTransportConfig extends BaseTransportConfig{
    boolean legacyModeAllowed = false; // disallow LegacyMode by default.

    /**
     * Some apps never want to use legacy mode. This allows to do so.
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

- An application that does not implement the notification listener still keeps working as well as current SdlProxy (no impact).
- If an application relies on legacy mode in some case, the application needs to explicitly turns on lagacyModeAllowed flag by ```MultiplexTransportConfig.setLegacyModeAllowed(true)```

## Alternatives considered

It's not certain how many production apps rely on legacy mode to work, but if we can mark legacy mode as the deprecated feature, ```enterLegacyMode``` function can be cleaned up without adding legacyModeAllowed flag in MultiplexTransportConfig.