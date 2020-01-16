Mobile Network Emulator
=======================

Realistic Emulation of Mobile Networks

## Prerequisites

This tool runs on Linux, and builds on top of the `tc-netem` tool.
It also uses the `ifb` kernel module to shape incoming traffic.

You need also Python3 with update versions of `pandas` and `scipy`.

The tool is able to emulate profiles available in the `profiles.csv` file.
Check it to have the complete list.

## Usage

You need to execute it as `root`.

Usage:
```
apply_shaping.sh -o operator -c country -t technology -q quality -i interface [-p period] [-r] [-d] [-h]
```

Parameters are:
* `operator`: the Mobile Network Operator to emulate.
* `country`: the country network to emulate.
* `technology`: whether to emulate 3G or 4G.
* `quality`: signal quality to emulate: bad, medium or good.
* `interface`: the name of the interface where to apply shaping.
* `period`: change network conditions periodically after `period` seconds.
* `-r`: stop doing traffic shaping.
* `-d`: dry run (only print all commands that would execute).
* `-h`: print help.

## Limitations

Due to the use of the `ifb` kernel module, you can impose shaping to one interface at a time.
