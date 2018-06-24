<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>terrarium 1 - images</title>
<script>
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
function display(count,a) {
  if (a==1) { c=count; } else { c=c+count; }
  if (c<0) { c=pictures.length-1; }
  if (c>=pictures.length) { c=0; }
  document.getElementById("im").src="./terracam/<?php echo $daytouse; ?>/"+pictures[c];
  document.getElementById("s").value=c;
  document.getElementById("p").innerHTML=(c+1)+"/<?php echo count($pictures); ?>";
}
</script>
<style type="text/css">
body,div { margin: 0; padding:0; }
.gc { display: grid; grid-template-columns: 10% auto 10%; }
div { text-align: center; margin: auto; }
img { max-width: 100%; max-height: 93vh; margin: auto; padding-top: 3vh;}
.gi1, .gi3 { background-color: grey; height: 100vh; overflow:hidden;}
a, a:hover, a:visited { color: black; text-decoration:none;}
input#s { width:100%;height:2vh;margin:0;padding:0;}
div#p { width:100%;height:1vh;text-align:center;}
</style>
</head>
<body>
<div class="gc">
<a href="javascript:display(-1,0)"><div class="gi1"><script>var i;for (i=0;i<2000;i++) { document.write("&lt; "); }</script></div></a>
<div class="gi2">
<div id="p"></div>
<img id="im" src="./terracam/<?php echo $daytouse . "/" . $pictures[0]; ?>">
<input type="range" id="s" min="0" max="<?php echo count($pictures) - 1; ?>" value="0">
</div>
<a href="javascript:display(1,0)"><div class="gi3"><script>var i;for (i=0;i<2000;i++) { document.write("&gt; "); }</script></div></a>
</div>
<script>
display(0,0);
document.getElementById("s").oninput = function(){display(Number(this.value),1);}
</script>
</body>
</html>
