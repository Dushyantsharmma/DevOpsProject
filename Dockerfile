FROM tomcat:9.0
COPY target/simple-webapp.war /usr/local/tomcat/webapps/ROOT.war
