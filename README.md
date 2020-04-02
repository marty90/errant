ERRANT: EmulatoR of Radio Access NeTworks
=========================================

ERRANT is an advanced emulator of radio access networks, tuned thank to a large-scale measurement campaign on operational mobile networks.

It uses `tc-netem` to install traffic shaping policies, allowing the user to choose between 32 profiles that differ for emulated operator, RAT (3g or 4g) and signal quality. The exact parameters of the shaping policies are dynamic, in the sense that they may vary at each run based on the values observed on the real network. 
The avaiable profiles are saved in the `model.pickle` file. ERRANT can also vary parameters dynamically (every `n` seconds) to emulate variable networks, and simulate moving scenario using the `ApplyScenario` scipt. 

## Prerequisites

This tool runs on Linux, and builds on top of the `tc-netem` tool.
It also uses the `ifb` kernel module to shape incoming traffic.

You need also Python3 with updated versions of `pandas` and `scipy`.

ERRANT is able to emulate profiles available in the `profiles.csv` file, that describes their average values for latency, upload and download bandwidth. Check it to have the complete list.

## Usage

You need to execute it as `root`.

Usage ERRANT for emluation without a scenario:
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

Note that to use the operator-agnostic models, you must specify `universal` for operator and country.

Usage ERRANT for emluation with a scenario:
```
ApplyScenario.py -s scenario.csv -i interface
```
Parameters are:
* `scenario.csv`: the name of the csv file containing the list of profiles to be emulated.
* `interface`: the name of the interface where to apply shaping.

The `scenario.csv` is a csv file where each row describe:
* `operator`: the Mobile Network Operator to emulate.
* `country`: the country network to emulate.
* `technology`: whether to emulate 3G or 4G.
* `quality`: signal quality to emulate: bad, medium or good.
* `period`: change network conditions periodically after `period` seconds.
* `expire`: move to the next network profile after `expire` seconds.

## Examples

Run simulation with Norway Telenor 4G Good profile. Impose the proofile to eth0 interface:
```
errant -o telenor -c norway -t 4g -q good -i eth0 
```

Run simulation with Norway Telenor 4G Good profile and periodically change network condition every 10s. Impose the proofile to eth0 interface:
```
errant -o telenor -c norway -t 4g -q good -p 10 -i eth0 
```

Usage ERRANT for emluation with a scenario:
```
ApplyScenario.py -s scenario.csv -i eth0
```

## Limitations

Due to the use of the `ifb` kernel module, you can impose shaping to one interface at a time.

## Creation of new models

If you want to create new models based on other measurements, you can use the scripts provided in the `model_creation` directory, where we provide the code and instructions to generate a new model file compatible with ERRANT.
