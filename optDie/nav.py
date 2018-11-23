#!/usr/bin/env python
# -*- coding: utf-8 -*-
from flask_bootstrap import __version__ as FLASK_BOOTSTRAP_VERSION
from flask_nav import Nav
from flask_nav.elements import Navbar, View, Subgroup, Link, Text, Separator

from .nav_renderer import IconItem

# To keep things clean, we keep our Flask-Nav instance in here. We will define
# frontend-specific navbars in the respective frontend, but it is also possible
# to put share navigational items in here.

nav = Nav()

# We're adding a navbar as well through flask-navbar. In our example, the
# navbar has an usual amount of Link-Elements, more commonly you will have a
# lot more View instances.

nav.register_element('frontend_top', Navbar(
    View('OptDie', '.geo'),
    View('Werkzeuge', '.geo'),
    View('Material', '.geo'),
    View('Vordimensionierung', '.dim'),
    # View('Optimierung', '.opt'),
    Text('Suche'),
    # View('Debug-Info', 'debug.debug_root'),
    # Subgroup(
    #     'Docs',
    #     Link('Flask-Bootstrap', 'http://pythonhosted.org/Flask-Bootstrap'),
    #     Link('Flask-AppConfig', 'https://github.com/mbr/flask-appconfig'),
    #     Link('Flask-Debug', 'https://github.com/mbr/flask-debug'),
    #     Separator(),
    #     Text('Bootstrap'),
    #     Link('Getting started', 'http://getbootstrap.com/getting-started/'),
    #     Link('CSS', 'http://getbootstrap.com/css/'),
    #     Link('Components', 'http://getbootstrap.com/components/'),
    #     Link('Javascript', 'http://getbootstrap.com/javascript/'),
    #     Link('Customize', 'http://getbootstrap.com/customize/'), ),
    # Text('Using Flask-Bootstrap {}'.format(FLASK_BOOTSTRAP_VERSION)),
    ))

nav.register_element('frontend_side', Navbar(
    Text(''),
    View('Dashboard', '.index'),
    View('Orders', '.index'),
    View('Products', '.example_form'),
    View('Customers', '.index'), 
    IconItem('glyphicon glyphicon-home', Text('bar')), ))
