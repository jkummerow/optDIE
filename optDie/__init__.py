# you can actually run the application with
#   $ flask --app=sample_app dev
# Afterwards, point your browser to http://localhost:5000

import os

from flask import Flask
from flask_appconfig import AppConfig
from flask_bootstrap import Bootstrap
# navigation
from flask_nav import register_renderer

# blueprints
from .frontend import frontend
from .nav import nav
from .nav_renderer import BootstrapRendererEnh, BootstrapRendererSidebar


def create_app(configfile=None):
    # We are using the "Application Factory"-pattern here, which is described
    # in detail inside the Flask docs:
    # http://flask.pocoo.org/docs/patterns/appfactories/

    app = Flask(__name__)

    # ensure the instance folder exists
    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass

    # We use Flask-Appconfig here, but this is not a requirement
    AppConfig(app)

    # Install our Bootstrap extension
    Bootstrap(app)

    # Our application uses blueprints as well; these go well with the
    # application factory. We already imported the blueprint, now we just need
    # to register it:
    app.register_blueprint(frontend)

    # Because we're security-conscious developers, we also hard-code disabling
    # the CDN support (this might become a default in later versions):
    app.config['BOOTSTRAP_SERVE_LOCAL'] = True

    app.config.from_mapping(
        SECRET_KEY='dev',
        DATABASE = os.path.join(app.instance_path, 'db.sqlite'),
        DB_CAD = os.path.join(app.instance_path, 'db', 'geometry'),
        MATLAB = os.path.join(app.instance_path, 'matlab')
    )

    # initialise navigation + renderer
    nav.init_app(app)
    register_renderer(app, 'bootstrap_class', BootstrapRendererEnh)
    register_renderer(app, 'bootstrap_sidebar', BootstrapRendererSidebar)

    from . import db
    db.init_app(app)

    return app
