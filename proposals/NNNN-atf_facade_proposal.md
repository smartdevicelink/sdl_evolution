# ATF Facade

* Proposal: [SDL-NNNN](NNNN-filename.md)
* Author: [Oleksandr Deriabin](https://github.com/aderiabin)
* Status: **Awaiting review**
* Impacted Platforms: [ATF]

## Introduction

This proposal describes unified interface for ATF (Automated Test Framework) - ATF Facade.
ATF should provide unified and flexible interface for creation test scripts to perform checks of SDL functionality.

Main ATF Facade purposes:
 - Simplify access to ATF features for test scripts
 - To separate test scripts from ATF
 - Provide well-structured intuitive interface of ATF for test scripts
 - Unify way of use ATF for creating automated tests
 - Create single point of ATF features documentation
 - To provide ability to create more human-readable tests

## Motivation

Currently ATF has a lot of functionality for testing most of SDL features, but each automated test uses different ATF modules.
ATF does not have unified interface for provide its functionality for test scripts. Instead that ATF has many separated modules with its own interfaces which is used for create automated scripts for SDL testing purposes.

So current approach leads to create test scripts which have multiple direct dependencies on different modules of ATF.
In other words automated test scripts are fully dependent from ATF implementation and each change in ATF can lead to need for change of test scripts.

In addition current approach demand a strong knowledge in ATF modules purposes and interactions between them for create good automated test scenario using ATF.
So creation of automated test scripts take a lot of time and it can be a bit complicated for Mobile application developers in the beginning.

Creation of ATF Facade will allow:
 - to create test scripts which are independent from ATF implementation
 - to unify ATF use approach for test script creation
 - to document ATF functionality create test script creation
 - to improve tests script readability and its structure on base of scenarious

## Proposed solution

Add new module Facade with next submodules in ATF:
 - Runner - Manage of run test scenario
 - SDL - Provide access to manage SDL
 - HMI - Provide access to emulate HMI actions and mange its expectations
 - Mobile - Provide access to emulate Mobile device and manage its expectations
 - Utilities - Provide access to utilities of ATF
 - Constants - Provide access to all constants used in ATF

### Submodules description

#### Runner - Manage of run test scenario

 - Step - Add step to test scenario
 - Title - Add titled section to test scenario
 - TestSettings - Set special test settings for run of current test

#### SDL - Provide access to manage SDL

 - StartSDL - Start SDL
 - StopSDL - Stop SDL
 - CheckStatusSDL - Check current status of SDL

#### HMI - Provide access to emulate HMI actions and mange its expectations

 - Connect - Create emulated HMI and connect it to SDL
 - Disconnect - Disconnect HMI from SDL
 - Send - Send raw message from HMI
 - SendRequest - Send request message from HMI
 - SendNotification - Send Notification message from HMI
 - SendResponse - Send Response message from HMI
 - ExpectResponse - Create expectation for response from SDL
 - ExpectNotification - Create expectation for notification from SDL
 - ExpectRequest - Create expectation for request from SDL

#### Mobile - Provide access to emulate Mobile device and manage its expectations

 - Connect - Create emulated Mobile device and connect it to SDL
 - Disconnect - Disconnect Mobile device from SDL
 - StartSession - Start mobile session on Mobile device
 - StartService - Start service on mobile session
 - StopService - Stop service on mobile session
 - Send - Send raw message from mobile session
 - SendRPC - Send RPC message from mobile session
 - ExpectResponse - Create expectation for response from SDL
 - ExpectNotification - Create expectation for notification from SDL

#### Utilities - Provide access to utilities of ATF

 - Report - Provide ATF reporting functionality
 - Event - Provide ATF event/expectation functionality
 - JSON - Provide JSON functionality
 - XML - Provide XML functionality

#### Constants - Provide access to all constants used in ATF

 - Protocol - Provide access to SDL protocol constants
 - Security - Provide access to Security constants
 - SDL - Provide access to SDL status constants
 - TestResult - Provide access to TestResult constants

### Test script improvement example

#### Current approach

```lua
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Connect_device()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_OnStatusUpdate_UPDATE_NEEDED_new_PTU_request()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appName = config.application1.registerAppInterfaceParams.appName } })
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, {status = "UPDATING"}):Times(2)

  EXPECT_NOTIFICATION("OnSystemRequest")
  :Do(function(_,data)
      if(data.payload.requestType == "HTTP") then
        if(data.binaryData == nil or data.binaryData == "") then
          self:FailTestCase("Binary data is empty")
        else
          print("Binary data is sent to mobile")
        end
      end
    end)
  :Times(2)

  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
```

#### Proposed approach

```lua
local ATF = require('facade')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local Mobile = ATF.Mobile
local HMI = ATF.HMI
local SDL = ATF.SDL
local Runner = ATF.Runner
local RPC = ATF.Constants.Protocol.RPC
local sessionId = 1

--[[ Preconditions ]]
local function preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
end

local function start()
  SDL:StartSDL()
  :Do(function()
    HMI:Connect()
    :Do(function()
      Mobile:Connect()
      :Do(function()
        allow_sdl(self)
      end)
    end)
  end)
end

local function startSession()
  Mobile:StartSession(sessionId)
  Mobile:StartService(sessionId, RPC)
end

--[[ Test ]]
local function testStep()
  local correlationId = Mobile:SendRPC(sessionId, "RegisterAppInterface", config.application1.registerAppInterfaceParams)

  HMI:ExpectNotification("BasicCommunication.OnAppRegistered", {application = { appName = config.application1.registerAppInterfaceParams.appName } })
  HMI:ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, {status = "UPDATING"}):Times(2)

  Mobile:ExpectNotification(sessionId, "OnSystemRequest")
  :Do(function(_,data)
      if(data.payload.requestType == "HTTP") then
        if(data.binaryData == nil or data.binaryData == "") then
          error("Binary data is empty")
        else
          print("Binary data is sent to mobile")
        end
      end
    end)
  :Times(2)

  Mobile:ExpectResponse(sessionId, correlationId, { success = true, resultCode = "SUCCESS" })
  Mobile:ExpectNotification(sessionId, "OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

--[[ Postconditions ]]
local function postcondition()
  SDL:StopSDL()
end

--[[ Scenario ]]
Runner.Title("Preconditions")
Runner.Step("Clean environment", preconditions)
Runner.Step("Start SDL, connect HMI, connect Mobile", start)
Runner.Step("Start Mobile session", startSession)
Runner.Title("Test")
Runner.Step("Check new PTU request on status update", testStep)
Runner.Title("Postconditions")
Runner.Step("Stop SDL", postcondition)
```

## Potential downsides

For backward compatibility for existing test scripts ATF will contain some amount of deprecated code.
That can be removed in case old scripts will be rewritten with approach proposed in current document.

## Impact on existing code

Is expected only impact on ATF code.

## Alternatives considered

Use current approach without unified ATF interface with separated interfaces for each of module of ATF.
