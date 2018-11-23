# This contains our frontend; since it is a bit messy to use the @app.route
# decorator style when using application factories, all of our routes are
# inside blueprints. This is the front-facing blueprint.
#
# You can find out more about blueprints at
# http://flask.pocoo.org/docs/blueprints/

from flask import current_app, Blueprint, render_template, flash, redirect, request, url_for
from markupsafe import escape
from .db import get_db, get_dbcad
import matlab.engine
import numpy as np

# from .forms import SignupForm
# from .nav import nav

frontend = Blueprint('frontend', __name__)


# Our index-page just shows a quick explanation. Check out the template
# "templates/opt.html" documentation for more details.
@frontend.route('/opt_run/<opt_id>')
def opt(opt_id):
    db = get_db()
    dp = db.execute(
        'SELECT * '
        'FROM quality '
    ).fetchall()
    data = []
    for p in dp:
        d = db.execute(
            'SELECT * '
            'FROM data_spaltwendel WHERE Designpoint={}'.format(p[0])
        ).fetchall()
        names = d[0].keys()
        d2 = {}
        for name in names:
            d2[name] = [f[name] for f in d] # umsortieren nach
        data.append(d2)
    return render_template('opt.html', list=dp, data=data)


@frontend.route('/geometry')
def geo():
    db = get_db()
    geom = db.execute(
        'SELECT *'
        'FROM geometry'
    ).fetchall()
    return render_template('geometry.html', list=geom)


@frontend.route('/geometry/<geo_id>')
def geo_detail(geo_id):
    db = get_db()
    cad = get_dbcad(geo_id)
    geom = db.execute(
        'SELECT * '
        'FROM geometry WHERE id={}'.format(geo_id)
    ).fetchall()
    data = {'cad': cad}
    opt = db.execute(
        'SELECT * '
        'FROM opts WHERE geometry={}'.format(geo_id)
    )
    return render_template('geometry_details.html', item=geom[0], data=data, opt_runs=opt)

@frontend.route('/pd')
def pd_wizard():
    return render_template('pd_wizard.html')

@frontend.route('/dimensioning', methods=('GET', 'POST'))
def dim():
    wt = []
    st = []
    form = []
    vars = []
    if request.method == 'POST':
        form = request.form
        try:
            v0 = float(request.form['roh']) ** -1
            vs = v0
            car_A = float(request.form['car_A'])
            car_B = float(request.form['car_B'])
            car_C = float(request.form['car_C'])
            Ts = float(request.form['Ts']) + 273.15
            T0 = float(request.form['T0']) + 273.15
            H = float(request.form['H']) * 1e-3
            D = float(request.form['D']) * 1e-3
            n = float(request.form['n'])
            alpha = float(request.form['alpha'])
            R = float(request.form['wt_b']) * 1e-3 / 2
            T = float(request.form['T']) + 273.15
            m = float(request.form['m']) * (60**-2)
            psln = float(request.form['psln'])
            st_end = float(request.form['st_end']) * 1e-3
            vars = [v0, vs, car_A, car_B, car_C, Ts, T0, H, D, n, alpha, R, T, m, psln, st_end]
        except ValueError:
            print('Input error: Could not convert input value to float')

        if len(vars) > 0:
            if all([isinstance(i, float) for i in vars]):
                print(vars)
                [wt, st] = vw_dim(v0, vs, car_A, car_B, car_C, Ts, T0, H, D, n, alpha, R, T, m, psln, st_end)
            else:
                print('Input error: Could not convert input value to float')

        # [wt, st] = [[[20.2602076386,40.5204152772,60.7806229158,81.0408305544,101.301038193,121.561245832,141.82145347,162.081661109,182.341868747,202.602076386,222.862284025,243.122491663,263.382699302,283.64290694,303.903114579,324.163322218,344.423529856,364.683737495,384.943945134,405.204152772,425.464360411,445.724568049,465.984775688,486.244983327,506.505190965,526.765398604,547.025606242,567.285813881,587.54602152,607.806229158,628.066436797,648.326644435,668.586852074,688.847059713,705.891938499], [7.8669982790488575, 8.002450002350088, 8.077406978300132, 8.102460271067685, 8.087334719501087, 8.040886297734687, 7.971109489109949, 7.885126779176062, 7.789197459991556, 7.688713560404722, 7.588200544327265, 7.491316340194317, 7.400854185136268, 7.318738793372177, 7.246031346177915, 7.1829211305011995, 7.128736250509974, 7.081936697126366, 7.040113853930961, 6.999994772137143, 6.95743905386189, 6.9074405045830645, 6.844124493654817, 6.760753420589026, 6.6497171623050235, 6.502546406816691, 6.3099007158889435, 6.0615737534244545, 5.74649350711843, 5.352721078845207, 4.867451383848675, 4.277011941652745, 3.5668654807377607, 2.7216075394535437, 1.8939318979391828]], [[0.0,10.3793103448,20.7586206897,31.1379310345,41.5172413793,51.8965517241,62.275862069,72.6551724138,83.0344827586,93.4137931034,103.793103448,114.172413793,124.551724138,134.931034483,145.310344828,155.689655172,166.068965517,176.448275862,186.827586207,197.206896552,207.586206897,217.965517241,228.344827586,238.724137931,249.103448276,259.482758621,269.862068966,280.24137931,290.620689655,301.0], [1.26145329167,1.25950632945,1.2643920273,1.29161392999,1.35583965074,1.43392413114,1.48186255123,1.51116698338,1.55031095616,1.59934095446,1.63136311002,1.65189456287,1.68056836964,1.71902928911,1.74562485293,1.76232202075,1.78487172932,1.81664570728,1.83924369881,1.85111131556,1.86522474156,1.89024229971,1.91462963431,1.92902608445,1.94266325104,1.96495876852,1.98782668634,1.99944589184,2.00264472302,2.00293672225]]]
    return  render_template('dimensioning.html', form=form, results=[wt, st])


def vw_dim(v0, vs, car_A, car_B, car_C, Ts, T0, H, D, n, alpha, R, T, m, psln, st_end):
    # calls the predimensioning algorithm written in matlab. Ensure that matlab for python api is installed
    # matlab needs float as input
    args = [float(i) for i in [v0, vs, car_A, car_B, car_C, Ts, T0, H, D, n, alpha, R, T, m, psln, st_end]]
    # start matlab
    mtlb_eng = matlab.engine.start_matlab()
    # change to subdir
    mtlb_eng.cd(current_app.config['MATLAB'])
    # matlab call
    mtlb_ret = mtlb_eng.wv_dim(*args, nargout=4)
    # close matlab session
    mtlb_eng.quit()
    # rearrange results to make sense
    wt = [ [i for i in mtlb_ret[0][0]], [i[0] for i in mtlb_ret[1]]]
    st = [ [i for i in mtlb_ret[2][0]], [i for i in mtlb_ret[3][0]] ]
    return [wt, st]