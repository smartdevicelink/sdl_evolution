# ATF Facade

* Proposal: [SDL-0121](0121-atf_facade_proposal.md)
* Author: [Oleksandr Deriabin](https://github.com/aderiabin)
* Status: **In Review**
* Impacted Platforms: [Core]

## Introduction

This proposal describes unified interface for ATF (Automated Test Framework) - ATF Facade.
ATF should provide unified and flexible interface for creation test scripts to perform checks of SDL functionality.

Main ATF Facade purposes:
 - Simplify access to ATF features for test scripts
 - Separate test scripts from ATF
 - Provide well-structured intuitive interface of ATF for test scripts
 - Unify way of using ATF for creating automated tests
 - Create single point of ATF features documentation
 - Provide ability to create more human-readable tests

## Motivation

Currently ATF has a lot of functionality for testing most of SDL features, but each automated test uses different ATF modules.
ATF does not have unified interface to provide its functionality for test scripts. Instead of this ATF has many separated modules with their own interfaces which are used in automated scripts for SDL testing purposes.

So current approach leads to creating test scripts which have multiple direct dependencies on different modules of ATF.
In other words automated test scripts are fully dependent on ATF implementation and each change in ATF can lead to a need to change test scripts.

In addition, the current approach requires a strong knowledge in ATF modules' purposes and interactions between them in order to create a good automated test scenario using ATF.
So creation of automated test scripts takes a lot of time and it can be a bit complicated for Mobile application developers in the beginning.

Creation of ATF Facade will allow:
 - to create test scripts which are independent of ATF implementation
 - to unify ATF use approach
 - to document ATF functionality
 - to improve test scripts readability and their structure on base of scenarios

## Proposed solution

Add new module Facade with next submodules in ATF:
 - Runner - Manage of run test scenario
 - SDL - Provide access to manage SDL
 - HMI - Provide ability to emulate HMI and manage its expectations
 - Mobile - Provide ability to emulate Mobile device and manage its expectations
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

#### HMI - Provide ability to emulate HMI and manage its expectations

 - Connect - Create emulated HMI and connect it to SDL
 - Disconnect - Disconnect HMI from SDL
 - Send - Send raw message from HMI
 - SendRequest - Send request message from HMI
 - SendNotification - Send Notification message from HMI
 - SendResponse - Send Response message from HMI
 - ExpectResponse - Create expectation for response from SDL
 - ExpectNotification - Create expectation for notification from SDL
 - ExpectRequest - Create expectation for request from SDL

#### Mobile - Provide ability to emulate Mobile device and manage its expectations

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

For backward compatibility with existing test scripts ATF will contain some amount of deprecated code.

## Impact on existing code

It is expected only impact on ATF code. Existing scripts will not be affected.

## Alternatives considered

Use current approach with separated interfaces for each of ATF modules.
