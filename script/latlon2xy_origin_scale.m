function [ret_x, ret_y, meridian_rad, offset_x, offset_y, xmax, ymax] = ...
                latlon2xy_origin_scale(lon, lat, meridian_rad_in, offset_x_in, offset_y_in)
    lon_rad = lon / 180 * pi; lat_rad = lat / 180 * pi;
    if ~exist('meridian_rad_in', 'var')
        meridian_rad = mean(lon_rad);
    else
        meridian_rad = meridian_rad_in;
    end
    
    R = 6.3781e6;

    x = R*(lon_rad - meridian_rad).*cos(lat_rad);
    y = R*lat_rad;

    if ~exist('offset_x_in', 'var')
        offset_x = min(x) - 1e-6;
    else
        offset_x = offset_x_in;
    end
    
    if ~exist('offset_y_in', 'var')
        offset_y = min(y) - 1e-6;
    else
        offset_y = offset_y_in;
    end
    
    ret_x = (x-offset_x);
    ret_y = (y-offset_y);
    
    xmax = max(ret_x);
    ymax = max(ret_y);
end

