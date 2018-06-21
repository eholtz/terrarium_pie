<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>terrarium 1</title>
<meta http-equiv="refresh" content="60">
</head>
<body>
<h1>aktuelles bild</h1>
<?php
$dayfolders = scandir("./terracam/");
rsort($dayfolders);
$pictures = scandir("./terracam/" . $dayfolders[0]);
rsort($pictures);
echo '<a href="' . "./terracam/" . $dayfolders[0] . "/" . $pictures[0] . '"><img src="' . "./terracam/" . $dayfolders[0] . "/" . $pictures[0] . '" height="196" width="262"></a>';
?>
<h1>alte bilder</h1>
<?php
foreach ($dayfolders as $day) {
    if (strlen($day) != 10) {continue;}
    echo '<a href="image.php?d=' . $day . '">' . $day . '</a> ';
}
?>
</body>
</html>
