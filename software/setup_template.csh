
# Python Package directories
setenv FEB_DIR    ${PWD}/../firmware/common
setenv SURF_DIR   ${PWD}/../firmware/submodules/surf
setenv ROGUE_DIR  ${PWD}/rogue

# Setup enivorment
# with SLAC AFS access
source /afs/slac.stanford.edu/g/reseng/python/3.5.2/settings.csh
source /afs/slac.stanford.edu/g/reseng/boost/1.62.0_p3/settings.csh

# with local installations
#source /path/to/python/3.5.2/settings.csh
#source /path/to/boost/1.62.0/settings.csh

# Setup python path
setenv PYTHONPATH ${PWD}/python:${SURF_DIR}/python:${FEB_DIR}/python:${ROGUE_DIR}/python

# Setup library path
setenv LD_LIBRARY_PATH ${ROGUE_DIR}/python::${LD_LIBRARY_PATH}

