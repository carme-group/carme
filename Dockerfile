FROM python:3.9 as builder

ENV NCOLONY_ROOT=/opt/carme/ncolony

RUN python3.9 -m venv /opt/carme/venvs/jupyter
RUN python3.9 -m venv /opt/carme/venvs/ncolony
RUN /opt/carme/venvs/jupyter/bin/python -m pip install jupyter pycus
RUN /opt/carme/venvs/ncolony/bin/python -m pip install ncolony

RUN mkdir /opt/carme/caddy
RUN cd /opt/carme/caddy && curl -OL https://github.com/caddyserver/caddy/releases/download/v2.2.1/caddy_2.2.1_linux_amd64.tar.gz && tar xzf caddy_2.2.1_linux_amd64.tar.gz

RUN mkdir -p $NCOLONY_ROOT/config $NCOLONY_ROOT/messages /opt/carme/src/

RUN echo "c.NotebookApp.token = ''" >> /opt/carme/venvs/jupyter/etc/jupyter/config.py 
RUN echo "c.NotebookApp.password = ''" >> /opt/carme/venvs/jupyter/etc/jupyter/config.py 
RUN echo "c.NotebookApp.notebook_dir = '/opt/carme/src'" >> /opt/carme/venvs/jupyter/etc/jupyter/config.py 

RUN /opt/carme/venvs/ncolony/bin/python -m ncolony ctl \
    --messages $NCOLONY_ROOT/messages \
    --config $NCOLONY_ROOT/config \
    add jupyter --cmd /opt/carme/venvs/jupyter/bin/jupyter \
    --arg lab --arg=--allow-root \
    --arg=--config --arg /opt/carme/venvs/jupyter/etc/jupyter/config.py \
    --arg=--ip --arg "0.0.0.0" \
    --env-inherit HOME

COPY Caddyfile /opt/carme/caddy/
RUN /opt/carme/venvs/ncolony/bin/python -m ncolony ctl \
    --messages $NCOLONY_ROOT/messages \
    --config $NCOLONY_ROOT/config \
    add caddy --cmd /opt/carme/caddy/caddy \
    --arg run --arg=-config --arg=/opt/carme/caddy/Caddyfile \
    --env-inherit SITE_ADDRESS \
    --env-inherit PASSWORD_HASH \
    --env-inherit STAGING \
    --env-inherit HOME

ENTRYPOINT ["/opt/carme/venvs/ncolony/bin/python", \
            "-m", "twisted", "ncolony", \
            "--messages", "/opt/carme/ncolony/messages", \
            "--conf", "/opt/carme/ncolony/config"]


#FROM python:3.9
#COPY --from=builder /opt/carme /opt/carme
#ENTRYPOINT ["python", "-m", "twisted", "ncolony", \
#                            "--messages", "/opt/carme/ncolony/messages",
#                            "--conf", "/opt/carme/ncolony/config"]
