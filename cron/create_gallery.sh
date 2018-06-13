#!/bin/bash

function step1() {
  # clean up
  [ -f _liste ] && rm _liste
  [ -f _liste2 ] && rm _liste2

  echo "deleting empty images"
  find ./ -empty -delete

  echo "creating a list of all images"
  # first create a list of all images
  find ./ -mindepth 1 -maxdepth 1 -iname "*.jpg" | sort >_liste

  echo "found $(wc -l _liste | awk '{print $1}') images"

  echo "find dark (night) images"
  # now determine if we should process the image
  # dark images (aka night) won't be processes
  for i in $(cat _liste); do
    convert "$i" -resize 1x1 "$dir_tmp/tmp.bmp"
    convert $dir_tmp/tmp.bmp $dir_tmp/tmp.txt
    sum=$(($(grep -o "\([0-9\,]*\)" $dir_tmp/tmp.txt | tail -n 1 | sed "s/\,/+/g")))
    if [ $sum -gt 30 ]; then
      echo "$i" >>_liste2
    else
      echo "picture $i is too dark"
    fi
  done

}

function step2() {
  # clean up
  [ -f _liste3 ] && rm _liste3
  mkdir -p $dir_tmp/
  last=""

  # now determine if the picture is somewhat "interesting"
  # these filters are based on experience and try/error
  # they produce fairly good results
  # basically i compare two images, if the difference is great
  # enough the picture seems to be interesting
  while read pic; do
    [ -z "$last" ] && last=$pic && continue
    echo "working on picture $pic"
    convert "$last" "$pic" -compose difference -composite -colorspace Gray "$dir_tmp/$pic.diff.jpg"
    convert "$dir_tmp/$pic.diff.jpg" -resize 10% "$dir_tmp/$pic.diffs.jpg"
    convert "$dir_tmp/$pic.diffs.jpg" -morphology Convolve Gaussian:0x4 "$dir_tmp/$pic.diffg.jpg"
    convert "$dir_tmp/$pic.diffg.jpg" -threshold 9% "$dir_tmp/$pic.difft.png"
    convert "$dir_tmp/$pic.difft.png" -resize 1x1 "$dir_tmp/$pic.diff1.bmp"
    convert "$dir_tmp/$pic.diff1.bmp" "$dir_tmp/$pic.diff1.txt"
    grep -q black "$dir_tmp/$pic.diff1.txt" || echo "$pic" >>_liste3
    grep -q black "$dir_tmp/$pic.diff1.txt" || echo "$pic is intresting enough"
    rm -f $dir_tmp/$pic.*
    last=$pic
  done <_liste2
}

function step3() {
  # now remove everything that's not "interesting" and keep the cool photos
  mkdir keep
  while read pic; do
    echo "keeping picture $pic"
    mv "$pic" "keep/$pic"
  done <_liste3
  echo "deleting boring pictures"
  find ./ -mindepth 1 -maxdepth 1 -iname "*.jpg" -delete
  mv keep/* ./
  rm -rf keep
}

function step4() {
  # finally create a html file
  echo "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"><title>$(hostname) - pictures - $current_date</title>" >index.html
  echo "</head><body>" >>index.html
  echo "<a href=\"../\">back</a><br />" >>index.html
  echo "var pswpElement = document.querySelectorAll('.pswp')[0];" >gallery.js
  echo "var items$clean_date = [ " >>gallery.js
  while read pic; do
    convert "$pic" -resize 128 "$pic.thumb.jpg"
    echo "{ src: '$current_date/$pic', w: 2592, h: 1952, msrc:'$current_date/$pic.thumb.jpg', title: '$pic' }," >>gallery.js
    echo "<a href=\"$pic\"><img src=\"$pic.thumb.jpg\"></a>" >>index.html
  done <_liste3
  echo "];" >>gallery.js
  echo "var options$clean_date = { index:0 };" >>gallery.js
  echo "var gallery$clean_date = new PhotoSwipe( pswpElement, PhotoSwipeUI_Default, items$clean_date, options$clean_date );" >>gallery.js
  echo "gallery$clean_date.init();" >>gallery.js
  echo "<script src=\"gallery.js\"></script>" >>index.html
  echo "</body></html>" >>index.html
}

function step5() {
  # final cleanup
  echo "removing temp lists"
  rm _liste*
}

today=$(date +%F)
dir_today="/mnt/nfs/terracam/$today"
dir_tmp="/dev/shm/terracamgallery/"

# clean up leftovers
mkdir -p $dir_tmp
rm -rf $dir_tmp
mkdir -p $dir_tmp

runlog="$dir_tmp/gallerylog.$(date +%Y%m%d.%H%M%S)"

echo "Starting up @ $(date +"%T %Z") ... " >$runlog
echo "logfile is $runlog " >>$runlog

# if we got a folder from the command line, use it
if [ -n "$1" ]; then
  dir_today="$1"
fi

# we will exit if we don't find the given directory
if [ ! -d $dir_today ]; then
  echo "could not find $dir_today" >>$runlog
  exit 1
fi

current_date=$(basename $dir_today)
clean_date=$(echo $current_date | sed "s/[^0-9]//g")

echo "Running on folder $dir_today" >>$runlog
[ ! -d $dir_today ] && echo "Could not find $dir_today" && exit 1

cwd=$(readlink -f $(dirname $0))
cd $dir_today

echo "Step 1 @ $(date +"%T %Z") ... " >>$runlog
step1 &>>$runlog

echo "Step 2 @ $(date +"%T %Z") ... " >>$runlog
step2 &>>$runlog

echo "Step 3 @ $(date +"%T %Z") ... " >>$runlog
step3 &>>$runlog

echo "Step 4 @ $(date +"%T %Z") ... " >>$runlog
#step4 &>> $runlog

echo "Step 5 @ $(date +"%T %Z") ... " >>$runlog
step5 &>>$runlog

cd $cwd

echo "Finishing @ $(date +"%T %Z") ... " >>$runlog
