#!/usr/bin/env bash

shellcheck --shell=bash --external-sources \
	bin/* \
	lib/* \
	scripts/*

shfmt --language-dialect bash --diff \
	./**/*
