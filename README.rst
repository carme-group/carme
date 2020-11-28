Carme
=====

Carme_ is named after the moon of Jupiter.

.. _Carme: https://en.wikipedia.org/wiki/Carme_(moon)

It wraps together three things:

* JupyterLab_
* Caddy_
* Pycus_

.. _JupyterLab: https://jupyterlab.readthedocs.io/en/stable/
.. _Caddy: https://caddyserver.com/
.. _Pycus: https://pycus.readthedocs.io/en/latest/

These three things,
and some glue,
are build into a Docker image that is designed to run on an
internet-accessible IP,
with DNS entry pointing to it.

Contributing to Carme
----------------------

* Follow the Code of Conduct
* In your first PR, add your name to the contributor list.

Using Carme
------------

Using Caddy's
`Let's Encrypt`_
integration,
it will run a password-authenticated TLS wrapper
around JupyterLab.
This TLS wrapper will also wrap JupyterLab
with password-based authentication.
Note that the password
*hash*
will be available in an environment variable of the Docker container.
As always,
use best practices for a secure password.

.. _Let's Encrypt: https://letsencrypt.org/

After building the docker container, you can run it with:

..code::

    docker run -p 1443:443 \
           --name carme \
           --env SITE_ADDRESS=<DNS NAME> \
           --env STAGING="" \
           -env PASSWORD_HASH= <PASSWORD HASH>\
           -d carme


If you are testing out correct DNS pointing,
you can use ``--env staging=staging-``
(note trailing dash).
In order to get a password hash, you can run the container,
ideally locally,

.. code::

    $ docker run --rm -it --entrypoint bash carme
    root@bdb995c8d1c1:/# /opt/carme/caddy/caddy hash-password
    Enter password: 
    Confirm password: 
    JDJhJDE0JC8zLzljNHhSb0oxbzc4bjM2blMwV3VlaVQ5T3RnT3l5QVB2SFhHdjgxazI3ajNJWmRjdktH


.. note::
    Your hash will be different. The hash above was generated from a password
    I generated and then deleted. If you use it, you will not be able to log in
    unless you restart your container with a different hash.

Contributors
------------

* Moshe Zadka <moshez@zadka.club>