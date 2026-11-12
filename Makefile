PACKAGE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ROOT ?= $(abspath $(VOC_SOURCE))
MODEL ?= 2
BUILD ?= $(PACKAGE_DIR)/build/$(MODEL)
HALD_SOURCE := $(PACKAGE_DIR)/HaldClut.Mod
COMMAND_SOURCE := $(PACKAGE_DIR)/examples/HaldCmd.Mod
TEST_SOURCE := $(PACKAGE_DIR)/test/test.py

include $(PACKAGE_DIR)/build.mk
