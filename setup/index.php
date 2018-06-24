<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>terrarium 1</title>
<meta http-equiv="refresh" content="60">
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
        $pictures[] = $pic;
    }
}
foreach ($pictures as $pic) {
    echo "<img src=\"" . $ppath . "/" . $pic . "\">";
}
?>
<h1>Alte Bilder</h1>
<?php
foreach ($dayfolders as $day) {
    if (strlen($day) != 10) {continue;}
    echo '<a href="image.php?d=' . $day . '">' . $day . '</a> ';
}
?>
</body>
</html>
