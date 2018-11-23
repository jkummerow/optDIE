classdef CNodeKanal < matlab.mixin.Copyable
%% Diese Klasse bildet ein Wendelelement ab
    % Material muss als Objekt übergeben werden
    
%% properties setzten
    properties
        ID % Eindeutige ID
        L% Geometrie
        Mat = CMaterial; % Material
        V % Volumenstrom
        T % Massetemperatur
        WALtype = 0; % Ersatzgeometrie
    end% properties
    properties (Dependent)
        H % Widerstandshöhe
        R % Fräserradius
    end %properties
    properties (Dependent = true, SetAccess = private, Hidden)
        m % Massenstrom
        fp % Strömungskoefizient
        
        K % Widerstandswert
        %R_ers
    end
    properties (Access = private)
        Bi
        Hi
        pH
        pR
        pB
    end
    properties (Dependent = true, SetAccess = private)
        B % Widerstandsbreite
        gamma % Schergeschwindigkeit
        eta % Dichte nach Carreau    
        delta_p % Druckverlust
        tau_w % Wandschubspannung
    end
%% methods
    methods
        %% Initialisierungsfunction
        function CNK = CNodeKanal(ID,H,R,L,Mat,V)
        %% CNodeKanal(ID,H,R,L,Mat,V)
            % Ließt alle benötigten Daten ein
            % nur H,B,L sowie V sollten danach noch eine Aktualisierung
            % benötigen
            if nargin > 0 % Support calling with 0 arguments
                % Werte in Objekt schreiben
                CNK.ID = ID;
                CNK.H = H;
                CNK.R = R;
                CNK.L = L;
                CNK.Mat = Mat;
                CNK.V = V;
            end% if
        end% CNodeKanal
        
        %% H
        function set.H(obj,value)
            obj.pH = abs(value);
            obj.setHB;
        end %function
        
        function value = get.H(obj)
            value = obj.pH;
        end %function

        %% R
        function set.R(obj,value)
            obj.pR=value;
            obj.setHB;
        end %function set.R
        function value = get.R(obj)
            value = obj.pR;
        end
        %% B
        function set.B(obj,value)
            obj.pB = value;
            if obj.pB > obj.pH
                obj.Hi = obj.pH;
                obj.Bi = obj.pB;
            else
                obj.Hi = obj.pB;
                obj.Bi = obj.pH;
            end %if
        end %function
        
        function value = get.B(obj)
            value = obj.pB;
        end %function
        
        %% R_ers
        % berechnet den Ersatzradius für den flächen oder umfangsgleichen
        % Ersatzquerschnitt
        function value = R_ers(obj)
            phi = 2*asind(obj.B/(2*obj.R));
            switch obj.WALtype
                case {1,2}
                    A = obj.R^2/2*(pi*phi/180-sind(phi));
                    value = sqrt(A/pi);
                case 3
                    l = 2*pi*obj.R*phi/360;
                    value = l/(2*pi);
            end
        end %function
        
        %% m
        function set.m(obj,value)
            obj.V = value * obj.Mat.v;
        end% m
        
        %% gamma
        function value = get.gamma(obj)
            if obj.H >= obj.R || obj.WALtype == 0
                e_S = 0.772;
                value = 6 * abs(obj.V) * e_S / (obj.Bi * (obj.Hi ^ 2));
            else
                e_K = 0.815;
                value = 4 * abs(obj.V) * e_K / (pi * obj.R_ers^3);
            end %if
        end% gamma
        
        %% eta
        function value = get.eta(obj)
            value = obj.Mat.A * obj.Mat.a_T / ((1 + obj.Mat.B * obj.gamma * obj.Mat.a_T) ^ obj.Mat.C);
        end
        
        %% fp
        function value = get.fp(obj) 
            if obj.B / obj.H <= 1
                x = obj.B / obj.H;
                value = 0.147682 * x.^2 - 0.796685 * x + 1;
            else
                x = obj.H / obj.B;
                if x > 0.5
                    value = -0.285714 * x.^2 + 0.252857 * x + 0.393571;
                else
                    value = 0.447;
                end %if
            end %if
        end% fp
        
        %% delta_p
        function value = get.delta_p(obj)
            value = obj.K * obj.V;
        end% delta_p
        
        function value = get.tau_w(obj)
            value = obj.delta_p * obj.H / ( 2 * obj.L );
        end %tau_w
        
        %% K
        function value = get.K(obj)
            if obj.H >= obj.R
                tmp_value = 12 * obj.eta * obj.L / obj.fp / (obj.Bi * obj.Hi ^ 3);
            else
                s=obj.WALtype;
                phi = 2*asind(obj.B/(2*obj.R));
                A = obj.R^2/2*(pi*phi/180-sind(phi));
                l = 2*pi*obj.R*phi/360;
                switch s
                    case 0 %weiter mit Wappen
                        tmp_value = 12 * obj.eta * obj.L / obj.fp / (obj.Bi * obj.Hi ^ 3);
                    case 1 %Flächengleicher Kreis
                        R_ers = sqrt(A/pi);
                        tmp_value = 8 * obj.eta * obj.L / (pi * R_ers^4);
                    case 2 %Flächen+Mantelgleicher Kreis
                        fp=564452.7596;
                        R_ers = sqrt(A/pi);
                        MF = l*obj.L;
                        L_ers = 2*pi*R_ers/MF;
                        tmp_value = 8 * obj.eta * L_ers /fp / (pi * R_ers^4);
                    case 3 %Umfangsgleicher Kreis
                        R_ers = l/(2*pi);
                        tmp_value = 8 * obj.eta * obj.L / (pi * R_ers^4);
                end
            end% if
            value = tmp_value;
        end% K
    end% methods
    
    methods (Access=private)
        function setHB(obj)
        %% Aktualisiert H und B
        % wird bei Änderungen von R und H aufgerufen
            if obj.H >= obj.pR
                obj.B = 2 * obj.pR;
            else
                obj.B = 2 * sqrt(2*obj.pR*obj.H - obj.H.^2);
            end
        end %function setHB
    end
end% classdef

