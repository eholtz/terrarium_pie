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

function hrt() {
  # human readable time
  [ -z "$1" ] || [ $1 -lt 1 ] && echo "0 Sekunden" && return 0
  sekunden=$1
  tage=$(($sekunden/86400))
  sekunden=$(($sekunden%86400))
  stunden=$(($sekunden/3600))
  sekunden=$(($sekunden%3600))
  minuten=$(($sekunden/60))
  sekunden=$(($sekunden%60))
  [ $tage -gt 0 ] && echo "$tage Tage "
  [ $(($stunden+$tage)) -gt 0 ] && echo "$stunden Stunden "
  [ $(($minuten+$stunden+$tage)) -gt 0 ] && echo "$minuten Minuten "
  echo "$sekunden Sekunden"
}
