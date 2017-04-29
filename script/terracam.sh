#!/bin/bash

timeout 20 curl -m 18 -o $dir_tmp/camtmp.jpg http://10.0.0.70:8080/photoaf.jpg
if [ $? -eq 0 ]; then
	ctz=$TZ
	TZ="Europe/Berlin"
	export TZ

	convert $dir_tmp/camtmp.jpg -fill white -gravity south -annotate +0+0 "Geckocam $(date +"%F %R %Z")" $dir_tmp/camtmptxt.jpg
	TZ=$ctz
	export TZ
	
	mkdir -p $dir_html/$(date +%F) 
	cp $dir_tmp/camtmptxt.jpg "$dir_html/$(date +%F)/geckocam01-$(date +%F_%R).jpg"
        rm $dir_html/latest.jpg
        ln -s "$dir_html/$(date +%F)/geckocam01-$(date +%F_%R).jpg" $dir_html/latest.jpg
	
fi


