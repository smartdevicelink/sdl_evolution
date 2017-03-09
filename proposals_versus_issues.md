The purpose of this document is to illustrate the differences between an SDL Evolution Proposal and an SDL Issue.  While determining how to present an item to the SDLC can be subjective, it’s our hope that providing examples of SDL Evolution Proposals and SDL Issues will help you to identify which format and GitHub Repository should be used for bringing your issue to the attention of the SDLC Steering Committee.

###SDL Evolution Proposals: [https://github.com/smartdevicelink/sdl_evolution](https://github.com/smartdevicelink/sdl_evolution)

####Qualifications:
- If there are multiple ways to approach an issue” to “If the behavior of the system has changed in a way that impacts what the app developer sees.
- If the issue/fix will have a large impact on the platform(s
- Any enhancements to the platform(s)

####Examples
| SDL Platform     | Proposal                                                 | URL                |
| ---------------- | -------------------------------------------------------- | ------------------ |
| RPC              | Update Mobile API to Include Mandatory Flag on Parameters| [SDL-0023](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0023-update-mobile-api-mandatory-flag.md)       |
| iOS              | Minimum iOS Version to 8.0                               | [SDL-0024](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0024-ios-8-0-minimum.md)       |
| Android          | Move to Android Studio                                   | [SDL-0026](https://github.com/smartdevicelink/sdl_evolution/issues/88)       |

When submitting an Evolution Proposal, please follow the guidelines and templates provided:
- [SDL Evolution README](https://github.com/smartdevicelink/sdl_evolution/blob/master/README.md)
- [SDL Evolution Proposal Template](https://github.com/smartdevicelink/sdl_evolution/blob/master/0000-template.md)
- [SDL Evolution Process](https://github.com/smartdevicelink/sdl_evolution/blob/master/process.md)

###SDL Issues Not Requiring a Proposal

####Qualifications:
- A clear discrepancy between expected and observed behavior(s)

####Examples
| SDL Platform     | Proposal                                                                     | URL                |
| ---------------- | ---------------------------------------------------------------------------- | ------------------ |
| Android          | NPEs in TransportBroker.sendMessageToRouterService() : routerServiceMessenger| [387](https://github.com/smartdevicelink/sdl_android/issues/387)   |
| iOS              | SDLManager’s stop does not stop the proxy.                                   | [509](https://github.com/smartdevicelink/sdl_ios/issues/509)       |
| Core             | Build fails if –DEXTENDED_MEDIA_MODE=ON                                      | [890](https://github.com/smartdevicelink/sdl_core/issues/890)      |

When entering an issue, please note any contribution guidelines and/or issue templates specified for the respectie repository:
- [iOS Issue Template](https://github.com/smartdevicelink/sdl_ios/blob/master/.github/ISSUE_TEMPLATE.md)
- [Core Contribution Guidelines](https://github.com/smartdevicelink/sdl_core/blob/master/CONTRIBUTING.md)
- [Android Contribution Guidelines](https://github.com/smartdevicelink/sdl_android/blob/develop/CONTRIBUTING.md)
