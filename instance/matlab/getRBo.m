function [ output ] = getRBo( input, input_type, Geometrie, Material, psln, varargin )
%getRB berechnet aus Geometrie Randgrößen
%   erwartet folgende Parameter:
%       input (double):         array mit zugeordneten Randbedingungen (RB)
%       input_type (int):       legt den RB-typ von input fest
%       Geometrie (CGeometrie): Geometrieobjekt
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
tt{1}.L = 1e-3; % Normlänge 1 mm
tt{1}.Mat = Material;
end
%% Typ festlegen
switch input_type
    case 1
        %% Enspalt
        ref_Obj = ES;
        ref_cond = @(in)diff([ES.H,in]);
        ref_abh = 1; %abhängigkeit zielgröße von Höhe: 1 = prop., 0 = rezipr.
        res_Obj = {AW, AS};
        res_cond = @(in)diff([ES.delta_p,in]);
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
        while abs(diff([ref_DP,get_delta_p_aeq(sres_obj)])) > ref_DP*1e-3
            sres_obj.H = lb + (ub-lb)/2;
            if diff([ref_DP,get_delta_p_aeq(sres_obj)]) < 0
                ub = sres_obj.H;
            else
                lb = sres_obj.H;
            end
        end      
    end
    output = [output {copyCellObj({AW AS ES})}];
end % for
        
%% Nested Functions
    function out = copyCellObj(cell)
        out = {};
        for obj=cell
            out = [out, {obj{1}.copy}];
        end
    end
    function out = get_delta_p_aeq(obj)
        if isa(obj,'CNodeKanal')
            out = obj.delta_p * cor; % * 2.79335735657704;
        else
            out = obj.delta_p;
        end
    end
end

