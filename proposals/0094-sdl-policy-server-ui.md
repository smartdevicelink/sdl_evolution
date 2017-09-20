# SDL Policy Server Enhancements - UI Framework

* Proposal: [SDL-0094](0094-sdl-policy-server-ui.md)
* Author: [Christopher Rokita](https://github.com/crokita), and [Joey Grover](https://github.com/joeygrover)
* Status: **Accepted**
* Impacted Platforms: [Policy Server]

## Introduction

This proposal provides an analysis of possible front-end frameworks for the UI component of the SDL Policy Server, and suggests which one would make the most sense to use for this project.

## Motivation
The policy server needs to be easy to use and easy to modify, including the UI. A subset of the requirements, such as reading and changing the approval status of incoming application requests, will be much simpler if there is a UI abstracting away the low-level implementation. In addition, the UI should be easy enough to understand so that those who use the policy server can modify the look of the UI with little effort.

## Proposed solution

The proposed UI framework to use for the SDL Policy Server is [Vue.js](https://vuejs.org/). The following sections will explain the nature of web development, what that means for the policy server, what judgment criteria is used as a result, and why Vue.js is the recommended framework.

#### The web ecosystem
It is difficult to choose which libraries and frameworks to use for a web-based JavaScript project as the web ecosystem is a fast-paced, volatile environment. There is currently no standard front-end JavaScript framework, and there is always a risk that a chosen framework will face obsoletion in the near future. This also means that there cannot be assumptions that a selected framework is well-known or is the tool of choice by users of the policy server. Therefore, the following section suggests a set of judgment criteria to help aid the decision of what framework is the most suitable for the policy server. 

#### Judgment criteria
The judgment criteria for the policy server is based around the assumption that any user who decides to learn the UI component will be new to the selected framework and must learn it from scratch. The criteria for a front-end JavaScript framework is the following:

*  Easy to use for beginners
*  Allows rapid prototyping of web pages
*  Mechanics that are consistent and intuitive
*  Easy to read/understand code that uses the framework
*  Well-written documentation
*  Ability to be Extended
*  Allows code to be split into reusable components (component-based architecture)
*  Support for separation of code between the view and the model
*  Simple to debug
*  Strength of community to help ensure its long-term support

#### Why Vue.js?
Vue.js takes inspiration from Angular and React and introduces a more expressive and simplified system for handling common tasks such as data binding, code separation, and sharing data between parent and child components. More complicated tasks such as routing and state management is possible through external libraries, similar to how React has Redux. Vue.js is "incrementally adoptable" which means that writing small web pages only necessitate a simple amount of Vue.js code, yet is able to to handle increasing complexity in a web application; this makes it easy for beginners to start and allows rapid prototyping without a need for complete rewrite. Vue.js also has [excellent documentation](https://vuejs.org/v2/guide/).

Vue.js breaks up different pieces of functionality into different properties of a Vue instance keeping things properly scoped. This makes it easy to understand what each piece of an app is supposed to do (ex. computed properties, methods, watches, and data are all separated and solve different problems).

The framework has external libraries that allow solving more complicated tasks mentioned above, such as Vuex for state management. Vue.js also takes inspiration from React's component-based approach and allows for easy HTML reuse and swappable views. Since Vue.js uses directives to handle HTML logic (similar to Angular) this allows wider separation between the view and the model. In the event of Vue.js errors, the browser console is informative enough to state where the problem is. In addition, Vue.js has a significant number of subframeworks to choose from that help stylize the UI through themes, pre-made components and transition animations. It's a valid possibility for the policy server to include one of these style frameworks to make it easier to configure the look of the server UI.

Strong support is important for a web framework because support helps ensure the framework's longevity. Although Vue.js does not have backing from giant companies like Angular and React, it has strong community support and [funding](https://vuejs.org/support-vuejs/). If these frameworks were to be measured in popularity by the number of stars their GitHub repositories have, then [Vue.js is the second most popular framework out there](https://github.com/showcases/front-end-javascript-frameworks) (as of September 5th 2017). This is beneficial because the community is large enough to help out others and post solutions to common problems in web development with Vue.js. 

It is due to the reasoning above that Vue.js is chosen as the recommended front-end JavaScript framework for the policy server.

## Potential downsides

Similar to using other frameworks, locking into Vue.js means the DOM and logic will be built using framework-specific details. If there are future proposals that involve changing the front-end framework used, this will mean spending a significant amount of time "translating" the web application to another framework. In addition, Vue.js is a relatively new framework and is still undergoing changes, which will necessitate keeping up with new features and bug fixes to the framework. However, the situation is similar to other web frameworks, such as React and Angular.

## Impact on existing code

The UI component of the policy server will be entirely new. Therefore, changes to existing code will be minimal. New API routes are expected to be included which will allow the UI to communicate with the policy server's database. 

## Alternatives considered

The other big contenders are AngularJS, Angular (a complete rewrite of AngularJS) and React. I have decided to leave AngularJS as an option, because the community is still strong and it's still more popular than Angular. That said, I personally find AngularJS not easy to use because of the number of problems that crop up during my time using the framework. Some examples of issues I have include nuances with $scope, dependency injection, importing JavaScript libraries, using watches for data binding, and understanding when to use services, service factories and service providers. 

The main issue with Angular is the push to use TypeScript. While a developer can get around using TypeScript, all of the documentation uses TypeScript code. The options there are sticking with JavaScript and facing the consequences of translating TypeScript example code into JavaScript, or learning TypeScript on top of Angular for the policy server. For the sake of maintaining a small learning curve, these frameworks are not as recommended.

React is a strong, popular framework, but a couple of factors caused the decision against recommending it for the policy server. The biggest factor is that React is not a simple framework for new web developers. The policy server is considered to be a fairly small project, and React is more suited for large web applications. Furthermore, React encourages combining JS and HTML to get logic in the view by using a syntax extension called JSX. The difference is small, but I would prefer avoiding JSX to make it easier to see what the output of the view will be like.
