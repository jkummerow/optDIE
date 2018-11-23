function [WL, WT, SL, ST] = wv_dim( v0, vs, car_A, car_B, car_C, Ts, T0, H, D, n, alpha, R, T, m, psln, st_end )
% wv_dim
%   Wrapper-Function für das Vorauslgungswerkzeug für Wendelverteiler
%   Liest alle Daten ein, startet die Berechnung
%   Rückgabe ist S, ein obj welches alle Eingabe und Rückgabewerte
%   speichert

% Materialobjekt
S.material = CMaterial;
% Geometrieobjekt
S.geometrie = CGeometrie;

S.material.v0 = v0;
S.material.vs = vs;
S.material.A = car_A;
S.material.B = car_B;
S.material.C = car_C;
S.material.Ts = Ts;
S.material.T0 = T0;

S.geometrie.H = H;
S.geometrie.D = D;

S.geometrie.n = n;
S.geometrie.alpha = alpha;
S.geometrie.R = R;


% Betriebspunkt-Parameter einlesen
S.material.T = T;
S.material.m = m;

% Rechnungsparameter einlesen
% psln = psln;

% Randbedingungen einlesen
% st_end = st_end;

% To-Do: Prüfung S.material
% To-Do: Prüfung S.geometrie

% Idealen Spalttiefenverlauf berechnen
S.ST_id = getSTiefe(S.material, S.geometrie, psln, S.material.m, st_end)*1e3;
%Spalttiefenverlauf glätten
S.ST_sm = sm_ST(S.ST_id);
% Geglätteten Verlauf in Objekt schreiben
S.geometrie.STiefe = S.ST_sm;

% Erste Näherung Wendeltiefenverlauf
S.geometrie.KTiefe = linspace(S.geometrie.R*2.5*1e3,0.01,5);

% idealen Wendeltiefenverlauf berechnen
[ S.Wendel, S.StegSteg, S.StegEnde ] = MainCalculation_KTiefe(S.geometrie, S.material, S.material.m, psln);
S.WT = [S.Wendel.H]*1e3;
S.WL = cumsum([S.Wendel.L])*1e3;

% ToDo: Loop für WT-Grenzwert-Rechnung

% Ergebnis plotten

%Wendeltiefenverlauf glätten
[xData, yData] = prepareCurveData( S.WL, S.WT );
% Set up fittype and options.
ft = fittype( 'fourier2' );
opts = fitoptions( 'fourier2' );
% Fit model to data.
[S.fitresult_wl, ~] = fit( xData, yData, ft, opts );
S.WT_sm = feval(S.fitresult_wl,linspace(0,sum([S.Wendel(1:end).L])*1e3,30));


% Anzeige Tiefenverlauf
% plot(S.fitresult_wl,S.WL,S.WT);
% title(S.df.ax(1),'Wendeltiefe');
% xlabel(S.df.ax(1),'Wendellänge [mm]');
% ylabel(S.df.ax(1),'Wendeltiefe [mm]');
% 
% assignin('base', 'WV_S', S);


% S.WL,feval(S.fitresult_wl,S.WL)
% S.WT_sm;
WL = S.WL;
WT = feval(S.fitresult_wl,S.WL);
SL = linspace(0,S.geometrie.H*1e3,30);
ST = S.ST_sm;

%% Nested functions
function ST_sm = sm_ST(ST_id)
        %Spalttiefenverlauf glätten
        [xData, yData] = prepareCurveData( [], ST_id );
        % Set up fittype and options.
        ft = fittype( 'smoothingspline' );
        opts = fitoptions( 'Method', 'SmoothingSpline' );
        opts.SmoothingParam = 0.01;
        % Fit model to data.
        [fitresult, ~] = fit( xData, yData, ft, opts );
        ST_sm = ppval(fitresult.p,linspace(1,100,30));
end %function sm_ST
end

