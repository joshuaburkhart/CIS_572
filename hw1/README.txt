Joshua Burkhart
1/28/2013
Dr. Daniel Lowd
CIS 572

Homework 1
----------

This program can be run on the command line as shown below.

demeter:CIS_572 joshuaburkhart$ ./id3.rb data_sets1/training_set.csv data_sets1/test_set.csv model1.log
Accuracy: 76.85%
demeter:CIS_572 joshuaburkhart$ ./id3.rb data_sets2/training_set.csv data_sets2/test_set.csv model2.log
Accuracy: 71.83%

It was tested using ruby 1.8.7.

demeter:CIS_572 joshuaburkhart$ ruby --version
ruby 1.8.7 (2009-06-12 patchlevel 174) [i686-darwin9.7.0]

One may need to specify 'ruby' prior to the file name as below.

demeter:CIS_572 joshuaburkhart$ ruby id3.rb data_sets2/training_set.csv data_sets2/test_set.csv model2.log
Accuracy: 71.83%
