classdef CNodeSpalt < matlab.mixin.Copyable
    %This Class contains all information for one canal-node
    %Berechnung der einzelnen Teilergebnisse innerhalb dieses Moduls
    %Zur Berechnung müssen geometrische Größen und Carreau-Parameter
    %übergebeben werden.
    
    properties
        %Eindeutige ID
        ID
        %Höhe
        H
        %Breite
        B
        %Länge
        L
        %Material
        Mat = CMaterial;
        %Volumenstrom
        V
        %Auflösung
        eps
%         Nodes = CNodeN;
    end% properties

    properties (Dependent = true, SetAccess = private, Hidden)
        fp %Strömungskoefizient
        K % Widerstandswert
        LN
        gamma_i
    end
    properties (Dependent = true, SetAccess = private)
        gamma
        eta %Dichte nach Carreau
        delta_p %Druckverlust
        tau_w
    end
    
    methods
        function CNK = CNodeSpalt(ID,H,B,L,Mat,V,eps)
            %Ließt alle benötigten Daten ein
            %nur H,B,L sowie V sollten danach noch eine Aktualisierung
            %benötigen
            if nargin > 0 % Support calling with 0 arguments
                CNK.ID = ID;
                CNK.H = H;
                CNK.B = B;
                CNK.L = L;
                CNK.Mat = Mat;
                CNK.V = V;
                CNK.eps = eps;
%                 CNK.Nodes(eps) = CNodeN;
%                 for i=1:eps
%                     CNK.Nodes(i) = CNodeN(i,CNK);
%                 end %for i
            end% if
        end% CNodeSpalt
        
        %gamma_i for intern calculation
        function value = get.gamma_i(obj)
            e_S = 0.772;
            value = 6 * abs(obj.V) * e_S ./ (obj.B * obj.H .^ 2);
        end% gamma_i
        
        %gamma for extern use
        function value = get.gamma(obj)
            value = mean(obj.gamma_i);
        end% gamma
        
        %eta
        function value = get.eta(obj)
            value = obj.Mat.A * obj.Mat.a_T ./ ((1 + obj.Mat.B * obj.gamma_i * obj.Mat.a_T) .^ obj.Mat.C);
        end
        
        %delta_p
        function value = get.delta_p(obj)
            value = obj.K * obj.V; %Schlitzgeometrie ohne Korrekturfaktor
        end% delta_p
        
        function value = get.tau_w(obj)
            value = obj.delta_p * mean(obj.H) / (2 * sum(obj.L));
        end %tau_w
        
        %K
        function value = get.K(obj)
            if (obj.B * obj.H .^3) ~= 0
                tmp_value = sum(12 * obj.eta * (obj.L/obj.eps) ./ (obj.B * obj.H .^ 3));
            else
                tmp_value = 10^20; %dirty!
            end% if
            value = tmp_value;
        end% K
    end% methods

end% classdef

