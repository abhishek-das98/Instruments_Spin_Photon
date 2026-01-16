clear;
clc;
close;

files = {
    '1_13_cluster_4_hard_to_read_dot_cavity_1_1_128uW'
    };
%legends = {'0 mA', '20 mA (2.8 V)'};
exposure_time = 1;

plotSpectraFromCSV(files, 'overlayed', ['R211105A\_Fab, Cluster 4-(unreadable), ' ...
    'QD at cavity position(1,1), ' ...
    'Optical power = 128 uW'], ...
    [], exposure_time, ...
    '1_13_cluster_4_hard_to_read_dot_cavity_1_1_128uW_no_bias');
