# Add SDL Core Daemon script

* Proposal: [SDL-0154](0154-add-sdl-core-daemon-script.md)
* Author: [Jacob Keeler](https://github.com/jacobkeeler)
* Status: **Accepted**
* Impacted Platforms: [Core]

## Introduction

This proposal is for the addition of a daemon script allowing simple control over the lifecycle of SDL Core. This script would allow users to easily start/restart/stop SDL Core in the background without needing to create their own scripts to manage this behavior, as is currently the case. 

## Motivation

Currently the start script (`start.sh`) for SDL Core is just a simple wrapper starting the `smartDeviceLinkCore` application in the current shell. Since SDL Core is a standalone application that requires no input from the user directly, it could easily be made into a background process instead, and this start script could be used instead to manage its lifecycle.

## Proposed solution

The proposed solution for this is the addition of a daemon script with the following commands:

- `core.sh start`
- `core.sh restart`
- `core.sh stop`

A potential version of this script was submitted as a Pull Request by mchalain - [here](https://github.com/smartdevicelink/sdl_core/pull/1669).

New `core.sh` (modified from mchalain's solution):

```bash
#!/bin/bash
cd $(dirname $0)
DIR=$(pwd)
PID_FILE=$DIR/sdl.pid

function core_start() {
	LD_LIBRARY_PATH=$DIR ${DIR}/smartDeviceLinkCore &
	PID=$!
	echo $PID > $PID_FILE
}

function core_stop() {
	kill $(cat $PID_FILE)
	rm $PID_FILE
}

if [ x$1 == xstop ]; then
	core_stop
elif [ x$1 == xrestart ]; then
	core_stop
	core_start
elif [ x$1 == xstart ]; then
	core_start
else
	echo "usage: core.sh [start/restart/stop]"
fi
```

New `core_external_proprietary.sh`:

```bash
#!/bin/bash
cd $(dirname $0)
DIR=$(pwd)
CORE_PID_FILE=/var/run/sdl.pid
PM_PID_FILE=/var/run/policy_manager.pid

function core_start() {
	echo "Starting SmartDeviceLinkCore"
	LD_LIBRARY_PATH=$DIR ${DIR}/smartDeviceLinkCore &
	CORE_PID=$!
	echo $CORE_PID > $CORE_PID_FILE
}

function core_stop() {
	echo "Stopping SmartDeviceLinkCore"
	kill $(cat $CORE_PID_FILE)
	rm $CORE_PID_FILE
}

function pm_start() {
	pip list | grep -F tornado > /dev/null
	if [ $? -eq 1 ]
		then
  			echo "Installing tornado python package"
			sudo pip install tornado
	fi
	echo "Starting Policy Manager"
	python ${DIR}/sample_policy_manager.py --pack_port 8088 --unpack_port 8089 --add_http_header --encryption &
	PM_PID=$!
	echo $PM_PID > $PM_PID_FILE
}

function pm_stop() {
	echo "Stopping Policy Manager"
	kill -INT $(cat $PM_PID_FILE)
	kill -9 $(cat $PM_PID_FILE)
	rm $PM_PID_FILE
}

if [ x$1 == xstop ]; then
	core_stop
	pm_stop
elif [ x$1 == xrestart ]; then
	core_stop
	pm_stop
	core_start
	pm_start
elif [ x$1 == xstart ]; then
	core_start
	pm_start
else
	echo "usage: core.sh [start/restart/stop]"
fi
```

## Potential downsides

- This script would need to be very reliable in order to be useful in any production case (if Core ever fails to shut down when prompted, it could cause issues). However, the alternative is to leave each OEM to implement their own version of this script, since such a mechanism is practically necessary in any production system.

## Impact on existing code

The only impacted sections of the current project would be the existing start scripts, `start.sh` and `start_external_proprietary.sh`. The exact changes needed are described in the `Proposed Solution` section.

## Alternatives considered

- Not adding this functionality and leaving SDL Core's startup process as is. This would mean anyone that wants this behavior would have to implement it themselves.
