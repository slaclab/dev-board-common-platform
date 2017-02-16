
# Python Package directories
export FEB_DIR=${PWD}/../firmware/common
export SURF_DIR=${PWD}/../firmware/submodules/surf
export ROGUE_DIR=${PWD}/rogue

# Setup environment
# with SLAC AFS access
source /afs/slac.stanford.edu/g/reseng/python/3.5.2/settings.sh
source /afs/slac.stanford.edu/g/reseng/boost/1.62.0_p3/settings.sh

# with local installations
#source /path/to/python/3.5.2/settings.sh
#source /path/to/boost/1.62.0/settings.sh

# Setup python path
export PYTHONPATH=${PWD}/python:${SURF_DIR}/python:${FEB_DIR}/python:${ROGUE_DIR}/python

# Setup library path
export LD_LIBRARY_PATH=${ROGUE_DIR}/python::${LD_LIBRARY_PATH}

