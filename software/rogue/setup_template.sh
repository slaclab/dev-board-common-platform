
# Source rogue environment. Use your local rogue path if not on slac afs.
source /afs/slac.stanford.edu/g/reseng/rogue/v1.2.0/setup_env.sh

# Python Package directories
export FEB_DIR=${PWD}/../firmware/common
export SURF_DIR=${PWD}/../firmware/submodules/surf

# Setup python path
export PYTHONPATH=${SURF_DIR}/python:${FEB_DIR}/python:${PYTHONPATH}

