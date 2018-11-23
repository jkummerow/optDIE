function [ objWendel, objStegSteg, objStegEnde ] = CreateNet3( Material, psln, V_0, Wtype, Geometrie )
%% CREATENET Funktion zur Erzeugung des Berechnungsnetzwerks
%   Diese Funktion erzeugt aus den übergeben Geometrieparametern des
%   Wendelverteilers (VW) das Berechnungsnetzwerk und füllt alle Segmente
%   mit den nötigen Materialdaten. Gibt das Netz als drei einzelne Arrays
%   zurück
% 
%   fordert die folgenden Eingabeparameter:
%       Material:   Typ CMaterial. Enthält Materialkennwerte
%       psln:       Typ double. Netzauflösung epsilon
%       V_0:        Typ double. Anfangs-Volumenstrom
%       Wtype:      Typ double. Form der Ersatzgeometrie. Auf 0 belassen
%       Geometrie:  Typ CGeometrie. Enthält Geometrie des WV
%
%   gibt die folgenden Rückgabeparameter aus:
%       objWendel:      Typ CNodeKanal. Array mit allen Wendelsegmenten
%       objStegSteg:    Typ CNodeSpalt. Arry mit allen Steg-zu-Steg-Segmenten
%       objStegEnde:    Typ CNodeSpalt. Array mit allen Steg-zu-VW-Ende-Segmenten
%       
%   Autor: Jan Wilfried Kummerow
%   Letzte Änderung: 05.04.2014


%% Geometrieparameter einlesen/zuweisen
% Kanal- Spalttiefenverlauf
Kanaltiefe = Geometrie.KTiefe;
Spalttiefe = Geometrie.STiefe;

% Grundlegende geom. Größen des WV
D = Geometrie.D; %Durchmesser
U = D * pi; %Umfang
n = Geometrie.n; %Wendelzahl
H = Geometrie.H; %Baulänge

alpha = Geometrie.alpha / 360 * 2 * pi; %Wendelwinkel in Rad
Wendel_L = H / sin(alpha); %Gesamtlänge der Wendel

% Segmentgrößen
WS_Dx = U / n / psln; %Segmentlänge x
WS_L = WS_Dx / cos(alpha);  %Segmentlänge
WS_Dy = tan(alpha) * WS_Dx; %Segmentlänge y

WS_b = Geometrie.Wb; %Kanalbreite

SS_L_mit = tan(alpha) * U / n; %Steglänge über L const. ohne Wendelbreite

%% WENDEL
ID=1;
WS_ges = ceil(Wendel_L/WS_L); %Anzahl an Wendelsegmenten
objWS(WS_ges) = CNodeKanal; %Array initialisieren
for i=1:WS_ges
    objWS(i).ID = i;
    
    % Ersatzquerschnitt = Wappen
    objWS(i).WALtype = Wtype;
    % Material-Daten übertragen
    objWS(i).Mat = Material;
    % Vorläufiger Volumenstrom (linear von 100% auf 0% von V_0)
    objWS(i).V = interp1([1 WS_ges],[V_0 0],i,'linear');
    % Fräserradius
    objWS(i).R = WS_b/2;
    
    % Ausnahme für letztes Wendelsegment abfangen
    if i ~= WS_ges
        % Länge für normales Segment
        objWS(i).L = WS_L;
    else
        % korrigierte Länge für letztes Segment
        objWS(i).L = Wendel_L - (WS_L*(i-1));
    end %if
    % Wendeltiefe setzten
    objWS(i).H = Wendeltiefe(sum([objWS(1:i).L])-objWS(i).L/2);
    
    
    ID=ID+1;
end %for
%end WENDEL

%% STEGENDE
SE_ges = psln; %Anzahl an Steg zu Ende-Segmenten
objSE(SE_ges) = CNodeSpalt; %Array initialisieren

%Suche nach SE-Elementen, die zu kurz wären
i = psln;
NrCrSE = 0;
while sum([objWS(end-SE_ges+i:end).L])*sin(alpha)-(objWS(end-SE_ges+i).B*tan(alpha)/2) < 0 || ...
     (sum([objWS(end-SE_ges+i:end).L])*sin(alpha)-(objWS(end-SE_ges+i).B*tan(alpha)/2) < 1e-3 && ...
     abs( sum([objWS(end-SE_ges+i-1:end).L])*sin(alpha)-objWS(end-SE_ges+i-1).B*tan(alpha)/2 - ( sum([objWS(end-SE_ges+i:end).L])*sin(alpha)-(objWS(end-SE_ges+i).B*tan(alpha)/2) ) )/(sum([objWS(end-SE_ges+i-1:end).L])*sin(alpha)-(objWS(end-SE_ges+i-1).B*tan(alpha)/2)) > 0.5)
    NrCrSE = NrCrSE + 1;
    i = i - 1;
end

% Erzeuge SE-Elemente
for i=1:SE_ges
    objSE(i).ID = ID;
    
    % Material-Daten übertragen
    objSE(i).Mat = Material;
    % Vorläufiger Volumenstrom
    objSE(i).V = V_0/psln;
    % Breite konst. setzen
    objSE(i).B = WS_Dx;
    % Länge abhängig von y-Position setzen
    objSE(i).L = sum([objWS(end-SE_ges-NrCrSE+i:end).L])*sin(alpha)-(objWS(end-SE_ges-NrCrSE+i).B*tan(alpha)/2);
    % Innere Auflösung
    objSE(i).eps = floor(abs(objSE(i).L)/WS_L)+1; %innere Auflösung = Anzahl interner Elemente
    % Spalthöhe abhängig von y-Position
    objSE(i).H = Spalthoehe(H-objSE(i).L,objSE(i));
    
    
    ID=ID+1;
end %for

%end STEGENDE

%% STEGSTEG
SS_ges = WS_ges - SE_ges - NrCrSE; %Anzahl an Steg zu Steg-Segmenten, für NrCRSE siehe STEGENDE-Abschnitt
objSS(SS_ges) = CNodeSpalt; %Array initialisieren

% Erzeuge SS-Elemente (wie SE-Elemente)
for i=1:SS_ges
    objSS(i).ID = ID;
    
    objSS(i).eps = fix(SS_L_mit/WS_L);
    objSS(i).Mat = Material;
    objSS(i).V = V_0/WS_ges;
    
    objSS(i).B = WS_Dx;
    objSS(i).L = SS_L_mit-(objWS(i).B+objWS(i+psln).B)*tan(alpha)/2;
    objSS(i).H = Spalthoehe(i*WS_Dy+(objWS(i).B*tan(alpha)/2),objSS(i));
    ID=ID+1;
end %for

%end STEGSTEG



%% Return
objWendel = objWS;
objStegSteg = objSS;
objStegEnde = objSE;

%% Nested Functions
% Nested functions können auf Variablen der Hauptfunktion zurückgreifen.

function value = Wendeltiefe(x)
%% Gibt Wendeltiefe abhängig von der x'-Position zurück
    value = Wendelverlauf(x);
end %function Wendeltiefe

function value = Spalthoehe(y,obj)
%% Gibt Spaltbreite abhängig von der Y-Position zurück
% fordert y und Spaltobjekt
    o_psln = obj.eps;
    L = obj.L;
    value = zeros(o_psln,1);
    for i_f=1:o_psln % Schleife durch alle internen Segmente
        value(i_f) = Spaltverlauf(y+L/o_psln*i_f);
    end %for i
end %function Spalthoehe

function value = Wendelverlauf(x)
%% Gibt Kanalhöhe an Position x aus
    value = interp1(linspace(0,Wendel_L*10^3,numel(Kanaltiefe)),Kanaltiefe,x*10^3,'linear','extrap')*10^-3; 
end% function Wendelverlauf

function value = Spaltverlauf(x)
%% Gibt Spalttiefe an Position x aus
    value = interp1(linspace(0,H*10^3,numel(Spalttiefe)),Spalttiefe,x*10^3,'linear','extrap')*10^-3; 
end %function Spaltverlauf

end %function CreateNet