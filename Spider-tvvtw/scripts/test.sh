#!/bin/bash

if [[ -s sfds ]]; then
	echo "exist and not zero"
else
	echo "not exist or zero"
fi