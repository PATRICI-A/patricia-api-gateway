FROM kong:3.7

USER root
RUN apt-get update && apt-get install -y gettext-base && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /usr/local/kong/declarative
COPY kong.yml /usr/local/kong/declarative/kong.yml.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN chown -R kong:kong /usr/local/kong/declarative
USER kong

ENTRYPOINT ["/entrypoint.sh"]
