# Android Manifest Metadata
* Proposal: [SDL-NNNN](nnnn-android_metadata.md)
* Author: [Joey Grover](https://github.com/joeygrover/)
* Status: **Awaiting Review**
* Impacted Platforms: [Android]

## Introduction

The current Android library relies on a lot of internal methods and functions that try and prevent developers from making changes to their apps. However, as Android becomes more and more strict on what system level methods are available the SDL library will need to move to more conventional methods to accomplish certain goals. One of the ways to achieve this is requiring developers to add metadata fields to the `SdlBroadcastReceiver`. This will allow the library to query all SDL enabled apps and retrieve attributes about them without having to perform any inter-app communication. 


## Motivation

The SDL Android library tries to accomplish the most it can without having the developer perform many integration steps. While a lot of this functionality has worked when first developed, as the Android OS matures and becomes more strict in terms of operation, these methods can fail.

There is also a current limitation that request developers to ensure their `SdlRouterService` instance is in the same package as their `SdlBroadcastReceiver`. Some developers may not like this setup as they package their classes by type (Activity, Service, etc). 

Some OEMs also implement custom router services that don't adhere to the normal flow of the `SdlRouterService` however, due to the nature of how the library has worked it was required they are named the same as (`SdlRouterService`) and therefore impossible for the library to tell the difference between custom and traditional routers.


## Proposed solution

The proposed solution is to add metadata to the `SdlBroadcastReceiver` declaration. This will allow the library to query for these broadcast receivers through the Android OS using the `sdl.router.startservice` intent. With the metadata flag set we can retrieve the metadata tags attached to this receiver. 

All metadata name tags can be stored in the resources to prevent developer integration errors. 

With the first release we will make the additions optional, but in the next release we will add code that requires the developers to add the metadata.

##### Proposed additions

###### Router Service Version
Adding the router service version into the metadata fields we are able to remove the version checking process built into the router service class. This ensures that we do not rely on the Android OS to determine which router service gets started. Also, because of Android Oreo, a new race condition was added where it is not easily detectable if a router service has started up while each app receives the wake up intents from bluetooth connections. This can cause multiple router services to start. Instead, every app will query and sort the SDL enabled apps so that they will all attempt to start the same router service essentially providing router service version checking before the router service starts. 


###### Location of Router Service
This metadata entry can serve as an option for developers to place their `SdlRouterService` into a different package than the `SdlBroadcastReceiver`. This entry is optional, as if it is not included the location will be assumed as the same as the `SdlBroadcastReceiver`.

###### Location of Router Service
While it is not recommended to create custom integrations of router service, the SDLC recognizes that it is the only way to integrate into specific systems. A way in which to help prevent these custom integrations from having adverse affects on the traditional flow is including a metadata flag that signals if the included router service is custom or not. This flag is also optional as it will be assumed to be `false`.

#### res/values/sdl.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="router_service_version_name">sdl_router_version</string>
    <integer name="router_service_version_value">5</integer>
    <string name="router_service_location_name">sdl_router_location</string>
    <string name="router_service_is_custom_name">sdl_custom_router</string>
</resources>
```

#### Developer Manifest Additions

```xml
<meta-data android:name="@string/router_service_version_name" android:value="@integer/router_service_version_value" />
<meta-data android:name="sdl_router_location" android:value="com.livio.service.SdlRouterService" />
<meta-data android:name="@string/router_service_is_custom_name" android:value="false" />

```

#### SdlAppInfo
A new class will be introduced to contain the information about the SDL enabled apps. 

```java
public class SdlAppInfo {
    private static final String TAG = "SdlAppInfo";

    //Shouldn't be duplicating constants, but this currently keeps us from needing a context instance.
    private static final String SDL_ROUTER_VERSION_METADATA = "sdl_router_version";
    private static final String SDL_ROUTER_LOCATION_METADATA = "sdl_router_location";
    private static final String SDL_CUSTOM_ROUTER_METADATA = "sdl_custom_router";

    private static final String ROUTER_SERVICE_SUFFIX = ".SdlRouterService";

    String packageName;
    ComponentName receiverComponentName, routerServiceComponentName;
    int routerServiceVersion = 4; //We use this as a default and assume if the number doesn't exist in metadata it is because the app hasn't updated.
    boolean isCustomRouterService = false;
    long lastUpdateTime;


    public SdlAppInfo(ResolveInfo resolveInfo, PackageInfo packageInfo){
        if(resolveInfo.activityInfo != null){

            this.packageName = resolveInfo.activityInfo.packageName;

            receiverComponentName = new ComponentName(resolveInfo.activityInfo.packageName, resolveInfo.activityInfo.name);


            Bundle metadata = resolveInfo.activityInfo.metaData;

            if(metadata.containsKey(SDL_ROUTER_VERSION_METADATA)){
                this.routerServiceVersion = metadata.getInt(SDL_ROUTER_VERSION_METADATA);
            }

            if(metadata.containsKey(SDL_ROUTER_LOCATION_METADATA)){
                String rsName = metadata.getString(SDL_ROUTER_LOCATION_METADATA);
                if(rsName != null){
                    this.routerServiceComponentName = new ComponentName(rsName.substring(0, rsName.lastIndexOf(".")), rsName);
                } //else there's an issue
            }else{
                this.routerServiceComponentName = new ComponentName(this.packageName, this.packageName+ROUTER_SERVICE_SUFFIX);
            }

            if(metadata.containsKey(SDL_CUSTOM_ROUTER_METADATA)){
                this.isCustomRouterService = metadata.getBoolean(SDL_CUSTOM_ROUTER_METADATA);
            }
        }

        if(packageInfo != null){
            this.lastUpdateTime = packageInfo.lastUpdateTime;
            if(this.lastUpdateTime == 0){
                this.lastUpdateTime = packageInfo.firstInstallTime;
            }
        }
    }

    /**
     * This comparator will sort a list to find the best router service to start out of the known SDL enabled apps
     *
     */
    public static class BestRouterComparator implements Comparator<SdlAppInfo>{

        @Override
        public int compare(SdlAppInfo one, SdlAppInfo two) {
            if(one != null){
                if(two != null){
                    if(one.isCustomRouterService){
                        if(two.isCustomRouterService){
                            return 0;
                        }else{
                            return -1;
                        }
                    }else if(two.isCustomRouterService){
                        return -1;

                    }else {
                        //Do nothing. Move to version check
                    }

                    int versionCompare =  two.routerServiceVersion  - one.routerServiceVersion;

                    if(versionCompare == 0){ //Versions are equal so lets use the one that has been updated most recently
                        int updateTime =  (int)(two.lastUpdateTime - one.lastUpdateTime);
                        if(updateTime == 0){
                            //This is arbitrary, but we want to ensure all lists are sorted in the same order
                            return  one.routerServiceComponentName.getPackageName().compareTo(two.routerServiceComponentName.getPackageName());
                        }else{
                            return updateTime;
                        }
                    }else{
                        return versionCompare;
                    }

                }else{
                    return -1;
                }
            }else{
                if(two != null){
                    return 1;
                }
            }
            return 0;
        }
    }
}


```
#### New Method to AndroidTools

```java
public static List<SdlAppInfo> querySdlAppInfo(Context context, Comparator<SdlAppInfo> comparator){
    List<SdlAppInfo> sdlAppInfoList = new ArrayList<>();
    Intent intent = new Intent(TransportConstants.START_ROUTER_SERVICE_ACTION);
    List<ResolveInfo> resolveInfoList = context.getPackageManager().queryBroadcastReceivers(intent, PackageManager.GET_META_DATA);
    if(resolveInfoList != null && resolveInfoList.size() > 0) {
        PackageManager packageManager = context.getPackageManager();
        
        for (ResolveInfo info : resolveInfoList) {
            PackageInfo packageInfo = null;
            try {
                packageInfo = packageManager.getPackageInfo(info.activityInfo.packageName, 0);
            } catch (NameNotFoundException e) {
            }finally {
                sdlAppInfoList.add(new SdlAppInfo(info, packageInfo));
            }
        }
        if (comparator != null) {
            Collections.sort(sdlAppInfoList, comparator);
        }
    }
    return sdlAppInfoList;
}

```

#### SdlBroadcastReceiver changes

In the ServiceFinder callback block we change to simply call the query and sort method:

```java
Intent serviceIntent;
List<SdlAppInfo> sdlAppInfoList = AndroidTools.querySdlAppInfo(context, new SdlAppInfo.BestRouterComparator());
if (sdlAppInfoList != null && !sdlAppInfoList.isEmpty()) {
    serviceIntent = new Intent();
    serviceIntent.setComponent(sdlAppInfoList.get(0).getRouterServiceComponentName());

} else{
    Log.d(TAG, "No sdl apps found");
    return;
}
```


## Potential downsides
- App developers will have to add these entries into their manifests.
- SDLC will have to ensure current app partners add these fields.

## Impact on existing code
- The entire impact can be seen [here](https://github.com/smartdevicelink/sdl_android/compare/develop...feature/metdata). This code is near complete as well.
- The version checking code will be removed out of the `SdlRouterService`. The public methods will be deprecated.  



## Alternatives considered
- N/A
