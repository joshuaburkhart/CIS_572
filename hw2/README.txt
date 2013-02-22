Joshua Burkhart
2/8/2013
Dr. Daniel Lowd
CIS 572

Homework 2
----------

This program can be run on the command line as shown below.

demeter:hw2 joshuaburkhart$ ./nb.rb spambase/spambase-train.csv spambase/spambase-test.csv 2 model.log
0.991944332415212
0.00636663260462407
0.0877900257799145
0.118858248319976
0.99999999999999

It was tested using ruby 1.8.7

demeter:hw2 joshuaburkhart$ ruby --version
ruby 1.8.7 (2009-06-12 patchlevel 174) [i686-darwin9.7.0]

One may need to specify 'ruby' prior to the file name as below.

demeter:hw2 joshuaburkhart$ ruby nb.rb spambase/spambase-train.csv spambase/spambase-test.csv 2 model.log
0.991944332415212
0.00636663260462407
0.0877900257799145
0.118858248319976
0.99999999999999
