#!/bin/bash

PortFile="/etc/apache2/ports.conf"
ConfDirectory="/etc/apache2/conf-available/"
SiteDirectory="/etc/apache2/sites-available/"
LogDirectory="/var/log/apache2/"
ssldir=(
keys
csr
accounts
archive
live
renewal
renewal-hooks
)
for dir in ${ssldir[@]};do
mkdir -p /etc/apache2/ssl/$dir	
done
ask_question() {
		while true; do
    		read -rp "$1 (Y/n): " response
    		case ${response,,} in
        			y|"") return 0;;
        			n ) return 1;;
        			* ) echo "لطفاچرت و پرت وارد نکنید😐";
   			esac
		done;
}


CheckModules(){
cat << 'EOF'

#######################################################
######						 ######
######	           CHECKIGN  MODULES 		 ######
######						 ######
#######################################################

EOF
declare -A modules=(
"security2"		"libapache2-mod-security2"
"proxy"			"libapache2-mod-proxy-html libxml2-dev"
"proxy_ajp"		"libapache2-mod-proxy-html libxml2-dev"
"proxy_balancer"	"libapache2-mod-proxy-html libxml2-dev"
"proxy_connect"		"libapache2-mod-proxy-html libxml2-dev"
"proxy_express"		"libapache2-mod-proxy-html libxml2-dev"
"proxy_fcgi"		"libapache2-mod-proxy-html libxml2-dev"
"proxy_fdpass"		"libapache2-mod-proxy-html libxml2-dev"
"proxy_ftp"		"libapache2-mod-proxy-html libxml2-dev"
"proxy_hcheck"		"libapache2-mod-proxy-html libxml2-dev"
"proxy_html"		"libapache2-mod-proxy-html libxml2-dev"
"proxy_http"		"libapache2-mod-proxy-html libxml2-dev"
"proxy_http2"		"libapache2-mod-proxy-html libxml2-dev"
"proxy_scgi"		"libapache2-mod-proxy-html libxml2-dev"
"proxy_uwsgi"		"libapache2-mod-proxy-html libxml2-dev"	
"proxy_wstunnel"	"libapache2-mod-proxy-html libxml2-dev"
"macro"			"libapache2-mod-macro"
"headers"		"apache2 apache2-dev"
"alias"			"apache2 apache2-dev"
"ssl"			"libapache2-mod-ssl"
"rewrite"		"libapache2-mod-rewrite"
"evasive"		"libapache2-mod-evasive"
)
for m in ${!modules[@]};
do	
	echo "checking "$m':'
if [ -f "/etc/apache2/mods-available/"$m".load" ] || [ -f "/etc/apache2/mods-available/"$m".conf" ]; then
	echo $m "is already installed"
	if [ ! -z $(a2query -m | awk '{print $1}' | sort -n | grep $m) ];then
                echo "All $m modules are already enabled."
        else
                echo "Enabling header modules..."
                sudo a2enmod $m
                echo "$m modules have been enabled."
        fi
else
   	echo $m "is Not installed"
	eval "sudo apt install ${modules[$m]}"
	if [ -f "/etc/apache2/mods-available/"$m".load" ] || [ -f "/etc/apache2/mods-available/"$m".conf" ]; then
        	echo $m "is already installed"
        	if [ ! -z $(a2query -m | awk '{print $1}' | sort -n | grep $m) ];then
                	echo "All $m modules are already enabled."
        	else
               		echo "Enabling $m modules..."
                	eval "sudo a2enmod $m"
                	echo "$m modules have been enabled."
        	fi
	else
		echo "you Got error in module $m "
	fi
fi
	echo  -e "\n" "\n"	
done
if [ $? -eq 0 ];then 
	apachectl configtest || result=$?
	if [ $result -eq 0 ];then
		service apache2 restart
	else
		a2dismod ssl
		service apache2 restart
	fi

fi
}







MakeMacros(){
cat << 'EOF'

#######################################################
######					         ######
######	    	   MAKEING MACROS	         ######
######						 ######
#######################################################

EOF

cat << 'EOF' > $ConfDirectory/publish.conf
<Macro publish $domain $subdomain $Zone $address $customconfig $proxyheader $sslproxy $modesecurity>
<VirtualHost ${$Zone_IP}:80>
      RewriteEngine on
      ServerName $subdomain.$domain
      ErrorLog /var/log/apache2/$Zone/$domain/$subdomain-error.log
      CustomLog /var/log/apache2/$Zone/$domain/$subdomain-access.log combined
	<IfModule !mod_ssl.c>
       	IncludeOptional /etc/apache2/sites-available/$Zone/$domain/$customconfig.conf
      	IncludeOptional /etc/apache2/sites-available/$Zone/$Zone.conf
       	ProxyPass / $address
       	ProxyPassReverse / $address
      	ProxyPreserveHost on
       	ProxyAddHeaders $proxyheader
       	SecRuleEngine $modesecurity
	 </IfModule>
	 <IfModule mod_ssl.c>
      	 RewriteCond %{SERVER_NAME} =$subdomain.$domain
     		 RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
       	#RewriteCond %{REQUEST_METHOD} ^(HEAD|PUT|DELETE) 
       	#RewriteRule .* - [F]
	 </IfModule>
</VirtualHost>
<IfModule mod_ssl.c>
<VirtualHost ${$Zone_IP}:443>
	ServerName $subdomain.$domain
      ErrorLog /var/log/apache2/$Zone/$domain/$subdomain-ssl-error.log
      CustomLog /var/log/apache2/$Zone/$domain/$subdomain-ssl-access.log combined
      IncludeOptional /etc/apache2/sites-available/$Zone/$domain/$customconfig.conf
	IncludeOptional /etc/apache2/sites-available/$Zone/$Zone.conf
      ProxyPass / $address
      ProxyPassReverse / $address
      ProxyPreserveHost on
      SSLEngine on
	Define SSL_DIR /etc/apache2/ssl/live/$domain
	<IfFile "/etc/apache2/ssl/live/$subdomain.$domain">
		Define SSL_DIR /etc/apache2/ssl/live/$subdomain.$domain
	</IfFile>
      CustomLog /var/log/apache2/VARS.log "${$Zone_IP} %{X-Real-IP}i %{True-Client-IP}i  ${SSL_DIR}"
	SSLCertificateFile ${SSL_DIR}/cert.pem
      SSLCertificateKeyFile ${SSL_DIR}/privkey.pem
      SSLCertificateChainFile ${SSL_DIR}/chain.pem
	SSLProxyEngine $sslproxy
      SSLProxyVerify none
      SSLProxyCheckPeerCN off
      SSLProxyCheckPeerName off
      SSLProxyCheckPeerExpire off
      ProxyAddHeaders $proxyheader
	SecRuleEngine $modesecurity



#	<IfModule mod_evasive20.c>
#	    DOSHashTableSize    3097
#	    DOSPageCount        10
#	    DOSSiteCount        100
#	    DOSPageInterval     1
#	    DOSSiteInterval     1
#	    DOSBlockingPeriod   10
#	
#	    DOSEmailNotify      erfanansary313@gmail.com
#	    DOSSystemCommand    "su - www-data -c 'alert %s %r'"
#		# '$subdomain.$domain'"
#	    DOSLogDir           "/var/log/apache2/$Zone/$domain"
#	</IfModule>

</VirtualHost>
</IfModule>
</Macro>
EOF
cat << 'EOF' > $ConfDirectory/root-publish.conf
<Macro root-publish $domain $Zone $address $customconfig $proxyheader $sslproxy $modesecurity>
<VirtualHost ${$Zone_IP}:80>
       RewriteEngine on
       ServerName $domain
       ErrorLog /var/log/apache2/$Zone/$domain/$domain-error.log
       CustomLog /var/log/apache2/$Zone/$domain/$domain-access.log combined
	<IfModule !mod_ssl.c>
       	IncludeOptional /etc/apache2/sites-available/$Zone/$domain/$customconfig.conf
      	IncludeOptional /etc/apache2/sites-available/$Zone/$Zone.conf
       	ProxyPass / $address
       	ProxyPassReverse / $address
      	ProxyPreserveHost on
       	ProxyAddHeaders $proxyheader
       	SecRuleEngine $modesecurity
	 </IfModule>
	 <IfModule mod_ssl.c>
      	 RewriteCond %{SERVER_NAME} =$domain
     		 RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
       	#RewriteCond %{REQUEST_METHOD} ^(HEAD|PUT|DELETE) 
       	#RewriteRule .* - [F]
	 </IfModule>
</VirtualHost>
<IfModule mod_ssl.c>
<VirtualHost ${$Zone_IP}:443>
       ServerName $domain
       ErrorLog /var/log/apache2/$Zone/$domain/$domain-ssl-error.log
       CustomLog /var/log/apache2/$Zone/$domain/$domain-ssl-access.log combined
	 IncludeOptional /etc/apache2/sites-available/$Zone/$domain/$customconfig.conf
	 IncludeOptional /etc/apache2/sites-available/$Zone/$Zone.conf
	 ProxyPass / $address
       ProxyPassReverse / $address
       ProxyPreserveHost on
       SSLEngine on
	 Define SSL_DIR /etc/apache2/ssl/live/$domain
       CustomLog /var/log/apache2/VARS.log "${$Zone_IP} %{X-Real-IP}i %{True-Client-IP}i  ${SSL_DIR}"
       SSLCertificateFile ${SSL_DIR}/cert.pem
       SSLCertificateKeyFile ${SSL_DIR}/privkey.pem
       SSLCertificateChainFile ${SSL_DIR}/chain.pem
	 SSLProxyEngine $sslproxy
       SSLProxyVerify none
       SSLProxyCheckPeerCN off
       SSLProxyCheckPeerName off
       SSLProxyCheckPeerExpire off
       ProxyAddHeaders $proxyheader
       SecRuleEngine $modesecurity
</VirtualHost>
</IfModule>
</Macro>
EOF
cat << 'EOF' > $ConfDirectory/harden.conf
<Macro harden $Zone>
Define SSL_DIR /etc/apache2/ssl/live/rcsis.ir
<VirtualHost ${$Zone_IP}:80>
       ServerName default.invalid
       DocumentRoot /var/www/html/default/404
       ErrorDocument 404 /404.html
       <IfModule mod_ssl.c>
               RewriteEngine On
               RewriteCond %{HTTPS} !=on
               RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
       </IfModule>
</VirtualHost>
<IfModule mod_ssl.c>
<VirtualHost ${$Zone_IP}:443>
       ServerName default.invalid
       DocumentRoot /var/www/html/default/404
       ErrorDocument 404 /404.html
       SSLEngine on
       SSLCertificateFile ${SSL_DIR}/cert.pem
       SSLCertificateKeyFile ${SSL_DIR}/privkey.pem
       SSLCertificateChainFile ${SSL_DIR}/chain.pem
</VirtualHost>
</IfModule>
</Macro>
EOF
cat << 'EOF' > $SiteDirectory/ssl.conf
<Location "/.well-known">
        ProxyPass "!"
        SecRuleEngine off
</Location>
Alias /.well-known /var/www/html/.well-known
<Directory "/var/www/html/.well-known">
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
</Directory>
EOF
echo "enable marcos"
a2enconf harden publish root-publish
if [ $? -eq 0 ];then 
	apachectl configtest
	if [ $? -eq 0 ];then
		service apache2 restart
	else
		a2dismod ssl
		service apache2 restart
	fi

fi
}




MakeZones(){
cat << 'EOF'

#######################################################
######                                           ######
######  DEFINE ZONES AND MAKE ZONES DIRECTOIES   ######
######                                           ######
#######################################################

EOF

declare -A Zones
condition=true
while $condition; do 
	read -p "Please enter your Zones Name: " Name
    read -p "Please enter your Zones Ip Address: " Ip
	if ask_question "Do you confirm your Name And Ip Zone?"; then
		Zones["$Name"]="$Ip"
		if ask_question "Do you want add another Zone?"; then
			echo "Please Enter Your Zone.."
		
		else	
			cat << 'EOF' > $PortFile
# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf
#--Define Zones Ips--#


#--Listen Zones Ips--#


<IfModule ssl_module>
#--Ssl Listen Zones Ips--#
</IfModule>



<IfModule mod_gnutls.c>
#--Gnutls Listen Zones Ips--#
</IfModule>
EOF
			echo "Making Your Zone..."
			echo "ZoneName	ZoneIp"
			for zone in ${!Zones[@]};do 
				X=${Zones[$zone]}
				mkdir -p $LogDirectory/$zone
				mkdir -p $SiteDirectory/$zone
				touch $SiteDirectory/$zone/$zone.conf
				bash -c "echo 'Use harden' $zone >> /etc/apache2/sites-enabled/000-default.conf"
				echo "$zone		$X"
				zone=$zone'_IP'
				sed -i "/#--Define Zones Ips--#/a\ Define  $zone   $X" $PortFile
				sed -i "/#--Listen Zones Ips--#/a\ Listen \${$zone}:80" $PortFile
				sed -i "/#--Ssl Listen Zones Ips--#/a\ Listen \${$zone}:443" $PortFile
				sed -i "/#--Gnutls Listen Zones Ips--#/a\ Listen \${$zone}:443" $PortFile
			done
			condition=false
		fi
	else
		echo "Please Enter Your Zone Again.."
	fi
done
}

InstallWaf(){
cat << 'EOF'

#######################################################
######                                           ######
######  	    INSTALLING WAF		 ######
######                                           ######
#######################################################

EOF

if [ -x "$(command -v apache2)" ]; then
    echo "Apache2 is already installed."
	CheckModules
	MakeMacros
	MakeZones
	MakeDomain

else
	echo "installing Apache2"
        sudo apt update
        sudo apt install apache2*
		if [ $? -eq 0 ];then
			CheckModules
			MakeMacros
			MakeZones
			MakeDomain
		fi
fi
}

MakeDomain(){

echo """

#######################################################
######                                           ######
###### 		     MAKE DOMAIN                 ######
######                                           ######
#######################################################

"""
	

declare -a Domains
while true; do 
	read -p "Please enter your Domain Name: " Name
	if ask_question "Do you confirm your Domain?"; then
		Domains+=("$Name")
		if ask_question "Do you want add another Domain?"; then
			echo "Please Enter Your Domain.."
		
		else	
			echo "Making Your Domain..."
			count=0
			while [ $count -lt ${#Domains[@]} ];do
				#for domain in ${!Domains[@]};do
				X=${Domains[$count]}
				readarray -t dirs < <(\
				find $SiteDirectory \
					-maxdepth 1 \
					-mindepth 1 \
					-type d \
					-printf '%f\n'\
				)
				if [ ${#dirs[@]} -eq 0 ]; then
    					echo "No zones found."
					MakeZones
					
				else
					echo "#--- Make Directories For Domain: $X ---# "
					touch $SiteDirectory/$X.conf
					sed -i '1i\#Use [Macro Name] [domain] [Subdomain] [Access] [Url For Proxy] [Cutom Config] [ProxyHeader] [SslProxy] [ModeSecurity]' $SiteDirectory/$X.conf
					echo $SiteDirectory/$X.conf
					for zone in ${dirs[@]};do 
						echo "Make $X Files For "$zone" Zone"
						mkdir -p $LogDirectory/$zone/$X
						echo $LogDirectory/$zone/$X
						mkdir -p $SiteDirectory/$zone/$X
						echo $SiteDirectory/$zone/$X
						echo "#--$zone access--#" | tr '[:lower:]' '[:upper:]' >> $SiteDirectory/$X.conf
						echo -e "\n"
					done
					count=$(( $count + 1 ))
				fi	
			#	done
			echo "you all domains are: "${Domains[@]}
			done
			a2ensite ${Domains[@]}
			if [ $? -eq 0 ];then
			      echo "Restart Sevice..."
  			      service apache2 restart
			fi
			break;
		fi
	else
		echo "Please Enter Your Domain Again.."
	fi
done
}


if [ -n "$1" ]; then
    case "$1" in
	-m|m)
		MakeMacros
		;;
	-d|d)
		MakeDomain
		;;
	-z|z)
		MakeZones
		;;
        -c|c)
            	CheckModules
		;;
        -i|i)
            	InstallWaf
            	;;
	-h|h)
		echo """
i for install Waf
m for Make Macros
z for make Zone
d for make Domain
c for check installed and enabled modules
		"""
		;;
        *)
            echo "Invalid input. Please enter 'start' or 'stop'."
            ;;
    esac
else
    echo "input switches or for help <iecw -h>"
fi
