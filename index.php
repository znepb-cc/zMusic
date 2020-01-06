<?php

/* Credit to jakedacatman for this file */

$v = $_GET["v"];
$file = "/var/www/html/files/output.wav",
$webm = "/var/www/html/files/output.opus",
`./youtube-dl --no-cache-dir https://youtube.com/watch?v=$v -x --audio-format opus -o $webm`;

`ffmpeg -i $webm $file`;
$out = "/var/www/html/files/dfpwm";
`java -jar /var/www/html/lionray.lar "{$file}" "{$out}"`;

header("Content-Type: application/octet-stream");
header("Content-Disposition: attachment; filename={$out}");

$handle = fopen($out, "rb");
header("Content-Length: " . filesize($out));
echo fread($handle, filesize($out));
fclose($handle);

unlink($file);
unlink($webm);
unlink($out);

?>