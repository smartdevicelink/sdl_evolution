# Use Promises in Server Logic of SDL Policy Server

* Proposal: [SDL-NNNN](NNNN-filename.md)P
* Author: [Chris Rokita](https://github.com/crokita)
* Status: **Awaiting review**
* Impacted Platforms: Policy Server

## Introduction

This proposal aims to change the majority of the server application logic from using callback-based to Promise-based asynchronous function management. This is an effort to modernize the codebase after years of stagnant structural changes to make the project more readable and easier to update when new features are requested.

## Motivation

The last structural change to the policy server was written at a time where Promises were not as well understood, and so the established method of handling asynchronous tasks was using callbacks. Earlier attempts to mitigate the issues of readability with this method have not scaled so well with the number of features the project has accumulated. The codebase has grown to a point where any additions or changes to the application logic require a significant amount of reading and care to ensure that no new bugs are introduced and that all cases are considered.

With the introduction of await/async syntax, asynchronous logic can be read from top to bottom without excessive nesting of functions or visually jumping around the method to keep track of the execution order. This Promise style syntax will require fewer lines and will automatically throw functions into the event loop instead of being ran synchronously.

## Proposed solution

All callback-based asynchronous management that resides in the `app/v1` directory will be changed to use Promises and async/await syntax. If using a function from a library that uses callback-based, error-first style and is outside the project's control, it will be converted into a Promise through the use of NodeJS's `util.promisify` helper method. All references to the project's flame, flow, and async libraries to help with asynchronous function chaining will be replaced entirely with Promises and async/await syntax. Express middleware functions will necessarily remain using the `next` callback style, but if possible this will be avoided elsewhere.

All controller, helper, and model files are suspectible to these changes. The sql files will be untouched as they merely construct SQL statements. The modules inside the `custom` folder such as the cache and database modules should have their methods change to return Promises. Due to the expectancy of developers to change the contents inside the `customizable` folder with their own code, no changes will be required for those exported functions. The only requirement to use this new feature should be to upgrade the NodeJS version. The server can convert these exported functions that use callbacks into ones that return Promises anyway.

The front-end's use of callbacks are much more controlled: the rare use of asynchronous function chaining means the code is still readable. Changing some of the common functions used such as the Vue mixin `httpRequest` would not have significant benefits because of the necessary two-value return of an error and a result. Catching errors in a promise still require a callback to be passed in, which leads to the same problem as callback-based methods if you are not chaining multiple asynchronous functions together. For these reasons, the front-end will not be changed for this proposal.

## Examples
The two examples below show what those functions could become. They are not finalized changes.

The difference between using the npm async library and using the Promise + async/await syntax can be quite large. Take this snippet of this vehicle data helper function, for example: https://github.com/smartdevicelink/sdl_server/blob/master/app/v1/vehicle-data/helper.js#L132-L165

The equivalent could be written like this after the implementation of this proposal:

```js
// errors can be caught by the parent function that invokes this
async function insertCustomVehicleDataItem (client, data) {
    const res = await client.getOne(sql.insertCustomVehicleData(data, false));
    //insert new children
    let promises = [];
    if (data.params) {
        for (let child of data.params) {
            child.status = 'STAGING';
            child.parent_id = res.id;
            promises.push(insertCustomVehicleDataItem(client, child));
        }
    }
    return Promise.all(promises);
}
```

Even in the cases where excessive nested callbacks are abstracted out as efficiently as possible, there is still an issue of readability which can make it challenging to reason with or modify the function. This is one of the more extreme examples where a mix of parallel and serial computations are required: https://github.com/smartdevicelink/sdl_server/blob/master/app/v1/policy/helper.js#L163-L209

Rewriting this to use Promises isn't as drastic a difference but it is still much easier to read:

```js
// asyncSql is a theoretical function that will execute a SQL statement and resolve a Promise on completion. This is subject to change during implementation.
function mapAppBaseInfo (isProduction, useLongUuids = false, requestedUuids, incomingAppObjs, appObjs) {
    const appObjPromises = appObjs.map(async appObj => {
        const promiseObjects = { // start all promises in parallel
            categories: asyncSql(sqlApps.getAppCategoriesNames(appObj.id)),
            displayNames: asyncSql(sql.getAppDisplayNames(appObj.id)),
            moduleNames: asyncSql(sql.getAppModules(appObj.id)),
            funcGroupNames: asyncSql(sql.getAppFunctionalGroups(isProduction, appObj)),
            serviceTypes: asyncSql(sqlApps.getApp.serviceTypes.idFilter(appObj.id)),
            serviceTypeNames: asyncSql(sqlApps.getApp.serviceTypeNames.idFilter(appObj.id)),
            serviceTypePermissions: asyncSql(sqlApps.getApp.serviceTypePermissions.idFilter(appObj.id)),
            hybridPreference: asyncSql(sqlApps.getApp.hybridPreference.idFilter(appObj.id)),
            appPassthrough: asyncSql(sqlApps.getApp.passthrough.idFilter(appObj.id)),
            incomingAppPolicy: Promise.resolve(incomingAppObjs[(useLongUuids ? appObj.app_uuid : appObj.app_short_uuid)])
        };

        for (let prop in promiseObjects) {
            promiseObjects[prop] = await promiseObjects[prop]; // resolve all promises into each property
        }

        const allDataPromises = { // start all promises in parallel
            policyObjs: model.constructAppPolicy(appObj, useLongUuids, promiseObjects),
            requestedUuids: Promise.resolve(requestedUuids),
            useLongUuids: Promise.resolve(useLongUuids),
            defaultFuncGroups: asyncSql(sql.getDefaultFunctionalGroups(isProduction)),
            preDataConsentFuncGroups: asyncSql(sql.getPreDataConsentFunctionalGroups(isProduction)),
            deviceFuncGroups: asyncSql(sql.getDeviceFunctionalGroups(isProduction)),
        };
        if (requestedUuids.length > 0) {
            allDataPromises.blacklistedApps = asyncSql(sqlApps.getBlacklistedApps(requestedUuids, useLongUuids));
        } else {
            allDataPromises.blacklistedApps = Promise.resolve([]);
        }

        for (let prop in allDataPromises) {
            allDataPromises[prop] = await allDataPromises[prop]; // resolve all promises into each property
        }

        return model.aggregateResults(allDataPromises);
    });

    return Promise.all(appObjPromises);
}


```

## Potential downsides

Although this is a single conceptual change in the idea of how asynchronous logic should be handled, it will involve a significant editing of the majority of the project's server files due to how ubiquitous the callback-style is. As a result, the project's code may look very different from its current state. All other PRs that edit the server code will be incompatible with the changes made in this PR. Therefore, it is recommended that either no other PR editing the server files is started in conjunction with this one, or a PR can be started but later must get refactored by its author to implement the same changes requested in this proposal.

## Impact on existing code

The type of change that needs to be made for this proposal involves changing structures that are ubiquitous throughout the project. Although the server's user-facing functionality and API will not change, the breadth of the changes necessary to the code will be very large.

The use of the new syntax necessitates a higher NodeJS version to be installed in order to run the server. The major version requirement will go up from v4.0 to v8.0. Due to the raised minimum version requirement for NodeJS, this will be a major version change and the next release of the SDL Policy Server including this change will be v3.0.0.

## Alternatives considered

The author is not aware of any better methods of asynchronous logic handling that avoids the use of excessive callbacks.