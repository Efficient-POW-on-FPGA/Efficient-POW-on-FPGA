#!/bin/sh

tmpfile="tmp.txt"
donefile="done.txt"
logfile="log.txt"
errorfile="error.txt"

function pullChanges(){
	git checkout master
	git branch -r | grep -v '\->' | while read remote; do git branch --track "${remote#origin/}" "$remote"; done
	git fetch --all
	git pull --all
	git log --oneline --all | grep -e '#build' > "$tmpfile"
}

function telegram() {
	cd ../telegram-bot-bash; bash bashbot.sh broadcast "$1"; cd ../processor
}

function build() {
	env LC_ALL=en_US.utf8 /opt/Xilinx/Vivado/2018.2/bin/vivado -mode batch -source build.tcl > "$logfile"
	if grep -Fq "ERROR:" "$logfile"
        then
		error=`cat $logfile | grep -F "ERROR:"`
		telegram "$error"
                telegram "build $1 failed"
	else
		cp build/processor/processor.runs/impl_1/main.bit "bitstreams/main_${commit}.bit"
		cp "bitstreams/main_${commit}.bit" bitstreams/main_last.bit
	        telegram "build $1 success"
	fi
}

function execute(){
	while read -r line
	do
		commit=`echo $line | awk -F' ' '{print $1}'`
		if grep -Fxq "$commit" "$donefile"
		then
			continue
		fi

		telegram "building $commit"
		git checkout "$commit"

		build "$commit"

		echo "$commit" >> "$donefile"
		break
	done < "$tmpfile"

	rm "$tmpfile"
}

while true
do
	pullChanges
	execute
	echo "done one thing"
	sleep 10
done
