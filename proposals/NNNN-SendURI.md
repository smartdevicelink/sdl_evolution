# SendURI

* Proposal: [SDL-NNNN]((NNNN-SendURI.md))
* Author: [Michael Crimando](https://github.com/MichaelCrimando) & [Derrick Portis](https://github.com/dportis)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / RPC ]

## Introduction

The SendURI feature is a new RPC that would allow SDL Apps on systems that contain built-in web browsers, mail services, SMS services and more to quickly and easily direct users to resource identifiers (URI).

## Motivation

In the future, vehicles may contain web browsers that a user could use (while stationary or in motion - depending on OEM), rear family entertainment systems that are SDL-enabled may start to exist, and SDL-enabled autonomous vehicles will become common. Getting this feature would enable an SDL conneciton to the built-in features for situations where it may be more comfortable to use in the vehicle displays. Examples include but are not limited to, emails, calls, SMS messages, video content, real estate listings, news articles, restuarant menus, charging station info, flight info, and shopping information. Sometimes a SDL app can emulate certain views using display layouts - but the system might not be able to show the desired amount of information.

## Proposed solution

The SendURI RPC would bring new functionality to SDL by giving app the ability to explore web addresses and more outside of SDL apps. This will lead to more versatile interactions with SDL.  

Some example user stories that this would solve:
"As a user, I want to be able to find more info on the world around me, so that I have more enjoyable road trips"
"As a User, I want real estate info displayed in the car, so that I can easily pull up photos and history on homes before I deal with any agents"
"As a user, I want to be able to view videos and media on the rear screens because it's much more comfortable to view on"
"As a user, I want to be able to bring up web addresses through Waze so I can see more about a location"
"As a User, I want to setup bookmark keywords within in an app so that I can pull up web addresses easily"

To figure what would be necessary for this feature, we looked at how Twitter and Facebook display URI previews to users, and have that formatting in mind for an actual system implementation.

**Facebook:**

![alt text](https://github.ford.com/mcriman1/sdl_evolution_fordinternal/blob/SendWebAd/assets/F049/FacebookArticleShare.JPG "Facebook Article Sharing")

**Twitter:**

![alt text](https://github.ford.com/mcriman1/sdl_evolution_fordinternal/blob/SendWebAd/assets/F049/TwitterArticleShare.JPG "Twitter Article Sharing")

There is a new parameter for SendURI in the Mobile and HMI APIs that allows the feature to exist.

```xml
  <function name="SendURI" functionID="SendURIID" messagetype="request">
    <param name="uri" type="String" maxlength="32779" mandatory="true">
      <description>
        The full length URI 
      </description>
    </param>
    <param name="title" type="String" maxlength="500" mandatory="false">
      <description>
        E.g. Video title, news article title, web page title, etc.
      </description>
    </param>
    <param name="description" type="String" maxlength="500" mandatory="false">
      <description>
        E.g. Video description, snippet from news article, etc.
      </description>
    </param>
    <param name="nickname" type="String" maxlength="100" mandatory="false">
      <description>
        Short name for URI, used instead of showing full URI
      </description>
    </param>
    <param name="icon" type="Image" mandatory="false">
      <description>
        Web page icon
      </description>
    </param>
    <param name="image" type="Image" mandatory="false">
      <description>
         E.g. Video thumbnail, news article photo, etc.
      </description>
    </param>

```
And the response:
```xml
  <function name="SendURI" functionID="SendURIID" messagetype="response" >
    <param name="success" type="Boolean" platform="documentation">
      <description> true, if successful; false, if failed </description>
    </param>

    <param name="resultCode" type="Result" platform="documentation">
      <description>See Result</description>
      <element name="SUCCESS"/>
      <element name="INVALID_DATA"/>
      <element name="OUT_OF_MEMORY"/>
      <element name="TOO_MANY_PENDING_REQUESTS"/>
      <element name="APPLICATION_NOT_REGISTERED"/>
      <element name="GENERIC_ERROR"/>
      <element name="REJECTED"/>
      <element name="ABORTED"/>
      <element name="IGNORED">
      *<element name="UNSUPPORTED_RESOURCE"/> //The description of this just mentions softbuttons but send location uses this - should we include?*
      <element name="DISALLOWED"/>
      <element name="USER_DISALLOWED">
      <element name="TIMED_OUT">
      <element name="UNSUPPORTED_REQUEST"/>

    </param>

    <param name="info" type="String" maxlength="1000" mandatory="false" platform="documentation">
      <description>Provides additional human readable info regarding the result.</description>
    </param>     
  </function>
```
And adding the element "WEB_BROWSER" to the SystemCapabilityType enum.
```xml
<enum name="SystemCapabilityType">
...
  <element name="WEB_BROWSER"/>
</enum> 

```

Adding a parameter "webBrowserCapability" to the SystemCapability struct.

```xml
<struct name="SystemCapability">
...
      <param name="webBrowserCapability" type="WebBrowserCapability" mandatory="false">
      
      </param>
  </struct>
```

Adding a struct "WebBrowserCapability" and the enum associated with it, "UriSchemes".

```xml
<struct name="WebBrowserCapability">
 <description>Extended capabilities for an onboard web browser</description>
    <param name="uriSchemes" type="String" mandatory="false" maxlength="500" minsize="0" maxsize="200" array="true">
      <description>
        A list of URI schemes available. The head unit will provided a list of URI schemes available. Examples: mailto, http, chome, bitcoin, spotify.
      </description >
    </param>
  </struct>

 
```

### Behavior When No Web Browser Available
If the system does not have the capability of navigating to a web address sent from an app, then when an app sends a request for navigating to a web address, the system shall reject the request and provide a response of UNSUPPORTED_RESOURCE.

### Allowed HMI States
- ALLOWED within the HMI levels: FULL, LIMITED, BACKGROUND
- DISALLOWED within the HMI level: NONE

## Potential downsides

* Malware - Have to worry about the security of the websites that users are being sent to. Potentially could just be handled by the integrated web browser
* Annoying popups - Apps may bring up website popups unsolicited. We should list in the developer guidelines to not do this and OEMs can do validation testing on apps.
* Internet speed, bad URLs - If the internet speed in the car is slow or if the user is brought to bad/slow web pages, then they may find the feature more annoying than anything.  The speed of the internet will have to be handled by the OEM, it will be up to the app to bring the user to optimized web pages, and OEMs will have to do some validation testing to verify.  
* May not be needed at the moment - Most cars at the moment don't have a built in web browser. However, in the future with autonmous vehicles, this will probably become much more common.

## Impact on existing code

RPC changes:

* New RPC for Mobile and Core

## Alternatives considered

* Users could just use phones/laptop in their car to access web pages, but it may not necessarily be as comfortable as viewing content on something like a rear entertainment display. Plus, apps could potentially use vehicle data to make a more integrated experience (for example: pulling up information about nearby landmarks)

