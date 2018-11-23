classdef CMaterial < handle
    %CMATERIAL enthält alle Stoffeigenschaften
    %   ...
    properties (SetObservable)
        m
        %Carraeu Parameter
        A
        B
        C
        %WLF-Parameter
        Ts
        T0
        T
        %Dichte
        v0
        vs
    end %properties
    properties(Dependent=true)
        v
        V
        a_T
    end %propertie
    properties (Access = private)
        pa_T
    end %properties
    methods
        function obj = CMaterial(A,B,C,Ts,T0,T,v0,vs)
            if nargin > 0
                obj.A = A;
                obj.B = B;
                obj.C = C;
                obj.Ts = Ts;
                obj.T0 = T0;
                obj.T = T;
                obj.v0 = v0;
                obj.vs = vs;
                obj.CalcA_T;
            end %if
            addlistener(obj,'Ts','PostSet',@CMaterial.propChange);
            addlistener(obj,'T0','PostSet',@CMaterial.propChange);
            addlistener(obj,'T','PostSet',@CMaterial.propChange);
        end %
        
        function value = get.v(obj)
            value = interp1([293.15 obj.T0],[obj.vs obj.v0],obj.T,'lin','extrap');
        end %get.v
        
        function value = get.V(obj)
            value = obj.m * obj.v;
        end %get.V
        
        function value = get.a_T(obj)
            value = obj.pa_T;
        end %get.a_T
        
        function CalcA_T(obj)
            C1 = 8.86;
            C2 = 101.6;
            obj.pa_T = 10.^( (C1*(obj.T0-obj.Ts) / (C2+(obj.T0-obj.Ts)) ) - ( C1*(obj.T-obj.Ts) / (C2+(obj.T-obj.Ts)) ) );
        end %function
    end %methods
    methods (Static)
        function propChange(~,eventData)
            h = eventData.AffectedObject;
            h.CalcA_T();
        end %function
    end %methods
end %classdef

