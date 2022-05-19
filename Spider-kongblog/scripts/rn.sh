#!/bin/bash

for f in `ls`;
do
	echo $f
	name=$(echo $f | sed -e 's/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g')
	name=$(echo $name | sed -e 's/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g')
	echo $name
	mv $f $name
done

# s/\\/\\\\/g;