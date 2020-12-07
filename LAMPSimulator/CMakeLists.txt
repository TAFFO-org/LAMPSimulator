set(SELF LAMPSimulator)

add_llvm_library(${SELF} MODULE
  LAMPSimulator.cpp
  LAMPSimulator.h

  LINK_LIBS
  m
  stdc++

  PLUGIN_TOOL
  opt
)

set_property(TARGET ${SELF} PROPERTY POSITION_INDEPENDENT_CODE ON)
