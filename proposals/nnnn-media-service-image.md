# Add Image to Media Service

* Proposal: [SDL-NNNN](NNNN-media-service-image.md)
* Author: [Joel Fischer](https://github.com/joeljfischer)
* Status: **Awaiting review**
* Impacted Platforms: [Core / iOS / Android / Web / RPC]

## Introduction
This proposal adds an image for the currently playing media item to the media app service.

## Motivation
An image for the media service was originally proposed but unfortunately somehow got lost in the app services shuffle and didn't make it into the RPC spec v5.1.0. We should add in the currently playing item's image to the service.

## Proposed solution
Very simply, we add a new parameter to the `MediaServiceData` RPC struct:

```xml
<struct name="MediaServiceData" since="5.1">
    <!-- All existing parameters here -->

    <param name="mediaImage" type="Image" mandatory="false" since="X.X">
        <description>
            Music: The album art of the current track
            Podcast: The podcast or chapter artwork of the current podcast episode
            Audiobook: The book or chapter artwork of the current audiobook
        </description>
    </param>
</struct>
```

## Potential downsides
No downsides were identified

## Impact on existing code
This is a minor version change to the RPC spec, Core, and proxy libraries.

## Alternatives considered
No alternatives were identified.