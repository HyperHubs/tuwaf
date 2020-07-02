FROM owasp/modsecurity:2.9-apache-ubuntu

ENV CRS_PATH=/etc/modsecurity.d/owasp-crs

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get -y install python git nano ca-certificates

WORKDIR /etc/modsecurity.d

# Checking out by git sha to get version 3.0.2 of CRS
# See https://github.com/SpiderLabs/owasp-modsecurity-crs/releases/tag/v3.0.2
RUN \
  git clone -b v3.3/master --single-branch https://github.com/coreruleset/coreruleset owasp-crs && \
  cd owasp-crs && \
  git checkout e4e0497be4d598cce0e0a8fef20d1f1e5578c8d0 && \
  rm -rf .git util/regression-tests

RUN \
  mv owasp-crs/crs-setup.conf.example owasp-crs/crs-setup.conf && \
  mv owasp-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example owasp-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf && \
  mv owasp-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example owasp-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

# Need this to make for loop work correctly in the next RUN block
SHELL ["/bin/bash", "-c"]

COPY proxy.conf /etc/apache2/conf-available
RUN \
  sed -i -e 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' modsecurity.conf && \
 a2enmod proxy proxy_http && a2enconf proxy.conf && service apache2 restart


COPY *.sh /
RUN chmod u+x /*.sh

#COPY http.conf /

ENV PARANOIA=1

# Possible values: On, Off, DetectionOnly
ENV SEC_RULE_ENGINE=On

ENV SEC_PRCE_MATCH_LIMIT=500000
ENV SEC_PRCE_MATCH_LIMIT_RECURSION=500000

# Keycloak proxy most probably in our case, hence port 3000
ENV PROXY_UPSTREAM_HOST=localhost:3000

# Allow to congifure client_max_body_size to avoid a HTTP 413
ENV CLIENT_MAX_BODY_SIZE=1m

# Avoid clickjacking attacks, by ensuring that content is not embedded into other sites.
# Possible values: DENY, SAMEORIGIN, ALLOW-FROM https://example.com/
# Remove this header with values: Off, No or an empty string
ENV PROXY_HEADER_X_FRAME_OPTIONS=SAMEORIGIN

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apachectl", "-D", "FOREGROUND"]
