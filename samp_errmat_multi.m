function [samp_errmat,samp_class]=samp_errmat_multi(samples,doms)
% Expected value given two samples and a boundary. If outcome values
% are not additionally specified, this is the classification accuracy.
% Credits:
%   Abhranil Das <abhranil.das@utexas.edu>
%	R Calen Walshe
%	Wilson S Geisler
%	Center for Perceptual Systems, University of Texas at Austin
% If you use this code, please cite:
% 1. <a href="matlab:web('https://doi.org/10.1167/jov.21.10.1','-browser')"
% >A method to integrate and classify normal distributions</a>
% 2. <a href="matlab:web('https://arxiv.org/abs/2012.14331','-browser')"
% >Methods to integrate multinormals and compute classification measures</a>

% parse inputs
parser=inputParser;
parser.KeepUnmatched=true;
addRequired(parser,'samples',@isstruct);
addRequired(parser,'doms',@iscell);
parse(parser,samples,doms);

n_dists=length(samples);
samp_class=cell(n_dists,1);
samp_errmat=nan(n_dists);
for i_samp=1:n_dists
    samp=samples(i_samp).sample;
    samp_class_this=nan(size(samp,1),1);
    for i_norm=1:n_dists
        dom=doms{i_norm};
        [~,~,samp_correct_this]=dom(samp',[]);
        samp_class_this(samp_correct_this)=i_norm;
        samp_errmat(i_samp,i_norm)=nnz(samp_correct_this);
    end
    samp_class{i_samp}=samp_class_this;
end
end


