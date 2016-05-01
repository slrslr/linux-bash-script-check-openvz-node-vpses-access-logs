# empty old report file
> /tmp/allvpslogscanneroutput

# Script tails webserver access logs on all VPSs using VZCTL (openvz tool) and send out report to admin using tool "mutt" (make sure it is installed)

# exclude CTIDs
exclude="MYVPSID|1234|65432"
adminmail=adminmailhere@gmail.com
# adjust also line 52 and 56

########### cPanel acccess logs

for ctid in $(vzlist -Ho ctid|grep -vE "$exclude");do

cmd="echo \"----------- CTID $ctid IP $(vzlist $ctid -Ho ip) cPanel access logs: -----------\" && tail /usr/local/apache/domlogs/*|grep -vE \"bytes|offsetftp|ftpxfer\"|grep \".\""

vzctl exec $ctid $cmd 2>/dev/null >> /tmp/allvpslogscanneroutput

done

########### zPanel access logs

for ctid in $(vzlist -Ho ctid|grep -vE "$exclude");do

if [ "$(vzctl exec $ctid ls /var/zpanel/logs/domains/zadmin/*access.log 2>/dev/null)" == "" ];then
#echo "There is no such dir at $ctid, continue next iteration"
#read fffff
continue
fi

cmd="echo \"----------- CTID $ctid IP $(vzlist $ctid -Ho ip) zPanel access logs: -----------\" && tail /var/zpanel/logs/domains/zadmin/*access*|grep -vE \".png|.gif|.ico|.jpg|robots|GET / HTTP\""

vzctl exec $ctid $cmd >> /tmp/allvpslogscanneroutput

# awk '{print $7}'

done

########## Apache access logs

for ctid in $(vzlist -Ho ctid|grep -vE "$exclude");do

cmd="echo \"----------- CTID $ctid IP $(vzlist $ctid -Ho ip) Apache access logs: -----------\" && tail /var/log/httpd/access_log 2>/dev/null|grep -vE \"myadmin|MyAdmin|baidu\"| awk '{print $7}'|grep -vE \".png|.gif|.ico|.jpg\"|sort -u;tail /var/log/apache2/access.log 2>/dev/null|grep -vE \"myadmin|MyAdmin|baidu\"| awk '{print $7}'|grep -vE \".png|.gif|.ico|.jpg\"|sort -u"

vzctl exec $ctid $cmd >> /tmp/allvpslogscanneroutput

done

########## Create webpage out of report file

# Create WebPage Out Of Log File command
cp -f /tmp/allvpslogscanneroutput /vz/root/MYVPSID/home/usernamehere/public_html/vps-logs.txt; vzctl exec MYVPSID chown usernamehere:usernamehere /home/usernamehere/public_html/vps-logs.txt

########## Send email to admin including report file

echo -e "Script /root/vpslogscanner ran at $(hostname) on $(date) and attached are access logs of all hosted VPSs except CTID $exclude \nView the logs on the web: http://admindomainhere.cz/vps-logs.txt" | mutt -a "/tmp/allvpslogscanneroutput" -s "VPSs access logs Report" -- $adminmail