classdef CGeometrie < matlab.mixin.Copyable
    %CGeometrie enth�lt die Geometriedaten des Wendelverteilers
    
    properties
        %Durchmesser
        D
        %Bauh�he
        H
        %Wendelzahl
        n
        %Wendelwinkel
        alpha
        %Mei�el-Radius
        R
        %Kanaltiefe
        KTiefe
        %Spalttiefe
        STiefe
    end
    properties (Dependent)
        %Wendel-Breite
        Wb
    end
    
    methods
        function value = get.Wb(obj)
            value = 2*obj.R;
        end
    end
    
end

