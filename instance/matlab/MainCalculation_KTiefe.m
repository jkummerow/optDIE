function [ Wendel, StegSteg, StegEnde, cor ] = MainCalculation_KTiefe(Geometrie,Material,m,psln)
Wtype=0;
V_0 = m * Material.v;

U = Geometrie.D * pi; %Umfang

alpha = Geometrie.alpha / 360 * 2 * pi; %Wendelwinkel in Rad
Wendel_L = Geometrie.H / sin(alpha); %Gesamtlänge der Wendel

WS_Dx = U / Geometrie.n / psln; %Segmentlänge x
WS_L = WS_Dx / cos(alpha);  %Segmentlänge

V_L0 = V_0 * WS_L / Wendel_L;

% Netzwerk aufbauen
[Wendel,StegSteg,StegEnde] = CreateNet3(Material, psln, V_0, Wtype, Geometrie);
SegNrs = size(Wendel,2) + size(StegSteg,2) + size(StegEnde,2);
% AllNodes = [Wendel StegSteg StegEnde];
NrSpNodes = size(StegSteg,2)+size(StegEnde,2);

% Strom/Spannungsvektoren initialisiren
i_0 = vertcat( ones(size(Wendel,2),1).*-V_0, zeros(SegNrs-size(Wendel,2),1) );
u_0 = zeros(SegNrs,1); % keine Zweigspannungsquellen!

% B-Matrix initialisieren
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

% Idealen Spaltvolumenstrom V_S berechnen
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
B_c(end,end+[1:numel(dP_W_sm)-size(B_c,2)]) = ones(1,numel(dP_W_sm)-size(B_c,2));
cor = abs((B_c*dP_W)./(B_c*dP_W_sm));
dP_W_sm_c=interp1(linspace(1,numel(dP_W_sm),numel(cor)),cor,1:numel(dP_W_sm),'lin','extrap')'.*dP_W_sm;
% dP_W_sm_c = dP_W_sm;

% Anhand des Druckverlustes Tiefe jedes Wendelsegementes bestimmen und in
% Objekt schreiben
for k=1:numel(Wendel)
    Wendel(k).H = 0.1e-3; %Startwert
    if dP_W_sm_c(k) == 0; break; end; %error handling für nulldruckverlust aufgrund der angepassten netzgeometrie
    
    % Tiefe um 1 mm erhöhen, bis Druckverlust geringer als Sollwert
    while Wendel(k).delta_p > dP_W_sm_c(k) 
        Wendel(k).H = Wendel(k).H + 1e-3;
    end
    
    % auf 1e-3% genaue Tiefe mit Binäre Suche finden
    lb_H = Wendel(k).H -1e-3; % lower bound
    ub_H = Wendel(k).H; % uppper bound
    for i=1:1000
        Wendel(k).H = (lb_H + ub_H)/2;

        if Wendel(k).delta_p < dP_W_sm_c(k)
            ub_H = (lb_H + ub_H)/2;
        else
            lb_H = (lb_H + ub_H)/2;
        end

        if abs(dP_W_sm_c(k) - Wendel(k).delta_p) < 1e-6 % gesuchte Genauigkeit erreicht
            break
        end %if
    end %for i
end %for k

% Schreibt Drücke zur Kontrolle in Workspace
% assignin('base','dP_W', dP_W);
% assignin('base','dP_W_sm', dP_W_sm);
% assignin('base','dP_W_sm_c',dP_W_sm_c);
% assignin('base','dP_S', dP_S);
% assignin('base', 'WV_Geo', Geometrie);
