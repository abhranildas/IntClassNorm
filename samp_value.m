function [samp_val,samp_val_mat,samp_1_correct,samp_2_correct,samp_1_dv,samp_2_dv]=samp_value(samp_1,samp_2,dom,varargin)
% Expected value given two samples and a boundary. If outcome values
% are not additionally specified, this is the classification accuracy.
% Credits:
%   Abhranil Das <abhranil.das@utexas.edu>
%	Wilson S Geisler
%	Center for Perceptual Systems, University of Texas at Austin
% If you use this code, please cite:
%   A new method to compute classification error
%   https://jov.arvojournals.org/article.aspx?articleid=2750251

% parse inputs (manual name-value parse instead of inputParser: this is
% called once per objective evaluation during boundary optimization, where
% inputParser overhead dominates. Unknown name-value pairs are ignored,
% matching the previous parser.KeepUnmatched=true behavior.)
dom_type='quad';
d_scale_type='squeeze_dist'; % match classify_normals default; squeeze_dv (the only
                             % transform samp_value applies) acts only when d_scale~=1
d_scale=1;
acc_sharpness=inf; % sharpness of sigmoidal accuracy function. Inf means exact step function.
vals=eye(2);
samp_balance=false;
for i=1:2:numel(varargin)-1
    switch lower(varargin{i})
        case 'dom_type',      dom_type=varargin{i+1};
        case 'd_scale_type',  d_scale_type=varargin{i+1};
        case 'd_scale',       d_scale=varargin{i+1};
        case 'acc_sharpness', acc_sharpness=varargin{i+1};
        case 'vals',          vals=varargin{i+1};
        case 'samp_balance',  samp_balance=varargin{i+1};
    end
end

if strcmpi(dom_type,'ray_trace')
    [~,~,samp_1_correct]=dom(samp_1',[]);
    [~,~,samp_2_correct]=dom(samp_2',[]);
    samp_2_correct=~samp_2_correct;
else

    % compute sample decision variables
    if strcmpi(dom_type,'quad')
        q2=dom.q2;
        q1=dom.q1;
        q0=dom.q0;

        samp_1_dv=dot(samp_1,samp_1*q2',2) + samp_1*q1 + q0;
        samp_2_dv=dot(samp_2,samp_2*q2',2) + samp_2*q1 + q0;

    elseif strcmpi(dom_type,'fun')
        samp_1_cell=num2cell(samp_1,1);
        samp_1_dv=dom(samp_1_cell{:});
        samp_2_cell=num2cell(samp_2,1);
        samp_2_dv=dom(samp_2_cell{:});
    end

    % scale d' by squeezing decision variables together, so their
    % medians come to 0
    if strcmpi(d_scale_type,'squeeze_dv') && d_scale ~=1
        samp_1_dv=samp_1_dv-median(samp_1_dv)*(1-d_scale);
        samp_2_dv=samp_2_dv-median(samp_2_dv)*(1-d_scale);
    end

    % compute correct trials by binarizing dv
    if isinf(acc_sharpness)
        % step accuracy function:
        samp_1_correct=samp_1_dv > 0;
        samp_2_correct=samp_2_dv < 0;
    else
        % smoothened sigmoidal accuracy function:
        samp_1_correct=1./(1+exp(-acc_sharpness*samp_1_dv));
        samp_2_correct=1./(1+exp(acc_sharpness*samp_2_dv));
    end
end

samp_count_mat=[sum(samp_1_correct) sum(~samp_1_correct);
                sum(~samp_2_correct)  sum(samp_2_correct)];

samp_val_mat=samp_count_mat.*vals;

if ~samp_balance % if it is not required to be class-balanced
    samp_val=sum(samp_val_mat(:));
else
    % class-balanced expected value per sample point, i.e. average of the expected values per point in
    % each class
    samp_val=mean(sum(samp_val_mat,2)./sum(samp_count_mat,2));
end

end


