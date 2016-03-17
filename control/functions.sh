#### functions

function turnoff() {
[ -z "$2" ] && echo "turnoff: no input and logfile given" && return
if [ $(gpio -g read $1) -ne 1 ] ; then
  gpio -g write $1 1
  date +%s > $2
fi
}

function turnon() {
[ -z "$2" ] && echo "turnon: no input and logfile given" && return
if [ $(gpio -g read $1) -ne 0 ] ; then
  gpio -g write $1 0
  date +%s > $2
fi
}

