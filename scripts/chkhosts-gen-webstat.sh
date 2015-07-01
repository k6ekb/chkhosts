#!/bin/bash
#
# Script to generate host status php web page and
# the comment update form page.
#
# usage: chkhosts-gen-webstat.sh  chkhosts_directory

OUR_CONFIG_FILE=chkhosts-gen-webstat.conf

# Announce ourselves.
echo "Chkhosts-gen-webstat.sh MY_VERSION_STRING"

# Check for required parameter and grab our working directory
if [[ "$#" -ne "1" ]]; then
        echo ""
        echo "ERROR:  Must specify chkhost's working directory."
        echo ""
        exit 1
else
        WORKDIR=$1
fi

# source OUR_CONFIG_FILENAME to set user-configurable variables
if [[ -e "$WORKDIR/conf/$OUR_CONFIG_FILE" ]]; then
	echo "Sourcing $WORKDIR/conf/$OUR_CONFIG_FILE..."
	source $WORKDIR/conf/$OUR_CONFIG_FILE
else
        echo ""
        echo "ERROR:  Cannot access $WORKDIR/conf/$OUR_CONFIG_FILE.  Aborting."
        echo ""
        exit 2
fi

# Now set our variables relative to the working directory
HOSTLISTFILE=$WORKDIR/conf/hostlist.txt
EMAIL_LIST=$WORKDIR/conf/notify-email.txt
SMS_LIST=$WORKDIR/conf/notify-sms.txt
UPHOSTSTATUSDIR=$WORKDIR/status-up
DOWNHOSTSTATUSDIR=$WORKDIR/status-down
CHKHOSTLOGDIR=$WORKDIR/log
CHKHOSTLOG=$CHKHOSTLOGDIR/chkhosts.log
WEBSTATDIR=$WORKDIR/webstat
WEBCOMMENTDIR=$WEBSTATDIR/system-comment
WEBSYSTEMINFODIR=$WEBSTATDIR/system-info
WEBSYSTEMCOLORDIR=$WEBSTATDIR/system-color
WEBSYSTEMLINE3DIR=$WEBSTATDIR/system-line3
WEBSYSTEMLINE4DIR=$WEBSTATDIR/system-line4
WEBSYSTEMLINE5DIR=$WEBSTATDIR/system-line5
WEBSYSTEMLINE6DIR=$WEBSTATDIR/system-line6
WEBSYSTEMLINE7DIR=$WEBSTATDIR/system-line7
WEBSYSTEMLINE8DIR=$WEBSTATDIR/system-line8
WEBPAGE=$WEBSTATDIR/status.php
COMMENTFORM=$WEBSTATDIR/update-comment.php
DESCFORM=$WEBSTATDIR/update-description.php

# Calculate the number of hosts we're monitoring
NUMSYSTEMS=$(grep -v -e '^#' $HOSTLISTFILE | wc -l)


#
# Create the Comment Form page first
####################################

echo "Generating $COMMENTFORM..."
echo '<!DOCTYPE html>' >$COMMENTFORM
echo '<html>'  >>$COMMENTFORM
echo '<head>'  >>$COMMENTFORM
echo '	<meta charset="UTF-8">' >>$COMMENTFORM
echo '	<meta name="generator" content="gen-webstat.sh MY_VERSION_STRING">' \
	>>$COMMENTFORM
echo '	<link rel="stylesheet" type="text/css" href="style.css">' >>$COMMENTFORM
echo "	<title>${_CHKHOSTS_COMMENTFORM_TITLE_}</title>"   >>$COMMENTFORM
echo '</head>' >>$COMMENTFORM
echo ' ' >>$COMMENTFORM

echo '<body>' >>$COMMENTFORM

# insert the php POST function and showstatus functions
cat >>$COMMENTFORM << "SUBMIT_FUNCTION_SECTION"
<?php
	session_start();
	if (isset($_SESSION['comment_session'])) {
		/* Don't do anything - already processed the submit... */
	}
	else {
        	if (isset($_POST['submit'])) {
               		$action_hostname = $_POST['CommentHostName'];
                	$action_comment = $_POST['CommentText'];
                	file_put_contents("system-comment/$action_hostname.txt",
				$action_comment);
                	$log_entry = strftime("%F %T: ") . 
				"$action_hostname, $action_comment\n";
                	file_put_contents("comment.log",$log_entry, 
				FILE_APPEND);
			header('Location: status.php');
			exit();
		}
        }
?>
SUBMIT_FUNCTION_SECTION

# insert the comment section 
cat >>$COMMENTFORM << "COMMENT_SECTION_1"
<h3>_CHKHOSTS_COMMENTFORM_TITLE_</h3>
<p>
This form allows you to update the <b>comment</b> line of 
the selected host. &nbsp;
</p>
<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="post">
<table align="center" style="border-spacing: 1px;border-style: solid;
              border-color: #000000;border-width: 3px 3px 3px 3px">
        <tr><td><b>Host:</b> &nbsp;
                <select name="CommentHostName">
                        <option selected value="unknown">&lt;select host&gt;
COMMENT_SECTION_1

# ensure system-comment directory and comment.log exist
mkdir -p $WEBCOMMENTDIR
touch $WEBSTATDIR/comment.log

# add the hosts to the drop-down list
for i in $( grep -v -e '^#' $HOSTLISTFILE ); do

	# create short host name...
        IPADDR="`echo $i | grep -e '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*'`"
        if [[ "$IPADDR" == "" ]]; then
                SHORTNAME="`echo $i | awk -F . '{ print $1}'`"
        else
                SHORTNAME="$IPADDR"
	fi

	# add to list in web page
	echo "		<option value=\"$SHORTNAME\">$SHORTNAME" \
		>>$COMMENTFORM

	# add initial comment to comment file for host
	if [[ ! -e "$WEBCOMMENTDIR/$SHORTNAME.txt" ]]; then
		echo "no comment" >$WEBCOMMENTDIR/$SHORTNAME.txt
	fi

done

# set permissions to ensure web server can write the files
chmod ugo+w $WEBCOMMENTDIR/* $WEBSTATDIR/comment.log

cat >>$COMMENTFORM << "COMMENT_SECTION_2"
                </select>
                </td></tr>
        <tr><td><b>Comment:</b> &nbsp;
                <input type="text" name="CommentText" size=40 maxlength=512 /></td></tr>
        <tr><td align="center"><input type="submit" name="submit" value="Update Comment"></td></tr>
</table>
</form>

<p>&nbsp;</p>
<div class="footer"> 
      <hr width="55%">
      <p align="center">This page generated by 
	<a href="https://github.com/k6ekb/chkhosts">
	gen-webstat.sh MY_VERSION_STRING</a><br>
	This page last edited on 
	<?php echo  strftime("%a, %d %b %Y at %H:%M %Z.", 
		filemtime("update-comment.php")); ?><br>
        You're logged in as '<?php print getenv("REMOTE_USER");?>' 
	from <?php print getenv("REMOTE_ADDR"); ?><br>
</div>
COMMENT_SECTION_2

#
# Close out COMMENTFORM document 
#############################

echo '</body>' >>$COMMENTFORM
echo '</html>' >>$COMMENTFORM

# now customize the Comment Form page...
sed -i "s/_CHKHOSTS_COMMENTFORM_TITLE_/${_CHKHOSTS_COMMENTFORM_TITLE_}/g" $COMMENTFORM
sed -i "s/_CHKHOSTS_HOSTNAME_/${_CHKHOSTS_HOSTNAME_}/g" $COMMENTFORM
sed -i "s/_CHKHOSTS_POLL_INTERVAL_/${_CHKHOSTS_POLL_INTERVAL_}/g" $COMMENTFORM
sed -i "s/_CHKHOSTS_CONTACTNAME_/${_CHKHOSTS_CONTACTNAME_}/g" $COMMENTFORM
sed -i "s/_CHKHOSTS_CONTACTEMAIL_/${_CHKHOSTS_CONTACTEMAIL_}/g" $COMMENTFORM



#
# Generate the HTML header for status page
#############################################

echo "Generating $WEBPAGE..."
echo '<!DOCTYPE html>' >$WEBPAGE
echo '<html>'  >>$WEBPAGE
echo '<head>'  >>$WEBPAGE
echo '	<meta charset="UTF-8">' >>$WEBPAGE
echo '	<meta http-equiv="refresh" content="300">' >>$WEBPAGE
echo '	<meta name="generator" content="gen-webstat.sh MY_VERSION_STRING">' \
	>>$WEBPAGE
echo '	<link rel="stylesheet" type="text/css" href="style.css">' >>$WEBPAGE
echo "	<title>${_CHKHOSTS_TITLE_}</title>"   >>$WEBPAGE
echo '</head>' >>$WEBPAGE
echo ' ' >>$WEBPAGE

#
# Generate the HTML body
########################

echo '<body>' >>$WEBPAGE

# insert the php POST function and showstatus functions
cat >>$WEBPAGE << "PHP_FUNCTIONS_SECTION"
<?php
        date_default_timezone_set('America/Los_Angeles');
        function showstatus($pingname,$hostname)
        {
                if (file_exists("../status-up/$pingname")) {
			$file = "system-color/$hostname.txt";
			if (file_exists($file)){
				$contents = file_get_contents($file); 
                       		echo "<td style=\"background-color:$contents; \
				border-color: #000000; \
				border-width: 1px 1px 1px 1px\">";
			} else {
				echo '<td style="background-color:green; \
				border-color: #00000; \
				border-width: 1px 1px 1px 1px">';
			}
			if (file_exists("system-info/$hostname.txt")) {
                        	echo "<b>";
				echo "<a href=\"system-info/$hostname.txt\">";
				echo "$hostname</a></b><br>";
			} else {
                        	echo "<b>$hostname</b><br>";
			}
                        if (file_exists("system-comment/$hostname.txt")) {
                                $comment=rtrim(file_get_contents(
					"system-comment/$hostname.txt"));
                                echo $comment;
                                echo "<br>";
                        }
                        if (file_exists("system-line3/$hostname.txt")) {
                                $line3info=rtrim(file_get_contents(
					"system-line3/$hostname.txt"));
                                echo $line3info;
                                echo "<br>";
                        }
                        if (file_exists("system-line4/$hostname.txt")) {
                                $line4info=rtrim(file_get_contents(
					"system-line4/$hostname.txt"));
                                echo $line4info;
                                echo "<br>";
                        }
                        if (file_exists("system-line5/$hostname.txt")) {
                                $line5info=rtrim(file_get_contents(
					"system-line5/$hostname.txt"));
                                echo $line5info;
                                echo "<br>";
                        }
                        if (file_exists("system-line6/$hostname.txt")) {
                                $line6info=rtrim(file_get_contents(
					"system-line6/$hostname.txt"));
                                echo $line6info;
                                echo "<br>";
                        }
                        if (file_exists("system-line7/$hostname.txt")) {
                                $line7info=rtrim(file_get_contents(
					"system-line7/$hostname.txt"));
                                echo $line7info;
                                echo "<br>";
                        }
                        if (file_exists("system-line8/$hostname.txt")) {
                                $line8info=rtrim(file_get_contents(
					"system-line8/$hostname.txt"));
                                echo $line8info;
                                echo "<br>";
                        }
                        echo strftime("%Y-%m-%d at %H:%M %Z",
                                filemtime("../status-up/$pingname"));
                        echo '</td>';
                } else {
			if (file_exists("system-offline/$hostname.txt")) {
                        	echo '<td style="background-color:silver; \
					border-color: #FFFFFF; \
					border-width: 1px 1px 1px 1px">';
			} else {
                        	echo '<td style="background-color:red; \
					border-color: #000000; \
					border-width: 1px 1px 1px 1px">';
			}
			if (file_exists("system-info/$hostname.txt")) {
                        	echo "<b>";
				echo "<a href=\"system-info/$hostname.txt\">";
				echo "$hostname</a></b><br>";
			} else {
                        	echo "<b>$hostname</b><br>";
			}
                        if (file_exists("system-comment/$hostname.txt")) {
                                $comment=rtrim(file_get_contents(
					"system-comment/$hostname.txt"));
                                echo $comment;
                                echo "<br>";
                        }
                        if (file_exists("system-line3/$hostname.txt")) {
                                $line3info=rtrim(file_get_contents(
					"system-line3/$hostname.txt"));
                                echo $line3info;
                                echo "<br>";
                        }
                        if (file_exists("system-line4/$hostname.txt")) {
                                $line4info=rtrim(file_get_contents(
					"system-line4/$hostname.txt"));
                                echo $line4info;
                                echo "<br>";
                        }
                        if (file_exists("system-line5/$hostname.txt")) {
                                $line5info=rtrim(file_get_contents(
					"system-line5/$hostname.txt"));
                                echo $line5info;
                                echo "<br>";
                        }
                        if (file_exists("system-line6/$hostname.txt")) {
                                $line6info=rtrim(file_get_contents(
					"system-line6/$hostname.txt"));
                                echo $line6info;
                                echo "<br>";
                        }
                        if (file_exists("system-line7/$hostname.txt")) {
                                $line7info=rtrim(file_get_contents(
					"system-line7/$hostname.txt"));
                                echo $line7info;
                                echo "<br>";
                        }
                        if (file_exists("system-line8/$hostname.txt")) {
                                $line8info=rtrim(file_get_contents(
					"system-line8/$hostname.txt"));
                                echo $line8info;
                                echo "<br>";
                        }
                        if (file_exists("../status-down/$pingname")) {
                                echo strftime("%Y-%m-%d at %H:%M %Z",
                                        filemtime("../status-down/$pingname"));
                        } else {
                                echo "pinging halted";
                        }
                        echo '</td>';
                }
        }
?>

PHP_FUNCTIONS_SECTION

# insert the header and intro section template
cat >>$WEBPAGE  << "HEADER_INTRO_SECTION"

<div class="body">

<h1 class="title">_CHKHOSTS_TITLE_</h1>
<p align=center><b><?php echo "Last refreshed: ";
                        echo strftime('%c'); ?></b></p>

<p>
The date and time in the bottom of each cell in the tables below is the
time the host <b>last</b> responded to a network ping. &nbsp;
The ping script runs on _CHKHOSTS_HOSTNAME_ 
<b>at a _CHKHOSTS_POLL_INTERVAL_ interval</b> 
and sends text/SMS and e-mail notifications when systems first 
go down or come back up. &nbsp;
Contact <a href="mailto:_CHKHOSTS_CONTACTEMAIL_">_CHKHOSTS_CONTACTNAME_</a>
if you'd like to be added to the SMS or e-mail
notification lists.
</p>

HEADER_INTRO_SECTION

# insert the status table
echo "<h3>System Status Table ($NUMSYSTEMS systems)</h3>" >>$WEBPAGE
echo '<p><table>' >>$WEBPAGE

HOSTCOUNTER=0
for i in $( grep -v -e '^#' $HOSTLISTFILE ); do

	# create short host name...
        IPADDR="`echo $i | grep -e '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*'`"
        if [[ "$IPADDR" == "" ]]; then
                SHORTNAME="`echo $i | awk -F . '{ print $1}'`"
        else
                SHORTNAME="$IPADDR"
        fi

	# start a new table row 	
	if [[ "$((HOSTCOUNTER % $_CHKHOSTS_TABLE_COLS_))" == "0" ]]; then
		echo '<tr>' >>$WEBPAGE
	fi
	echo "<?php showstatus(\"$i\",\"$SHORTNAME\"); ?>" >>$WEBPAGE

	let "HOSTCOUNTER += 1"
done
echo '</table></p>' >>$WEBPAGE


# insert the Log links section 
cat >>$WEBPAGE << "LOG_SECTION"
<p>
The comment (line 2) for each host in the system status table 
above can be updated via the web. &nbsp;
All changes are logged with the date and time the change was 
made. &nbsp;
Use these links to make updates or to review the comments log:
<ul>
	<li><a href="update-comment.php">
		<b>Update Comment (line 2)</b></a> 
		&nbsp;&nbsp;(<a href="comment.log">
		Review Comment Change Log</a>)</li>
</ul>
</p>
<p>
Use this link to review host status changes (up/down):
<ul>
	<li><a href="../log/chkhosts.log"><b>Host Status Change Log</b></a></li>
</ul>
</p>
<p>
Windows users:  The log file links above render best in Google 
Chrome or Firefox; 
Internet Explorer reportedly garbles or doesn't display the 
log file at all.
</p>
LOG_SECTION


# insert the footer
cat >>$WEBPAGE << "FOOTER_SECTION"
</div>

<div class="footer"> 
      <hr width="55%">
      <p align="center">This page generated by 
	<a href="https://github.com/k6ekb/chkhosts">
	gen-webstat.sh MY_VERSION_STRING</a><br>
	This page last edited on 
	<?php echo  strftime("%a, %d %b %Y at %H:%M %Z.", 
		filemtime("status.php")); ?><br>
        You're logged in as '<?php print getenv("REMOTE_USER");?>' 
	from <?php print getenv("REMOTE_ADDR"); ?><br>
</div>
FOOTER_SECTION

#
# Close out document 
####################

echo '</body>' >>$WEBPAGE
echo '</html>' >>$WEBPAGE


# now customize it...
sed -i "s/_CHKHOSTS_TITLE_/${_CHKHOSTS_TITLE_}/g" $WEBPAGE
sed -i "s/_CHKHOSTS_HOSTNAME_/${_CHKHOSTS_HOSTNAME_}/g" $WEBPAGE
sed -i "s/_CHKHOSTS_POLL_INTERVAL_/${_CHKHOSTS_POLL_INTERVAL_}/g" $WEBPAGE
sed -i "s/_CHKHOSTS_CONTACTNAME_/${_CHKHOSTS_CONTACTNAME_}/g" $WEBPAGE
sed -i "s/_CHKHOSTS_CONTACTEMAIL_/${_CHKHOSTS_CONTACTEMAIL_}/g" $WEBPAGE

# ensure an empty status change log exists (for new installation)
mkdir -p $CHKHOSTLOGDIR
touch $CHKHOSTLOG

# make sure the status-up & status-down directories exist
mkdir -p $UPHOSTSTATUSDIR
mkdir -p $DOWNHOSTSTATUSDIR

# make sure the system-info, and system-line[3-8] 
# directories exist
mkdir -p $WEBSYSTEMINFODIR
mkdir -p $WEBSYSTEMCOLORDIR
mkdir -p $WEBSYSTEMLINE3DIR
mkdir -p $WEBSYSTEMLINE4DIR
mkdir -p $WEBSYSTEMLINE5DIR
mkdir -p $WEBSYSTEMLINE6DIR
mkdir -p $WEBSYSTEMLINE7DIR
mkdir -p $WEBSYSTEMLINE8DIR

# all done!
echo "All done."
exit 0
