#### functions

function getonv() {
  case $1 in 
    5|6|26)
      echo 1
      ;;
    *)
      echo 0
      ;;
  esac
}

function getoffv() {
  case $1 in 
    5|6|26)
      echo 0
      ;;
    *)
      echo 1
      ;;
  esac
}


function turnoff() {
[ -z "$2" ] && echo "turnoff: no input and logfile given" && return
if [ $(gpio -g read $1) -ne $(getoffv $1) ] ; then
  gpio -g write $1 $(getoffv $1)
  date +%s > $2
fi
}

function turnon() {
[ -z "$2" ] && echo "turnon: no input and logfile given" && return
if [ $(gpio -g read $1) -ne $(getonv $1) ] ; then
  gpio -g write $1 $(getonv $1)
  date +%s > $2
fi
}

