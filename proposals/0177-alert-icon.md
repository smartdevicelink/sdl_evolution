# Alert icon

* Proposal: [SDL-0177](0177-alert-icon.md)
* Author: [BrandonHe](https://github.com/brandonhe)
* Status: **In Review**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal is about adding the RPC `alert` to include an icon.

## Motivation

Currently the RPC `alert` can add alertText, ttsChunks, progressIndicator and softButtons, but cannot add icon for this feature. Icon can help user clearly notice alert information, such as alert information from head unit or from a connected mobile navigation app, alert type is a traffic sign or a vehicle health.

## Proposed solution

The proposed solution is to add a parameter `alertIcon` to `alert`.

### HMI API additions

```xml
<enum name="ImageFieldName">
  <element name="alertIcon">
    <description>The image field for Alert</description>
  </element>
</enum>>
:
<function name="Alert" messagetype="request">
   :
   <param name="alertIcon" type="Common.Image" mandatory="false" >
    <description>Image to be displayed for the corresponding alert. See Image. </description>
    <description>If omitted, no (or the default if applicable) icon should be displayed.</description>
  </param>
</function>
```

### Mobile API additions

```xml
<enum name="ImageFieldName">
  :
  <element name="alertIcon">
    <description>The image field for Alert</description>>
  </element>
</enum>>
<function name="Alert" functionID="AlertID" messagetype="request">
   :
   <param name="alertIcon" type="Image" mandatory="false" >
     <description>
       Image struct determining whether static or dynamic icon.
       If omitted on supported displays, no (or the default if applicable) icon should be displayed.
     </description>
  </param>
</function>
```

### SDL Android
The Android library would need to add `setAlertIcon()` and `getAlertIcon()` method in `Alert.java`
```java
public class Alert extends RPCRequest {
  public static final String KEY_PLAY_TONE = "playTone";
  :
  public static final String KEY_SOFT_BUTTONS = "softButtons";
  public static final String KEY_ICON = "icon";   // <--- add

  :

  /**
   * <p>Sets the Image
   * If provided, defines the image to be shown along with an alert</p>
   * @param alertIcon
   *            <p>an Image obj representing the Image obj shown along with an
   *            alert</p>
   *            <p>
   *            <b>Notes: </b>If omitted on supported displays, no (or the
   *            default if applicable) icon will be displayed</p>
   */
  public void setAlertIcon(Image alertIcon) {
    setParameters(KEY_ICON, alertIcon);
  }

  /**
   * <p>Gets the image to be shown along with an alert </p>
   * 
   * @return Image -an Image object
   */
  public Image getAlertIcon() {
    return (Image) getObject(Image.class, KEY_ICON);
  }
}
```

### SDL iOS
The iOS library would need a new constant `SDLNameAlertIcon`, add new property `alertIcon`, and create corresponding `setAlertIcon` and `getAlertIcon` functions in `SDLAlert.m`

**SDLNames.h**
```objectivec
extern SDLName const SDLNameAlertIcon;
```
**SDLNames.m**
```objectivec
SDLName const SDLNameAlertIcon = @"alertIcon"
```
**SDLImageFieldName.m**
```objectivec
SDLImageFieldName const SDLImageFieldNameAlertIcon = @"alertIcon"
```
**SDLAlert.h**
```objectivec
/**
 * @abstract Image struct containing a static or dynamic icon
 *
 * @discussion If provided, defines the image to be be shown along with an alert
 * 
 * If omitted on supported displays, no (or the default if applicable) icon will be displayed
 *
 * Optional
 */
@property (nullable, strong, nonatomic) SDLImage *alertIcon;
```
**SDLAlert.m**
```objectivec
#import "SDLAlert.h"
#import "SDLImage.h"
#import "SDLName.h"

- (void)setAlertIcon:(nullable SDLImage*)alertIcon {
        [parameters setObject:alertIcon forName:SDLNameAlertIcon];
}

- (nullable SDLImage *)alertIcon {
    return [parameters sdl_objectForName:SDLNameAlertIcon ofClass:SDLImage.class];
}
```

## Potential downsides

The proposed change is backward compatible and will not cause a breaking change. However the API of `Alert` is inconsistent.

## Impact on existing code

The impact on existing code is very small. Existing apps are not affected as this proposal is adding an optional single parameter and changes on SDL core are minimal, it should be a minor version change.

## Alternatives considered

Optionally, we can use `graphic`, `appIcon`, `cmdIcon` and `menuIcon` to cover some alert usage scenarios instead of adding a new `alertIcon`, but that may confuse developers by which icon should be used. And it cannot support customized alerts, such as vehicle health alert, traffic sign alert and etc.
