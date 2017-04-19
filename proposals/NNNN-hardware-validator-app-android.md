# Hardware Validator App (Android)

* Proposal: [SDL-NNNN](NNNN-hardware-validator-app-android.md)
* Author: [Jacob Keeler](https://github.com/jacobkeeler)
* Status: **Awaiting review**
* Impacted Platforms: [Android]

## Introduction

This proposal is for the addition of a new "Hardware Validator" Android Application to be managed as part of the SDL project. This application would allow OEMs integrating SDL to verify that all SDL functionality works correctly on their system using a realistic environment.

## Motivation

As it stands, the only real way of validating an OEM's SDL integration fully is to manually check all cases and verify that the HMI behaves correctly in each. Unfortunately, there will always be some level of manual work necessary when validating SDL integrations, as there are some aspects which are entirely visual on the HMI side. 

The belief is that the need to perform these HMI validations will increase greatly as more OEMs adopt SDL. As no documented process exists yet for performing these validations, this could end up being a rather costly and ineffective effort if nothing is provided to OEMs to ease this process.

The goal of this proposal is to offer a solution which can automate the validation process as much as possible, as well as provide a way to guide a developer through the manual sections of the process.

## Proposed solution

The proposed solution is to provide an application with the following features:

* Semi-automated tests, prompting the user whenever manual input is necessary
* The ability to read in scripts containing event sequences describing individual tests, to allow for easily expandable test cases
    * Must be able to create test suites within these scripts composed of several of these test sequences
    * Sequences can include messages to be sent, expected messages from SDL Core, and user prompts
* Logging of all messages sent and received from the app, for simpler debugging
* File logging for all test results, to be presented as validation criteria for a new integration

## Detailed solution

### Script format
One of the simpler possible script formats that can be used for this application is JSON.

Sample Format:

```json
{
  "name": "Compliance Test Suite",
  "type": "type_suite",
  "tests": [
    {
      "name": "Media App (FULL)",
      "type": "type_sequence",
      "preconditions": {
        "isMediaApplication": "true",
        "hmiLevel": "LIMITED"
      },
      "sequence": [
        {
          "action": "action_user_prompt",
          "positive_button": "OK",
          "negative_button": "Cancel",
          "message": "Select \"SDL Tester\" from App List",
          "expectation": "result_positive"
        },
        {
          "action": "action_expect_message",
          "function_name": "OnHMIStatus",
          "message_type": "notification",
          "params": {
            "hmiLevel": "FULL",
            "audioStreamingState": "AUDIBLE",
            "systemContext": "MAIN"
          }
        }
      ]
    },
    {
      "type": "type_file",
      "file_name": "language_change.json"
    },
    {
      "name": "Show",
      "type": "type_sequence",
      "preconditions": {
        "hmiLevel": "FULL"
      },
      "sequence": [
        {
          "action": "action_send_message",
          "function_name": "Show",
          "message_type": "request",
          "params": {
            "mainField1": "Test"
          }
        },
        {
          "action": "action_expect_message",
          "function_name": "Show",
          "message_type": "response",
          "params": {
            "success":true,
            "resultCode":"SUCCESS"
          }
        },
        {
          "action": "action_user_prompt",
          "positive_button": "Yes",
          "negative_button": "No",
          "message": "Does the word \"Test\" appear in the main text field?",
          "expectation": "result_positive"
        }
      ]
    }
  ]
}
```

This file would create a test structure in the log file such as:

1. Compliance Test Suite - Failed
    * Media App (FULL) - Failed
        * In Step 3: "OnHMIStatus" expectation
            * Expected "hmiLevel" = "FULL", got "NONE"
            * Expected "audioStreamingState" = "AUDIBLE", got "NOT_AUDIBLE"
    * Language Change (ES-MX) - Passed
    * Show - Passed

These test suites consist of three potential elements:

  * `type_suite` - Represents a group of tests.
    * `name` - The name of the test suite, as will displayed in the test log.
    * `tests` - A list of test suite elements. It is possible to nest test suites using this parameter.
  * `type_sequence` - Represents an individual test, defined as a sequence of events.
    * `name` - The name of the test, as will displayed in the test log.
    * `sequence` - A list of sequence elements (defined in next section of format description) in the order they are to be perfomed/expected.
  * `type_file` - Represents an external script to be loaded as part of the current test suite. Used as a way of importing several prewritten tests and making them into a full test suite.
    * `file_name` - The file path of the script to be loaded.

Individual test sequences consist of three potential elements (defined by the `action` parameter):

  * `action_send_message` - Defines a message to be sent to SDL Core.
    * `function_name` - The name of the RPC to be sent.
    * `message_type` - The type of the message to be sent, can be `request`, `response`, or `notification`
    * `params` - Contains all parameters to be included in the sent message.
  * `action_expect_message` - Defines a message that is expected to be received from SDL Core.
    * `function_name` - The name of the RPC expected to be received.
    * `message_type` - The type of the message expected to be received, can be `request`, `response`, or `notification`
    * `params` - Contains all parameters expected to be present in the message.
    * `timeout` - The timeout for receiving this message, in milliseconds. defaults to `10000` 
  * `action_user_prompt` - Defines a prompt to be displayed to the user of the application.
    * `positive_button` - The text to be displayed on the positive result button within the prompt (OK, Yes, etc.).
    * `negative_button` - The text to be displayed on the negative result button within the prompt (Cancel, No, etc.). If this field is omitted, no negative button will be present in the prompt.
    * `message` - The text to be displayed in the main body of the user prompt, giving the user instructions or requesting information from them.
    * `expectation` - The result type which is considered a passing result for the prompt, can either be `result_positive` or `result_negative`. Defaults to `result_positive`.

## Potential downsides

One of the potential downsides of this proposal is that the project requires a full set of test scripts to be maintained in order to work properly, which will take some resources.

Fortunately, the message flows which SDL Core and the mobile libraries follow do not change particularly often, so they likely will not need to be changed very often once they are initially written.

## Impact on existing code

This proposal will have no impact on existing code.

## Alternatives considered

* XML format vs. JSON

When considering possible formats for the test scripts, it was decided that a simple-to-parse existing format would be most effective since it can be handled easily with existing libraries. The two obvious formats of this type were XML and JSON. All of the elements described in the test script format could just as easily be implemented in XML format, but since the entire SDL protocol uses the JSON format, it seems simpler for developers to utilize this same format rather than move to another when working with this project.
