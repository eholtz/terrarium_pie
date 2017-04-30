#!/bin/bash

function step1 {
  # clean up
  [ -f _liste ] && rm _liste
  [ -f _liste2 ] && rm _liste2

  # first create a list of all images
  find ./ -mindepth 1 -maxdepth 1 -iname "*.jpg" | sort > _liste

  # now determine if we should process the image
  # dark images (aka night) won't be processes
  for i in $(cat _liste); do 
    convert "$i" -resize 1x1 "$dir_tmp/tmp.bmp"
    convert $dir_tmp/tmp.bmp $dir_tmp/tmp.txt
    sum=$(($(grep -o "\([0-9\,]*\)" tmp.txt | tail -n 1 | sed "s/\,/+/g")))
    if [ $sum -gt 30 ] ; then
      echo "$i" >> _liste2
    fi
  done

}

function step2 {
  # clean up
  [ -f _liste3 ] && rm _liste3
  mkdir -p $dir_tmp/
  last=""

  # now determine if the picture is somewhat "interesting"
  # these filters are based on experience and try/error
  # they produce fairly good results
  # basically i compare two images, if the difference is great
  # enough the picture seems to be interesting
  while read pic ; do
    [ -z "$last" ] && last=$pic && continue
    convert "$last" "$pic" -compose difference -composite -colorspace Gray "$dir_tmp/$pic.diff.jpg"
    convert "$dir_tmp/$pic.diff.jpg" -resize 10% "$dir_tmp/$pic.diffs.jpg"
    convert "$dir_tmp/$pic.diffs.jpg" -morphology Convolve Gaussian:0x4 "$dir_tmp/$pic.diffg.jpg"
    convert "$dir_tmp/$pic.diffg.jpg" -threshold 33% "$dir_tmp/$pic.difft.png"
    convert "$dir_tmp/$pic.difft.png" -resize 1x1 "$dir_tmp/$pic.diff1.bmp"
    convert "$dir_tmp/$pic.diff1.bmp" "$dir_tmp/$pic.diff1.txt"
    grep -q black "$dir_tmp/$pic.diff1.txt" || echo "$pic" >> _liste3
    rm -f $dir_tmp/$pic.*
    last=$pic
  done < _liste2
}

function step3 {
  # now remove everything that's not "interesting" and keep the cool photos
  mkdir keep
  while read pic ; do
    cp "$pic" "keep/$pic"
  done < _liste3
  find ./ -mindepth 1 -maxdepth 1 -iname "*.jpg" -delete
  mv keep/* ./
  rm -rf keep
}

function step4 {
  # finally create a html file
  echo "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"><title>$(hostname) - pictures - $(date %F)</title>" > index.html
  #  echo "<img id=\"p\" src=\"latest.jpg\">" >> index.html
  #  echo "<script>var i = document.getElementById('p');if(i && i.style) { i.style.height = (window.innerHeight-20) + 'px'; }</script>" >> $dir_html/pic.html
  echo "<script src=\"../dist/photoswipe.min.js\"></script><script src=\"../dist/photoswipe-ui-default.min.js\"></script>" >> index.html
  echo "<link href=\"../dist/default-skin/default-skin.css\" rel=\"stylesheet\" /><link href=\"../dist/photoswipe.css\" rel=\"stylesheet\" />" >> index.html
  echo "</head><body>" >> index.html
  cat >> index.html << EOF
<!-- Root element of PhotoSwipe. Must have class pswp. -->
<div class="pswp" tabindex="-1" role="dialog" aria-hidden="true">
<!-- Background of PhotoSwipe. 
It's a separate element as animating opacity is faster than rgba(). -->
<div class="pswp__bg"></div>
<!-- Slides wrapper with overflow:hidden. -->
<div class="pswp__scroll-wrap">
<!-- Container that holds slides. 
PhotoSwipe keeps only 3 of them in the DOM to save memory.
Don't modify these 3 pswp__item elements, data is added later on. -->
<div class="pswp__container">
<div class="pswp__item"></div>
<div class="pswp__item"></div>
<div class="pswp__item"></div>
</div>
<!-- Default (PhotoSwipeUI_Default) interface on top of sliding area. Can be changed. -->
<div class="pswp__ui pswp__ui--hidden">
<div class="pswp__top-bar">
<!--  Controls are self-explanatory. Order can be changed. -->
<div class="pswp__counter"></div>
<button class="pswp__button pswp__button--close" title="Close (Esc)"></button>
<button class="pswp__button pswp__button--share" title="Share"></button>
<button class="pswp__button pswp__button--fs" title="Toggle fullscreen"></button>
<button class="pswp__button pswp__button--zoom" title="Zoom in/out"></button>
<!-- Preloader demo http://codepen.io/dimsemenov/pen/yyBWoR -->
<!-- element will get class pswp__preloader--active when preloader is running -->
<div class="pswp__preloader">
<div class="pswp__preloader__icn">
<div class="pswp__preloader__cut">
<div class="pswp__preloader__donut"></div>
</div>
</div>
</div>
</div>
<div class="pswp__share-modal pswp__share-modal--hidden pswp__single-tap">
<div class="pswp__share-tooltip"></div> 
</div>
<button class="pswp__button pswp__button--arrow--left" title="Previous (arrow left)">
</button>
<button class="pswp__button pswp__button--arrow--right" title="Next (arrow right)">
</button>
<div class="pswp__caption">
<div class="pswp__caption__center"></div>
</div>
</div>
</div>
</div>
<script type="text/javascript">
var pswpElement = document.querySelectorAll('.pswp')[0];
var items = [ 
EOF
  while read pic ; do
    convert "$pic" -resize 128 "$pic.thumb.jpg"
    echo "{ src: '$pic', w: 2592, h: 1952, msrc:'$pic.thumb.jpg', title: '$pic' }," >> index.html
#    echo "<a href=\"$pic\"><img src=\"$pic.thumb.jpg\"></a>" >> index.html
  done < _liste3
  cat >> index.html << EOF
];
// define options (if needed)
var options = {
// optionName: 'option value'
// for example:
index: 0 // start at first slide
};
// Initializes and opens PhotoSwipe
var gallery = new PhotoSwipe( pswpElement, PhotoSwipeUI_Default, items, options);
gallery.init();
</script>
EOF
  echo "</body></html>" >> index.html
}

function step5 {
  # final cleanup
  rm _liste*
}

# now get all the definitions from config
source "$(readlink -f $(dirname $0)/../config/files.sh)"

runlog="$dir_log/htmllog.$(date +%Y%m%d.%H%M%S)"

echo "Starting up @ $(date +"%T %Z") ... " > $runlog
echo "logfile is $runlog " >> $runlog

if [ -n "$1" ] ; then
  $dir_today="$1"
else
  $dir_today=$dir_html/$(date +%F)
fi

echo "Running on folder $dir_today" >> $runlog
[ ! -d $dir_today ] && echo "Could not find $dir_today" && exit 1

cwd=$(pwd)
cd $dir_today

if [ ! -d $dir_html/dist/ ]; then
  echo "Initializing java script files..." >> $runlog
  cp -vr "$(readlink -f $(dirname $0)/../html/dist)" "$dir_html" >> $runlog
fi

echo "Step 1 @ $(date +"%T %Z") ... " >> $runlog
step1 &>> $runlog

echo "Step 2 @ $(date +"%T %Z") ... " >> $runlog
step2 &>> $runlog

echo "Step 3 @ $(date +"%T %Z") ... " >> $runlog
step3 &>> $runlog

echo "Step 4 @ $(date +"%T %Z") ... " >> $runlog
step4 &>> $runlog

echo "Step 5 @ $(date +"%T %Z") ... " >> $runlog
step5 &>> $runlog

cd $cwd

echo "Finishing @ $(date +"%T %Z") ... " >> $runlog

