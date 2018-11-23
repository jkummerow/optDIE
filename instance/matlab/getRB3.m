function [ output ] = getRB3( input, input_type, Geometrie, Material, psln, st_end )
%getRB berechnet aus Geometrie Randgrößen
%   erwartet folgende Parameter:
%       input (double):         array mit zugeordneten Randbedingungen (RB)
%       input_type (int):       legt den RB-typ von input fest
%       Geometrie (CGeometrie): Geometrieobjekt
%       Material (CMaterial):   Materialobjekt
%       psln (int):             Elementdichte
%       st_end (double):        Endspalt für Korrektur
%   gibt folgende Rückgaben:
%       output (Cell):          Cellarray enthält Widerstandsobjekte von
%                               Anfangswendel -und spalt sowie Endspalt mit
%                               der Normlänge von 1 mm

%% Korrekturwert berechnen

% Genauen Druckverlust berechnen
ST_id = getSTiefe(Material, Geometrie, psln, Material.m, st_end)*1e3;
%Spalttiefenverlauf glätten
[xData, yData] = prepareCurveData( [], ST_id );
% Set up fittype and options.
ft = fittype( 'smoothingspline' );
opts = fitoptions( 'Method', 'SmoothingSpline' );
opts.SmoothingParam = 0.01;
% Fit model to data.
[fitresult, ~] = fit( xData, yData, ft, opts );
ST_sm = ppval(fitresult.p,linspace(1,100,30));
Geometrie.STiefe = ST_sm;
iDP = get_idealdp(Geometrie,Material,psln);

% Genäherten Druckverlust berechnen
nDP = createRWE( st_end, 1, Geometrie, Material, psln );

% Korrekturwert
cor = iDP{1}.delta_p / iDP{1}.L*1e-3 / nDP{1}{1}.delta_p;

%% Berechnung mit Korrektur durchführen
output = createRWE( input, input_type, Geometrie, Material, psln, cor );
end

function [ output ] = createRWE( input, input_type, Geometrie, Material, psln, varargin )
%createRWE erzeugt aus Geometrie und Randgrößen Widerstandselemente am
%Wendelanfang, Anfangsspalt und Endspalt

%   erwartet folgende Parameter:
%       input (double):         array mit zugeordneten Randbedingungen (RB)
%       input_type (int):       legt den RB-typ von input fest
%       Geometrie (CGeometrie): Geometrieobjekt
%       Material (CMaterial):   Materialobjekt
%       psln (int):             Elementdichte
%       cor (double):           Korrekturwert (varargin(1))
%   gibt folgende Rückgaben:
%       output (Cell):          Cellarray enthält Widerstandsobjekte von
%                               Anfangswendel -und spalt sowie Endspalt mit
%                               der Normlänge von 1 mm
%% init
if nargin == 6
    cor = varargin{1};
else
    cor = 1;
end

%% Volumenstrom berechnen
m = Material.m;
ubl = Geometrie.H*Geometrie.n ./ (Geometrie.D*pi*tand(Geometrie.alpha)); % Überlappung
V_0 = m * Material.v;

%% Initialisiere Widerstandsobjekte
AW = CNodeKanal; % Anfangswendel
AS = CNodeSpalt; % Anfangsspalt
ES = CNodeSpalt; % Endspalt

AW.R = Geometrie.R;
AW.V = V_0*(1 - 1/psln/ubl);
AS.eps = 1; ES.eps = 1;
AS.B = Geometrie.D*pi / Geometrie.n / psln; ES.B = Geometrie.D*pi / Geometrie.n / psln;
AS.V = V_0/psln/ubl;
ES.V = V_0/psln;

for tt = {AW AS ES}
tt{1}.L = 1e-3; %#ok<FXSET> % Normlänge 1 mm
tt{1}.Mat = Material; %#ok<FXSET>
end
%% Typ festlegen
switch input_type
    case 1
        %% Enspalt
        ref_Obj = ES;
        ref_cond = @(in)diff([ES.H,in]);
        ref_abh = 1; %abhängigkeit zielgröße von Höhe: 1 = prop., 0 = rezipr.
        res_Obj = {AW, AS};
    case 2
        %% Anfangsspalt
        ref_Obj = AS;
        ref_cond = @(in)diff([AS.H,in]);
        ref_abh = 1; %abhängigkeit zielgröße von Höhe: 1 = prop., 0 = rezipr.
        res_Obj = {AW, ES};
    case 3
        %% Anfangswendeltiefe
        ref_Obj = AW;
        ref_cond = @(in)diff([AW.H,in]);
        ref_abh = 1; %abhängigkeit zielgröße von Höhe: 1 = prop., 0 = rezipr.
        res_Obj = {AS, ES};
    case 4
        %% Gesamtdruckverlust
        ref_Obj = ES;
        ref_cond = @(in)diff([ES.delta_p*Geometrie.H*1e3,in]);
        ref_abh = 0; %abhängigkeit zielgröße von Höhe: 1 = prop., 0 = rezipr.
        res_Obj = {AW, AS};
    case 5
        %% Schergeschwindigkeit Wendel
        ref_Obj = AW;
        ref_cond = @(in)diff([AW.gamma,in]);
        ref_abh = 0; %abhängigkeit zielgröße von Höhe: 1 = prop., 0 = rezipr.
        res_Obj = {AS, ES};
    case 6
        %% Schergeschwindigkeit Spalt
        ref_Obj = AS;
        ref_cond = @(in)diff([AS.gamma,in]);
        ref_abh = 0; %abhängigkeit zielgröße von Höhe: 1 = prop., 0 = rezipr.
        res_Obj = {AW, ES};
    otherwise
        %% error
end %switch

%% Berechnungsschleife
output = {};
for sinp = input
    % Höhe des Referenzobjekts finden
    lb = 1e-6;
    ub = 1000;
    ref_Obj.H = lb + (ub-lb)/2;
    while abs(ref_cond(sinp)) > sinp*1e-3
        ref_Obj.H = lb + (ub-lb)/2;
        if (ref_cond(sinp) < 0) == ref_abh
            ub = ref_Obj.H;
        else
            lb = ref_Obj.H;
        end
    end
    ref_DP = ref_Obj.delta_p;
    for sres_obj_c = res_Obj
        sres_obj = sres_obj_c{1};
        % Höhe des Ergebnisobjekts finden
        lb = 1e-6;
        ub = 1e3;
        sres_obj.H = lb + (ub-lb)/2;
        while abs(diffDP(sres_obj)) > ref_DP*1e-3
            sres_obj.H = lb + (ub-lb)/2;
            if diffDP(sres_obj) < 0
                ub = sres_obj.H;
            else
                lb = sres_obj.H;
            end
        end      
    end
    output = [output {copyCellObj({AW AS ES})}]; %#ok<AGROW>
end % for
        
%% Nested Functions
    function out = copyCellObj(cell)
    %kopiert cell-objekte
        out = {};
        for obj=cell
            out = [out, {obj{1}.copy}]; %#ok<AGROW>
        end
    end %function copyCellObj

    function out = diffDP(obj)
    %Berechnet Druckdifferenz zum Referenzobjekt.
    %Berechnet für die Wendel den Druckverlust anhand der Situation am
    %WV-Austritt: Druckdifferenz zwischen den ersten beiden StegElementen
    %infolge der Längendifferenz. Unter Annahme gleichen Volumenstroms ist
    %dieser dann gleich dP_Wendel(1).
    %Dieser wird dann auf WE von 1mm Länge umgerechnet und mit einem
    %Korrekturwert versehen
    
        if isa(ref_Obj,'CNodeSpalt')
            if isa(obj,'CNodeKanal')
                t_obj = ref_Obj.copy;
                t_obj.L = Geometrie.D*pi / Geometrie.n / psln * tand(Geometrie.alpha);
                refW_DP = t_obj.delta_p/(Geometrie.D*pi / Geometrie.n / psln)*1e-3*cor;
                out = diff([refW_DP, obj.delta_p]);
            else
                out = diff([ref_DP, obj.delta_p]);
            end
        else
            if isa(obj,'CNodeSpalt')
                t_obj = obj.copy;
                t_obj.L = Geometrie.D*pi / Geometrie.n / psln * tand(Geometrie.alpha);
                refW_DP = t_obj.delta_p/(Geometrie.D*pi / Geometrie.n / psln)*1e-3*cor;
                out = diff([ref_DP, refW_DP]);
            else
                out = diff([ref_DP, obj.delta_p]);
            end
        end
    end %function diffDP

end

function [idealdp] = get_idealdp(Geometrie,Material,psln)
%get_idealdp erzeugt aus Geometrie und Randgrößen Widerstandselemente am
%Wendelanfang, Anfangsspalt und Endspalt durch aufstellen des gesamten
%Widerstandsnetzes und lösen der Systemmatrix

%   erwartet folgende Parameter:
%       Geometrie (CGeometrie): Geometrieobjekt
%       Material (CMaterial):   Materialobjekt
%       psln (int):             Elementdichte
%   gibt folgende Rückgaben:
%       output (Cell):          Cellarray enthält Widerstandsobjekte von
%                               Anfangswendel -und spalt sowie Endspalt mit
%                               der wahren Länge

Wtype=0;
V_0 = Material.m * Material.v;

U = Geometrie.D * pi; %Umfang

alpha = Geometrie.alpha / 360 * 2 * pi; %Wendelwinkel in Rad
Wendel_L = Geometrie.H / sin(alpha); %Gesamtlänge der Wendel

WS_Dx = U / Geometrie.n / psln; %Segmentlänge x
WS_L = WS_Dx / cos(alpha);  %Segmentlänge

V_L0 = V_0 * WS_L / Wendel_L;

%% Netzwerk aufbauen
[Wendel,StegSteg,StegEnde] = CreateNet3(Material, psln, V_0, Wtype, Geometrie);
SegNrs = size(Wendel,2) + size(StegSteg,2) + size(StegEnde,2);
% AllNodes = [Wendel StegSteg StegEnde];
NrSpNodes = size(StegSteg,2)+size(StegEnde,2);

% % Strom/Spannungsvektoren initialisiren
% i_0 = vertcat( ones(size(Wendel,2),1).*-V_0, zeros(SegNrs-size(Wendel,2),1) );
% u_0 = zeros(SegNrs,1); % keine Zweigspannungsquellen!

%% B-Matrix initialisieren
B = diag(-ones(NrSpNodes,1));
for i = 1:psln-1
    B = B + diag(-ones(NrSpNodes-i,1),i);
end %for i
for i = 1:size(Wendel,2)-NrSpNodes
    B_im = B(:,end);
    B = [B B_im]; %#ok<AGROW>
end
B = [B diag(ones(NrSpNodes,1))];
% B = sparse(B); %Umwandlung in sparse-mode. Optimierung erforderlich

%% Idealen Spaltvolumenstrom V_S berechnen
V_S = repmat(1:ceil(Geometrie.H/tan(alpha)/(U/Geometrie.n)),psln,1); %erstellt Matrix mit 1:Überlappung in der Zeile und epsilon Zeilen
V_S = reshape(V_S,numel(V_S),1)*V_L0; %formt Matrix um, sodass jede Spalte untereinander in einem Vektor steht
V_S = V_S(1:(size(StegSteg,2)+size(StegEnde,2))); %kürzt die Matrix auf Anzahl an Stegelementen

% idealen Spaltvolumenstrom in Stegelemente schreiben
for i = 1:size(V_S,1)
    if i <= size(StegSteg,2)
        objN = StegSteg(i);
    else
        objN = StegEnde(i-size(StegSteg,2));
    end %if
    objN.V = V_S(i);
end %for i

%% Druckverlust berechnen
% Druckverlust Spalt auslesen + B in Wendel+Spaltanteil zerlegen
dP_S = [StegSteg.delta_p StegEnde.delta_p]';
B_W = B(1:end,1:size(Wendel,2));
B_S = B(1:end,size(Wendel,2)+1:end); %#ok<NASGU> % nicht benötigt, da Einheitsmatrix = keine Änderung bei Multiplikation!

% Berechne Druckverlust Wendel
dP_W = -B_W\dP_S;

% Fitte Druckverlust durch Glättungsspline
[xData, yData] = prepareCurveData( [], dP_W );
ft = fittype( 'smoothingspline' );
opts = fitoptions( 'Method', 'SmoothingSpline' );
opts.SmoothingParam = 0.10; %Glättungsgrad des Splins
opts.Exclude = excludedata( xData, yData, 'range', [500 Inf] ); % alle Datenpunkte nahe und unter Nulllinie löschen
[fitresult, ~] = fit( xData, yData, ft, opts );
dP_W_sm = abs(ppval(fitresult.p,xData)); % Spline auswerten, abs nötig, da auf keinen fall neg. Werte!

% Korrigiere Geglätteten Druckverlust
B_c = ones(1,psln);
for i=2:floor(Geometrie.H/tan(alpha)/(U/Geometrie.n)) % bis Überlappung, abgerundet
    B_c = blkdiag(B_c,ones(1,psln));
end
B_c(end,end+(1:numel(dP_W_sm)-size(B_c,2)) ) = ones(1,numel(dP_W_sm)-size(B_c,2));
cor = abs((B_c*dP_W)./(B_c*dP_W_sm));
dP_W_sm_c=interp1(linspace(1,numel(dP_W_sm),numel(cor)),cor,1:numel(dP_W_sm),'lin','extrap')'.*dP_W_sm;


%% Wendeltiefe des 1. Elements finden
Wendel(1).H = 0.1e-3; %Startwert

% Tiefe um 1 mm erhöhen, bis Druckverlust geringer als Sollwert
while Wendel(1).delta_p > dP_W_sm_c(1) 
    Wendel(1).H = Wendel(1).H + 1e-3;
end

% auf 1e-3% genaue Tiefe mit Binäre Suche finden
lb_H = Wendel(1).H -1e-3; % lower bound
ub_H = Wendel(1).H; % uppper bound
for i=1:1000
    Wendel(1).H = (lb_H + ub_H)/2;

    if Wendel(1).delta_p < dP_W_sm_c(1)
        ub_H = (lb_H + ub_H)/2;
    else
        lb_H = (lb_H + ub_H)/2;
    end

    if abs(dP_W_sm_c(1) - Wendel(1).delta_p) < 1e-6 % gesuchte Genauigkeit erreicht
        break
    end %if
end %for i

idealdp = { Wendel(1) StegSteg(1) StegEnde(mod(numel(StegSteg),psln)+1) };
end