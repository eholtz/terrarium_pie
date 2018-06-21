<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>terrarium 1</title>
<meta http-equiv="refresh" content="60">
<script type="text/javascript">
var pictures=[<?php
$dayfolders = scandir("./terracam/");
rsort($dayfolders);
$daytouse = $dayfolders[0];
foreach ($dayfolders as $day) {
    if (strlen($day) != 10) {continue;}
    if (isset($_GET["d"])) {
        if (strcmp($_GET["d"], $day) == 0) {
            $daytouse = $day;
            break;
        }
    }
}
$pictures_raw = scandir("./terracam/" . $daytouse);
foreach ($pictures_raw as $pic) {
    if (substr($pic, -3) == "jpg") {
        $pictures[] = $pic;
    }
}
sort($pictures);
echo '"' . implode('","', $pictures) . '"';
?>];
var c=0;
function display(count) {
  c=c+count;
  if (c<0) { c=pictures.length-1; }
  if (c>=pictures.length) { c=0; }
  document.getElementById("im").src="./terracam/<?php echo $daytouse; ?>/"+pictures[c];
}
</script>
<style type="text/css">
body,div { margin:0; padding:0; }
div { text-align:center; margin:auto; }
img { max-width:100%; max-height:98vh; margin:auto; padding-top:1vh;}
a, a:hover, a:visited { color:black; text-decoration:none;}
.gc { display:grid; grid-template-columns: 10% auto 10%; }
.gi1, .gi3 { background-color:grey; height:100vh; overflow:hidden;}
</style>
</head>
<body>
<div class="gc">
<a href="javascript:display(-1)"><div class="gi1"><script>var i;for (i=0;i<2000;i++) { document.write("&lt; "); }</script></div></a>
<div class="gi2"><img id="im" src="./image.jpg"></div>
<a href="javascript:display(1)"><div class="gi3"><script>var i;for (i=0;i<2000;i++) { document.write("&gt; "); }</script></div></a>
</div>
<script>
display(0);
</script>
</body>
</html>
