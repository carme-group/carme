FROM python:3.9 as builder


RUN apt update && apt install -y npm
RUN mkdir /opt/carme/caddy
RUN cd /opt/carme/caddy && \
    curl -OL https://github.com/caddyserver/caddy/releases/download/v2.2.1/caddy_2.2.1_linux_amd64.tar.gz \
    && tar xzf caddy_2.2.1_linux_amd64.tar.gz \
    && rm caddy_2.2.1_linux_amd64.tar.gz
RUN python3.9 -m venv /opt/carme/venvs/jupyter
RUN /opt/carme/venvs/jupyter/bin/python -m pip install jupyter pycus>=20.11.0
RUN python3.9 -m venv /opt/carme/venvs/ncolony
RUN /opt/carme/venvs/jupyter/bin/jupyter nbextension enable --py widgetsnbextension --sys-prefix
RUN /opt/carme/venvs/jupyter/bin/jupyter labextension install @jupyter-widgets/jupyterlab-manager
RUN /opt/carme/venvs/ncolony/bin/python -m pip install ncolony

COPY Caddyfile /opt/carme/caddy/
COPY jupyte-config.py /opt/carme/venvs/jupyter/etc/jupyter/config.py 

ENV NCOLONY_ROOT=/opt/carme/ncolony

RUN mkdir -p $NCOLONY_ROOT/config $NCOLONY_ROOT/messages
RUN mkdir -p /opt/carme/homedir/venvs /opt/carme/homedir/src
RUN useradd --uid 1000 --home-dir /opt/carme/homedir/ --shell /bin/bash jupyter 
RUN chown -R jupyter /opt/carme/homedir
RUN /opt/carme/venvs/ncolony/bin/python -m ncolony ctl \
    --messages $NCOLONY_ROOT/messages \
    --config $NCOLONY_ROOT/config \
    add jupyter --cmd /opt/carme/venvs/jupyter/bin/jupyter \
    --arg lab \
    --arg=--config --arg /opt/carme/venvs/jupyter/etc/jupyter/config.py \
    --uid=1000 \
    --env HOME=/opt/carme/homedir \
    --env WORKON_HOME=/opt/carme/homedir/venvs

RUN /opt/carme/venvs/ncolony/bin/python -m ncolony ctl \
    --messages $NCOLONY_ROOT/messages \
    --config $NCOLONY_ROOT/config \
    add caddy --cmd /opt/carme/caddy/caddy \
    --arg run --arg=-config --arg=/opt/carme/caddy/Caddyfile \
    --env-inherit SITE_ADDRESS \
    --env-inherit PASSWORD_HASH \
    --env-inherit STAGING \
    --env-inherit HOME


FROM python:3.9
COPY --from=builder /opt/carme /opt/carme
RUN useradd --uid 1000 --home-dir /opt/carme/homedir/ --shell /bin/bash jupyter 
ENTRYPOINT ["/opt/carme/venvs/ncolony/bin/python", \
            "-m", "twisted", "ncolony", \
            "--messages", "/opt/carme/ncolony/messages", \
            "--conf", "/opt/carme/ncolony/config"]
