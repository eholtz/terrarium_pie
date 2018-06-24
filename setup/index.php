<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>terrarium 1</title>
<meta http-equiv="refresh" content="60">
<style>
li { 
    float: left;
    list-style: none; 
    text-align: center; 
    border: 1px dashed grey; 
    width: 5em;
    margin-left: 1em;
    margin-bottom: 2em;
}
</style>
</head>
<body>
<h1>Aktuelles Bild</h1>
<?php
$dayfolders = scandir("./terracam/");
rsort($dayfolders);
$pictures = scandir("./terracam/" . $dayfolders[0]);
rsort($pictures);
echo '<a href="' . "./terracam/" . $dayfolders[0] . "/" . $pictures[0] . '"><img src="' . "./terracam/" . $dayfolders[0] . "/" . $pictures[0] . '" height="196" width="262"></a>';
?>
<h1>Regen</h1>
<pre><?php echo file_get_contents("include"); ?></pre>
<h1>Statistiken</h1>
<?php
$ppath = "./rrd/graphs/";
foreach (scandir($ppath) as $pic) {
    if (substr($pic, -4) == ".png") {
        $data = explode("_", $pic);
        $span = $data[1];
        $sort = $data[0];
        $spans[$sort] = $span;
        $pictures[$span][] = $pic;
    }
}
ksort($spans);
$divs = "";
foreach ($spans as $span) {
    sort($pictures[$span]);
    $divs .= "\n<div style=\"clear:both;display:none;\" id=\"$span\">";
    foreach ($pictures[$span] as $pic) {
        $divs .= "<img src=\"" . $ppath . "/" . $pic . "\">";
    }
    $divs .= "</div>";
}
?>
<ul>
<?php
foreach ($spans as $span) {
    echo "<li>$span</li>";
}
echo $divs;
?>
</ul>
<script>
function toggle(elementid) {
    var el=document.getElementById(elementid);
    if (el) {
    if (el.style.display == "none") {
        el.style.display = "block";
    } else {
        el.style.display = "none";
    }
}
}
var lis=document.getElementsByTagName("li");
for (var i=0;i<lis.length;i++) {
    lis[i].addEventListener("click",function() {
        toggle(this.innerHTML);
    });
}
</script>
<h1 style="clear:both;">Alte Bilder</h1>
<?php
foreach ($dayfolders as $day) {
    if (strlen($day) != 10) {continue;}
    echo '<a href="image.php?d=' . $day . '">' . $day . '</a> ';
}
?>
</body>
</html>
