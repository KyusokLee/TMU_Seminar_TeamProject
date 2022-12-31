<?php
$IMAGE_DIR = "video/";

$PAGE_TITLE = "Raspberry Pi自動撮影システム";

$LIST_TEMP = "<li><a href=\"<!--URL-->\"><!--NAME--></li>";

$HTML_BASE =<<<EOT
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title><!--PAGE_TITLE--></title>
<head>
<body>
    <h1><!--PAGE_TITLE--></h1>
    <ul>
<!--LINK_LIST-->
    </ul>
</body>
</html>
EOT;

$dirhl = opendir($IMAGE_DIR);
while ( false !== ( $file_list[] = readdir($dirhl) ) );
closedir($dirhl);

rsort($file_list);

$list_buf = "";
foreach ( $file_list as $target) {
    if ( preg_match("/avi$/", $target ) ) {
        $date = preg_replace("/([0-9][0-9][0-9][0-9])([0-9][0-9])([0-9][0-9])([0-9][0-9])([0-9][0-9])([0-9][0-9])\.avi/","$1年$2月$3日 $4時$5分$6秒",$target);
        $buf = str_replace("<!--NAME-->",$date,$LIST_TEMP);
        $buf = str_replace("<!--URL-->",$IMAGE_DIR . $target ,$buf);
        $list_buf .= $buf;
    }
}

$output_html = str_replace( "<!--PAGE_TITLE-->", $PAGE_TITLE, $HTML_BASE);
$output_html = str_replace( "<!--LINK_LIST-->", $list_buf, $output_html );

print $output_html;



