<?php
phpinfo();
$link = mysql_connect('mysql.polymicrosystems.com', 'tgunr', 'bat1d93k');
if (!$link) {
   die('Could not connect: ' . mysql_error());
}
echo 'Connected successfully';
mysql_close($link);
?> 