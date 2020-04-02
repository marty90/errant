ERRANT: EmulatoR of Radio Access NeTworks
=========================================

ERRANT is an advanced emulator of radio access networks, tuned thank to a large-scale measurement campaign on operational mobile networks.

It uses `tc-netem` to install traffic shaping policies, allowing the user to choose between 26 profiles that differ for emulated operator, RAT (3G or 4G) and signal quality. The exact paramenters of the shaping policies are dynamic, in the sense that they may vary at each run based on the values observed on the real network. ERRANT can also vary parameters dynamically (every `n` seconds) to emulate variable networks.

## Prerequisites

This tool runs on Linux, and builds on top of the `tc-netem` tool.
It also uses the `ifb` kernel module to shape incoming traffic.

You need also Python3 with updated versions of `pandas` and `scipy`.

ERRANT is able to emulate profiles available in the `profiles.csv` file, that describes their average values for latency, upload and download bandwidth. Check it to have the complete list.

## Usage

You need to execute it as `root`.

Usage:
```
errant -o operator -c country -t technology -q quality -i interface [-p period] [-r] [-d] [-h]
```

Parameters are:
* `operator`: the Mobile Network Operator to emulate.
* `country`: the country network to emulate.
* `technology`: whether to emulate 3G or 4G.
* `quality`: signal quality to emulate: bad, medium or good.
* `interface`: the name of the interface where to apply shaping.
* `period`: change network conditions periodically after `period` seconds.
* `-r`: stop doing traffic shaping. Remove all the shaping policies.
* `-d`: dry run (only print all commands that would execute).
* `-h`: print help.

## Examples

Run simulation with Norway Telenor 4G Good profile. Impose the proofile to eth0 interface:
```
errant -o Telenor -c Norway -t 4G -q Good -i eth0 
```

Run simulation with Norway Telenor 4G Good profile and periodically change network condition every 10s. Impose the proofile to eth0 interface:
```
errant -o Telenor -c Norway -t 4G -q Good -p 10 -i eth0 
```

Run simulation with Norway Telenor 4G Good profile and periodically change network condition every 10s, changing among three different profiles. Impose the proofile to eth0 interface:
```
errant -o Telenor -c Norway -t 4G -q Good -p 10 -pr [4G-BAD, 3G-GOOD, 3G-MEDIUM] -i eth0 
```


## Limitations

Due to the use of the `ifb` kernel module, you can impose shaping to one interface at a time.

## Creation of new profiles

If you want to create new profiles based on other measurements, you can use the scripts provided in the `profile_creation` directory, where we provide the code and instructions to generate a new profile file compatible with ERRANT.
