FROM python:3.9 as builder

ENV NCOLONY_ROOT=/opt/valetudo/ncolony

RUN python3.9 -m venv /opt/valetudo/venvs/jupyter
RUN python3.9 -m venv /opt/valetudo/venvs/ncolony
RUN /opt/valetudo/venvs/jupyter/bin/python -m pip install jupyter pycus
RUN /opt/valetudo/venvs/ncolony/bin/python -m pip install ncolony

RUN mkdir /opt/valetudo/caddy
RUN cd /opt/valetudo/caddy && curl -OL https://github.com/caddyserver/caddy/releases/download/v2.2.1/caddy_2.2.1_linux_amd64.tar.gz && tar xzf caddy_2.2.1_linux_amd64.tar.gz

RUN mkdir -p $NCOLONY_ROOT/config $NCOLONY_ROOT/messages /opt/valetudo/src/

RUN echo "c.NotebookApp.token = ''" >> /opt/valetudo/venvs/jupyter/etc/jupyter/config.py 
RUN echo "c.NotebookApp.password = ''" >> /opt/valetudo/venvs/jupyter/etc/jupyter/config.py 
RUN echo "c.NotebookApp.notebook_dir = '/opt/valetudo/src'" >> /opt/valetudo/venvs/jupyter/etc/jupyter/config.py 

RUN /opt/valetudo/venvs/ncolony/bin/python -m ncolony ctl \
    --messages $NCOLONY_ROOT/messages \
    --config $NCOLONY_ROOT/config \
    add jupyter --cmd /opt/valetudo/venvs/jupyter/bin/jupyter \
    --arg lab --arg=--allow-root \
    --arg=--config --arg /opt/valetudo/venvs/jupyter/etc/jupyter/config.py \
    --env-inherit HOME

COPY Caddyfile /opt/valetudo/caddy/
RUN /opt/valetudo/venvs/ncolony/bin/python -m ncolony ctl \
    --messages $NCOLONY_ROOT/messages \
    --config $NCOLONY_ROOT/config \
    add caddy --cmd /opt/valetudo/caddy/caddy \
    --arg run --arg=-config --arg=/opt/valetudo/caddy/Caddyfile \
    --env-inherit SITE_ADDRESS \
    --env-inherit PASSWORD_HASH \
    --env-inherit STAGING \
    --env-inherit HOME

ENTRYPOINT ["/opt/valetudo/venvs/ncolony/bin/python", \
            "-m", "twisted", "ncolony", \
            "--messages", "/opt/valetudo/ncolony/messages", \
            "--conf", "/opt/valetudo/ncolony/config"]


#FROM python:3.9
#COPY --from=builder /opt/valetudo /opt/valetudo
#ENTRYPOINT ["python", "-m", "twisted", "ncolony", \
#                            "--messages", "/opt/valetudo/ncolony/messages",
#                            "--conf", "/opt/valetudo/ncolony/config"]
