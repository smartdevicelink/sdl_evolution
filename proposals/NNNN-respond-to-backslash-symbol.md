# Respond INVALID_DATA to PutFile request with **backslash symbol**(`\`) at "syncFileName" parameter

* Proposal: [SDL-NNNN]
* Author: [Melnyk Tetiana](https://github.com/TMelnyk)
* Status: Awaiting review
* Impacted Platforms: Core
[SDL-NNNN]: https://github.com/smartdevicelink/sdl_evolution/new/master/proposals/NNNN-respond-to-backslash-symbol.md

## Introduction
**backslash symbol** (`\`) is control symbol in most of Linux and QNX based environments.
It may allow mobile application sending files with absolute path.
SDL must respond with INVALID_DATA on the PutFile request to app if file name is  **backslash symbol** (`\`).

## Motivation  
Currently Linux SDL has NO restrictions related to "\" (backslash) symbol at `<syncFileName>` parameter.
It is major security issue. Ignoring **backslash symbol** (`\`) in file names may allow mobile application rewrite random files on OEM platform and exploit vulnerability. 

## Proposed solution
SDL must respond with 'INVALID_DATA, success:false' resultCode in case `<syncFileName>` parameter of the *PutFile requests* to upload on the system contains **backslash symbol** (`\`).

The following use case possible:
``` 
app -> SDL: PutFile ("\123.jpg") // "syncFileName" with backslash
```

As result in this case SDL must return INVALID_DATA to mobile app.

## Detailed design

All logic can be implemented in scope of PutFile Request processing
```cpp
void PutFileRequest::Run() {
  ...
  const std::string& sync_file_name_ = (*message_)[strings::msg_params][strings::sync_file_name].asString();	
  if ContainsForbiddenSymbols(sync_file_name_) {
    SendResponse(false, mobile_apis::Result::INVALID_DATA,
                "syncFileName contains Forbidden symbols", &response_params);
    return;
  }
  ...
}

```

## Impact on existing code
Impact on PutFile request processing

## Alternatives considered
SDL may not check file name for any forbidden symbols
