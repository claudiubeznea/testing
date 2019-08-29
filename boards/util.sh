#!/bin/bash

# showBoards:		list the supported boards
# @args:		none
# return:		none
function showBoards() {
	for f in boards/config/*; do
		boardName=$(basename ${f});
		echo ${boardName}
	done
}
