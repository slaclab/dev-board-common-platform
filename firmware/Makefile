export PARALLEL_BUILD = 3
export BUILD_SCRIPT = $(PWD)/submodules/ruckus/system_build_all.mk
export SETUP_ENV    = $(PWD)/setup_env_slac.csh
export TARGET_DIRS  = $(PWD)/common/VivadoHls/AxiLiteExample/vivado_hls/ \
                      $(PWD)/common/VivadoHls/AxiStreamExample/vivado_hls/ \
                      $(PWD)/targets/PartialReconfigurationExample/StaticDesign/ \
                      $(PWD)/targets/PartialReconfigurationExample/LedRtlA/ \
                      $(PWD)/targets/PartialReconfigurationExample/LedRtlB/ \
                      $(PWD)/targets/XilinxAC701DevBoard/Ac701GigE/ \
                      $(PWD)/targets/XilinxAC701DevBoard/Ac701Pgp/ \
                      $(PWD)/targets/XilinxKC705DevBoard/Kc705GigE/ \
                      $(PWD)/targets/XilinxKC705DevBoard/Kc705Pgp/ \
                      $(PWD)/targets/XilinxKC705DevBoard/Kc705TenGigE/ \
                      $(PWD)/targets/XilinxKC705DevBoard/Kc705Xaui/ \
                      $(PWD)/targets/DigilentNetFpgaSumeDevBoard/NetFpgaSumeGigE/ \
                      $(PWD)/targets/DigilentNetFpgaSumeDevBoard/NetFpgaSumePgp/ \
                      $(PWD)/targets/DigilentNetFpgaSumeDevBoard/NetFpgaSumeTenGigE/ \
                      $(PWD)/targets/DigilentNetFpgaSumeDevBoard/NetFpgaSumeXaui/ \
                      $(PWD)/targets/XilinxKCU105DevBoard/Kcu105GigE/ \
                      $(PWD)/targets/XilinxKCU105DevBoard/Kcu105Pgp/ \
                      $(PWD)/targets/XilinxKCU105DevBoard/Kcu105TenGigE/ \
                      $(PWD)/targets/XilinxKCU105DevBoard/Kcu105Xaui/


# Use top level makefile
include $(BUILD_SCRIPT)
