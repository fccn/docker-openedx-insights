# Open edX Insights docker builder

Builds a docker container with the Open edX Insights.

By default builds the upstream repository https://github.com/openedx/edx-analytics-dashboard.git
for the `master` branch, but it's possible to build other fork.

Tested for the **lilac** open edx release.

## Clean
Execute it like:
```bash
make clean
```

## Clone
Git clone the insights code to insights folder.
```bash
make repository=https://github.com/fccn/edx-analytics-dashboard.git branch=nau/lilac.master clone
```

## Build

Execute it like:
```bash
make build
```
