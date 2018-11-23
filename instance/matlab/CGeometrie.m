classdef CGeometrie < matlab.mixin.Copyable
    %CGeometrie enthält die Geometriedaten des Wendelverteilers
    
    properties
        %Durchmesser
        D
        %Bauhöhe
        H
        %Wendelzahl
        n
        %Wendelwinkel
        alpha
        %Meißel-Radius
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

