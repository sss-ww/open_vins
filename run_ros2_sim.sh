#!/usr/bin/env bash
# Run OpenVINS' built-in simulator with ROS 2 + rviz2 visualization (no dataset needed).
# Usage: ./run_ros2_sim.sh
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source /opt/ros/humble/setup.bash
source "${REPO_DIR}/install/setup.bash"

# The simulator config uses the relative path
#   sim_traj_path: "src/open_vins/ov_data/sim/..."
# so run from a directory where that relative path resolves.
mkdir -p /tmp/ovsim/src
ln -sfn "${REPO_DIR}" /tmp/ovsim/src/open_vins
cd /tmp/ovsim

rviz2 -d "${REPO_DIR}/ov_msckf/launch/display_ros2.rviz" > /tmp/ov_rviz.log 2>&1 &
RVIZ_PID=$!

# Give rviz2 time to create its window and discover topics.
sleep 3

echo ">>> running simulation (takes about 1 minute; Ctrl-C to stop)"
# NOTE: OpenVINS may print "Error in destruction of rcl publisher handle"
# and a segmentation fault while shutting down ROS 2. This happens *after*
# the trajectory is complete and does not affect the results.
ros2 run ov_msckf run_simulation --ros-args \
  -r __ns:=/ov_msckf \
  -p config_path:="${REPO_DIR}/config/rpng_sim/estimator_config.yaml" || true

echo ">>> simulation finished; close the rviz2 window to exit"
wait "${RVIZ_PID}" 2>/dev/null || true