FROM httpd:2.4
# RUN sed -i '/LoadModule rewrite_module/s/^#//g' /usr/local/apache2/conf/httpd.conf

# remove base href "modeller" cause our modeller will not be in a subdirectory
RUN sed -i 's/href="\/modeller/href="/g' ./modeller/index.html

COPY ./modeller/ /usr/local/apache2/htdocs/
COPY .htaccess   /usr/local/apache2/htdocs/

# Copy conf
COPY httpd.conf /usr/local/apache2/conf/
COPY ./extra/httpd-ssl.conf /usr/local/apache2/conf/extra/

# Copy ssl certificate
COPY ./ssl/ /usr/local/apache2/conf/


