
# Source rogue environment. Use your local rogue path if not on slac afs.
#source /afs/slac.stanford.edu/g/reseng/rogue/master/setup_env.csh

# Python Package directories
setenv FEB_DIR    ${PWD}/../../firmware/common
setenv SURF_DIR   ${PWD}/../../firmware/submodules/surf

# Setup python path
setenv PYTHONPATH ${SURF_DIR}/python:${FEB_DIR}/python:${PYTHONPATH}

