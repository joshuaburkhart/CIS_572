Joshua Burkhart
2/22/2013
Dr. Daniel Lowd
CIS 572

Homework 3
==========

The programs written for this assignment have been tested using ruby 1.8.7.

demeter:hw3 joshuaburkhart$ ruby --version
ruby 1.8.7 (2009-06-12 patchlevel 174) [i686-darwin9.7.0]

Depending on one's path condiguration, it may be necessary to specify 'ruby' prior to the file name.


Logistic Regression
-------------------

The 'logistic.rb' program performs logistic regression.

Usage: ./logistic.rb <train> <test> <eta> <sigma> <model>

An example execution is below.

demeter:hw3 joshuaburkhart$ ./logistic.rb spambase/spambase-train.csv spambase/spambase-test.csv 0.0001 0.1 logistic_model.log
0.677795420385563
0.473381786605025
0.348507362380177
0.40129143781237
0.955589150632541
...
0.0136955071801666
0.356546926267072
0.503328646082482
0.90281762249045
0.643065243827831
0.799044678539924
Accuracy: 0.921


Perceptron
----------

The 'perceptron.rb' program performs perceptron learning.

Usage: ./perceptron.rb <train> <test> <eta> <model>

An example execution is below.

demeter:hw3 joshuaburkhart$ ./perceptron.rb spambase/spamlineartrainsmall.csv spambase/spamlineartest.csv 0.1 perceptron_model.log
Errors: 19.0 (0.19)
Errors: 12.0 (0.12)
Errors: 8.0 (0.08)
Errors: 6.0 (0.06)
Errors: 4.0 (0.04)
Errors: 3.0 (0.03)
Errors: 5.0 (0.05)
Errors: 0.0 (0.0)
0.425557483188341
0.354343693774205
...
0.289050497374996
0.401312339887548
0.622459331201855
0.425557483188341
0.549833997312478
Accuracy: 0.959
