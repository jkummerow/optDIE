function [ T ] = getSTiefe(Material, Geometrie, psln, m, refH, varargin)
if isempty(varargin)
    K=0;
else
    K=varargin{1};
end

U = Geometrie.D * pi; %Umfang

alpha = Geometrie.alpha / 360 * 2 * pi; %Wendelwinkel in Rad
Wendel_L = Geometrie.H / sin(alpha); %Gesamtlänge der Wendel

WS_Dx = U / Geometrie.n / psln; %Segmentlänge x
WS_L = WS_Dx / cos(alpha);  %Segmentlänge
seg_y = tan(alpha)*U/Geometrie.n; %Länge bis zur nächsten Überlappung
ulp = round(Geometrie.H/seg_y); %Überlappung

V_0 = m * Material.v; %Anfangsvolumenstrom
VS = (1:ulp)*(V_0/psln/ulp);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Referenzdruck berechnen
refSE = CNodeSpalt;
refSE.eps = 1;
refSE.H = refH;
refSE.B = Geometrie.D*pi / Geometrie.n / psln;
refSE.L = 1e-3;
refSE.Mat = Material;
refSE.V = V_0 / psln;

refDP = refSE.delta_p;

TS=zeros(1,numel(VS)); %mem preallocation
for k=1:numel(VS)-1 %da am Austritt schon bekannt
    refSE.V = VS(k);

    lb_H = 0;
    ub_H = refH;
    for i=1:1000
        refSE.H = (lb_H + ub_H)/2;

        if refSE.delta_p < refDP
            ub_H = (lb_H + ub_H)/2;
        else
            lb_H = (lb_H + ub_H)/2;
        end

        if abs(refDP - refSE.delta_p)/refDP < 1e-6
            TS(k) = refSE.H;
            break
        end %if
    end %for i
end %for k

TS(end)=refH;
TS = TS .* linspace(1-K,1,numel(TS));


T_x = (repmat([1-1e-6 1+1e-6],1,ulp-1)+reshape(meshgrid(0:ulp-2,1:2),1,(ulp-1)*2))*seg_y;
T_x = [0 T_x Geometrie.H];
T_y = reshape(meshgrid(TS,1:2),1,numel(TS)*2);
T = interp1(T_x,T_y,linspace(0,Geometrie.H,100),'lin','extrap');
