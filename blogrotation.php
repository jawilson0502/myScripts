<?php
	$conn = mysql_connect($servername, $username, $password)
		or die("Unable to connect to MySQL");

	$selected = mysql_select_db("website", $conn)
		or die("Could not select website database");

	$result = mysql_query("SELECT * FROM (SELECT * FROM blogPosts ORDER BY blog_id DESC LIMIT 5) sub ORDER BY blog_id DESC");
				
	while ($row = mysql_fetch_array($result)) {
		echo "\t<div class='post-preview'>\n";
		echo "\t\t<a href='";
		echo $row{'path'};
		echo "'>\n";
		echo "\t\t\t<h2 class='post-title'>";
		echo $row{'title'};
		echo "</h2>\n";
		echo "\t\t\t<h3 class='post-subtitle'>";
		echo $row{'subtitle'};
		echo "</h3>\n";
		echo "\t\t</a>\n";
		echo "\t\t<p class='post-meta'>Posted by <a href='aboutme.html'>Jessica Wilson</a> on ";
		echo $row{'create_date'};
		echo "</p>\n";
		echo "\t</div>";
		echo "\t<hr>";
	}

	mysql_close($conn);
?>
