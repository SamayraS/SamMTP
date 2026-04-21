#!/bin/bash
#
# Central config for batch experiment orchestration.
#

# Number of runs per (mode, ratio) pair.
RUNS_PER_CONFIG=8

# Runtime per run in seconds.
RUN_DURATION_SECONDS=480

# Mutation intervals to cycle across runs.
MUTATION_INTERVALS=(1 5 10)

# Experiment modes.
CONFIG_MODES=(
  "baseline"
  "ip"
  "dns"
  "ip_port"
  "ip_dns"
  "ip_port_dns"
)

# Bot:benign client ratios.
# Format "<bots>:<clients>"
BOT_BENIGN_RATIOS=(
  "50:5"
  "50:50"
  "20:80"
)

# Final log storage.
ALL_CONFIG_LOGS_DIR="all_config_logs"
