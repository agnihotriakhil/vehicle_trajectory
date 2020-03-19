function [out, valid] = WayInterpolation(in, resolution_in, isMap)
    if ~exist('resolution_in', 'var')
        res = 1;
    else
        res = resolution_in;
    end
    out = in;
    I = 1;
    valid = true;
    while I ~= size(out, 2)
        p1 = out(:,I);
        p2 = out(:,I+1);
        if norm(p1-p2) > 0.1 * 160 * 1000 / 3600 && ~isMap % 0.1s, 160kmh
            valid = false;
            return
        end
        if norm(p1-p2) > res
            lambda = res / norm(p1-p2);
            lambda_acc = lambda;
            p_insert = []; num_insert = 0;
            px = p1(1); py = p1(2);
            delta_x = lambda * (p2(1) - p1(1));
            delta_y = lambda * (p2(2) - p1(2));
            while lambda_acc < 1
                px = px + delta_x;
                py = py + delta_y;
                p_insert = [p_insert [px; py]];
                num_insert = num_insert + 1;
                lambda_acc = lambda_acc + lambda;
            end
            assert(num_insert == size(p_insert,2));
            out = [out(:,1:I) p_insert out(:,I+1:end)];
            I = I + num_insert;
        end
        I = I + 1;
    end
end