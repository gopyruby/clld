"""
Deployment utilities for clld apps
"""
import time
import json

from fabric.api import sudo, run, local, put, env
from fabtools import require
from fabtools.python import virtualenv
from fabtools import service

from clld.deploy import config


LOCATION_TEMPLATE = """\
location /{app.name} {{
        proxy_pass_header Server;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_set_header X-Forwarded-For  $remote_addr;
        proxy_set_header X-Scheme $scheme;
        proxy_connect_timeout 10;
        proxy_read_timeout 10;
        proxy_pass http://127.0.0.1:{app.port}/;
}}
"""

SUPERVISOR_TEMPLATE = """\
[program:{app.name}]
command={gunicorn} -u {app.name} -g {app.name} --error-logfile {app.error_log} {app.config}
autostart=true
autorestart=true
redirect_stderr=True
"""

_CONFIG_TEMPLATE = """\
[app:{app.name}]
use = egg:{app.name}
pyramid.reload_templates = false
pyramid.debug_authorization = false
pyramid.debug_notfound = false
pyramid.debug_routematch = false
pyramid.default_locale_name = en
pyramid.includes =
    pyramid_tm
    pyramid_exclog

sqlalchemy.url = {app.sqlalchemy_url}
exclog.extra_info = true

%s

[server:main]
use = egg:waitress#main
host = 0.0.0.0
port = {app.port}
worker = 3

[loggers]
keys = root, {app.name}, sqlalchemy, exc_logger

[handlers]
keys = console, exc_handler

[formatters]
keys = generic, exc_formatter

[logger_root]
level = WARN
handlers = console

[logger_{app.name}]
level = WARN
handlers =
qualname = {app.name}

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_exc_logger]
level = ERROR
handlers = exc_handler
qualname = exc_logger

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[handler_exc_handler]
class = handlers.SMTPHandler
args = (('localhost', 25), '{app.name}@{env.host}', ['{config.ERROR_EMAIL}'], '{app.name} Exception')
level = ERROR
formatter = exc_formatter

[formatter_generic]
format = %%(asctime)s %%(levelname)-5.5s [%%(name)s][%%(threadName)s] %%(message)s

[formatter_exc_formatter]
format = %%(asctime)s %%(message)s
"""

CONFIG_TEMPLATES = {
    'test': _CONFIG_TEMPLATE % """\
[filter:paste_prefix]
use = egg:PasteDeploy#prefix
prefix = /{app.name}

[pipeline:main]
pipeline =
    paste_prefix
    {app.name}
""",
    'production': _CONFIG_TEMPLATE % """\
[pipeline:main]
pipeline =
    {app.name}
""",
}


def install_repos(name):
    sudo('pip install -e git+%s#egg=%s' % (config.repos(name), name))


def deploy(app, environment):
    template_variables = dict(
        app=app, env=env, config=config, gunicorn=app.bin('gunicorn_paster'))

    require.users.user(app.name, shell='/bin/bash')
    require.postgres.user(app.name, app.name)
    require.postgres.database(app.name, app.name)
    require.files.directory(app.venv, use_sudo=True)
    require.python.virtualenv(app.venv)
    require.files.directory(app.logs, use_sudo=True)

    with virtualenv(app.venv):
        require.python.package('gunicorn', use_sudo=True)
        install_repos('clld')
        install_repos(app.name)

    if False:  # recreate the db only if necessary!
        local('pg_dump -f /tmp/wold2.sql wold2')
        require.files.file('/tmp/wold2.sql', source="/tmp/wold2.sql")
        sudo('sudo -u wold2 psql -f /tmp/wold2.sql -d wold2')

    require.files.file(
        str(app.config),
        contents=CONFIG_TEMPLATES[environment].format(**template_variables),
        owner='root',
        group='root',
        use_sudo=True)

    require.files.file(
        str(app.supervisor),
        contents=SUPERVISOR_TEMPLATE.format(**template_variables),
        mode='644',
        owner='root',
        group='root',
        use_sudo=True)

    sudo('/etc/init.d/supervisor stop')
    sudo('/etc/init.d/supervisor start')
    time.sleep(2)
    res = run('curl http://localhost:%s/_ping' % app.port)
    assert json.loads(res)['status'] == 'ok'

    if environment == 'test':
        require.files.file(
            str(app.nginx_location),
            contents=LOCATION_TEMPLATE.format(**template_variables),
            owner='root',
            group='root',
            use_sudo=True)
    elif environment == 'production':
        require.files.file(
            str(app.nginx_site),
            contents=SITE_TEMPLATE.format(**template_variables),
            owner='root',
            group='root',
            use_sudo=True)

    service.reload('nginx')
