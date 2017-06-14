
# Location of aes-stream-drivers include
AES_INCLUDE := ../../../aes-stream-drivers-v1.0.1/include/

# Variables
CC      := g++
DEF     :=
BIN     := $(PWD)/bin
OBJ     := $(PWD)/.obj
CFLAGS  := -Wall -I$(AES_INCLUDE)
LFLAGS  := 

# Generic Sources
LIB_DIR := $(PWD)/lib
LIB_SRC := $(wildcard $(LIB_DIR)/*.cpp)
LIB_HDR := $(wildcard $(LIB_DIR)/*.h)
LIB_OBJ := $(patsubst $(LIB_DIR)/%.cpp,$(OBJ)/%.o,$(LIB_SRC))

# Final Sources
SRC_DIR := $(PWD)/src
SRC_SRC := $(wildcard $(SRC_DIR)/*.cpp)
SRC_BIN := $(patsubst $(SRC_DIR)/%.cpp,$(BIN)/%,$(SRC_SRC))

# Default
all: dir $(LIB_OBJ) $(SRC_BIN)

# Object directory
dir:
	test -d $(OBJ) || mkdir $(OBJ)
	test -d $(BIN) || mkdir $(BIN)

# Clean
clean:
	rm -f $(BIN)/*
	rm -f $(OBJ)/*

# Compile Generic Sources
$(OBJ)/%.o: $(LIB_DIR)/%.cpp $(LIB_DIR)/%.h
	$(CC) -c $(CFLAGS) $(DEF) -o $@ $<

$(BIN)/%: $(SRC_DIR)/%.cpp $(LIB_OBJ) 
	$(CC) $(CFLAGS) $(DEF) $(OBJ)/* -o $@ $< $(LFLAGS) 

