# Template images 

* Proposal: [SDL-0062](0062-template-images.md)
* Author: [Kujtim Shala](https://github.com/kshala-ford)
* Status: **Accepted**
* Impacted Platforms: [Core / iOS / Android / RPC]

## Introduction

This proposal is to enable the HMI to customize icons used by apps and make them match the graphical design of the HMI.

## Motivation

Today many apps are using images as icons for buttons. Most of them are using PNG files with transparency and a black symbol. This may look great on SDL head units which are designed in light colors but looks terrible on dark colors. The following two pictures show how an app tries to overcome the issue by using dark grey icons.

![day-example][day-example]

![night-example][night-example]

Currently some apps try to workaround by using dark gray icons but those icons are recognized as disabled buttons. It's impossible for app developers to overcome this issue and they should not be in charge as it's not defined by SDL of how to color the graphical interface. Other/future head units may use a dark grey design which makes the workaround useless.

## Proposed solution

This proposal is to provide a new image type and allow app developers to declare an uploaded image as a `template` image. A template image would behave the exact same way as a dynamic image but would indicate that this image can be (re)colored by the HMI as needed by using an image pattern.

Template images would even allow the HMI to color the Icon when a button is selected/highlighted/touched-down although this proposal intended to improve the UI for different head units of different OEMs.

In a nutshell this proposal would allow flexible creation of icons whereby HMI decides the color and App decides the symbol.

### API change
The API change on the mobile and HMI is the following:

```xml
<struct name="Image">
 <param name="value" minlength="0" maxlength="65535" type="String"></param>
 <param name="imageType" type="ImageType"></param>
 <param name="isTemplate" type="Boolean" mandatory="false"></param> <!-- NEW PARAMETER -->
</struct>
```

### Mobile change
Apps still upload PNG files over PutFile and use them in e.g. a soft button. When an app developer want's to let the HMI decide the coloring it has to set `.isTemplate` to true. This is the single change for an app developer.

Example:

![icon][icon]

### SDL Core change
Whenever core receives an RPC from the app which incldues an image it just has to make sure the `.isTemplate` parameter makes its way to the HMI.

### HMI change
The HMI component has to hold a set of images called **image pattern**.

| image pattern name | image                       |
|--------------------|-----------------------------|
| day mode           | ![img][pattern-day]         |
| night mode         | ![img][pattern-night]       |
| highlight mode     | ![img][pattern-highlighted] |

Whenever HMI has to show an image which has `.isTemplate` set to true the HMI has to

1. load the proper image pattern
2. extract alpha channel from the template image
3. apply the alpha channel to the image pattern
4. use this newly generated image instead of the uploaded one

Example for all different modes:

| Step | Day mode            | Night mode            | Highlighted mode            |
|------|---------------------|-----------------------|-----------------------------|
| 1.   | ![img][pattern-day] | ![img][pattern-night] | ![img][pattern-highlighted] |
| 2.   | ![img][template]    | ![img][template]      | ![img][template]            |
| 3.   | ![img][icon-day]    | ![img][icon-night]    | ![img][icon-highlighted]    |
| 4.   | ![img][button-day]  | ![img][button-night]  | ![img][button-highlighted]  |

Whenever the UI changes, the HMI has to recreate images currently visible on the screen.

## Potential downside

N/A

## Impact on existing code

The impact on mobile side is minimal. App developer only has to set `.isTemplate` whenever appropriate. It's backwards compatible to head units which don't support this feature. Those head unit would just ignore this new parameter.

The impact on SDL core is minimal except the change of the HMI and mobile API. Unit tests may be requried but as this parameter is not used by core the effort should be trivial.

The HMI has to add all the logic of template images. The image manipulation is surprisingly easy these days on common UI frameworks.

## Alternatives considered

Instead of another parameter in `Image` it could be added as another image type. The API change on the mobile and HMI would be the following:

```xml
<enum name="ImageType">
 <description>Contains information about the type of image.</description>
 <element name="STATIC" />
 <element name="DYNAMIC" />
 <element name="TEMPLATE" /> <!-- NEW -->
</enum>
```

The big downside is that apps won't know when to use template rather than dynamic when it comes to backwards compatibility (e.g. SDL Core 4.1).

[day-example]: ../assets/proposals/0062-template-images/imagetype-example-day.png
[night-example]: ../assets/proposals/0062-template-images/imagetype-example-night.png
[icon]: ../assets/proposals/0062-template-images/imagetype-icon.png
[template]: ../assets/proposals/0062-template-images/imagetype-icon.png
[icon-day]: ../assets/proposals/0062-template-images/imagetype-icon-day.png
[icon-night]: ../assets/proposals/0062-template-images/imagetype-icon-night.png
[icon-highlighted]: ../assets/proposals/0062-template-images/imagetype-icon-highlighted.png
[pattern-day]: ../assets/proposals/0062-template-images/imagetype-pattern-day.png
[pattern-night]: ../assets/proposals/0062-template-images/imagetype-pattern-night.png
[pattern-highlighted]: ../assets/proposals/0062-template-images/imagetype-pattern-highlighted.png
[button-day]: ../assets/proposals/0062-template-images/button-day.png
[button-night]: ../assets/proposals/0062-template-images/button-night.png
[button-highlighted]: ../assets/proposals/0062-template-images/button-highlighted.png
