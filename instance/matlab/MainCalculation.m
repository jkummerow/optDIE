function [ V, Wendel, StegSteg, StegEnde ] = MainCalculation(Geometrie,Material,m,psln)
%% MainCalculation Funktion zur Berechnung der Volumenstromverteilung
%   Diese Funktion berechnet den Volumenstrom in Wendel und Spalt eines
%   Wendelverteilers (VW) aus den übergebenen Geometrieparametern und gibt
%   sie als Vektor zurück. Ferner wird das aufgestellte Berechnungsnetz
%   ebenfalls zurückgegeben.
% 
%   fordert die folgenden Eingabeparameter:
%       Geometrie:  Typ CGeometrie. Enthält Geometrie des WV
%       Material:   Typ CMaterial. Enthält Materialkennwerte
%       m:          Typ double. Massenstrom durch den WV-Abschnitt in
%                               [m^3/s]
%       psln:       Typ double. Netzauflösung epsilon
% 
%   Autor: Jan Wilfried Kummerow
%   Letzte Änderung: 06.04.2014

Wtype=0;
V_0 = m * Material.v;
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
B = sparse(B); %Umwandlung in sparse-mode. Optimierung erforderlich

% Schwellwert festlegen
lambda = V_0 / size(Wendel,2) / 1000; %promille-Bereich

% Hauptschleife, läuft bis Schwellwert unterschritten wird
for j = 1:1000
    V_tmp = 0;
    % Widerstandsmatrix abfragen
    K = [Wendel.K StegSteg.K StegEnde.K]';
    R = spdiags(K,0,size(K,1),size(K,1));

    Z = B*R * B.';
    u_q = -B * sparse(u_0) + B*R * sparse(i_0);
    
    % Gleichungssystem lösen
    V_j = Z \ u_q;
    
    % V zurückrechnen
    V = B.' * full(V_j);
    V = V - i_0;
    
    % neue V-Werte in objekte schreiben, Schwellwert schreiben
    for i = 1:size(V,1)
        if i <= size(Wendel,2)
            objN = Wendel(i);
        elseif i <= size(Wendel,2)+size(StegSteg,2)
            objN = StegSteg(i-size(Wendel,2));
        else
            objN = StegEnde(i-(size(Wendel,2)+size(StegSteg,2)));
        end %if
        if V_tmp < abs(objN.V - V(i))
            V_tmp = abs(objN.V - V(i));
        end %if
        objN.V = V(i);
    end %for i
    % Schwellwert unterschitten?
    if V_tmp < lambda
        break;
    end %if
end %for j