# Command Line Equation Evaluator

## Instructions
This is a [Ceylon](https://ceylon-lang.org/) program that compiles to the JVM thus it uses the ceylon wrapper. 

To Compile it run the following command:
 
```
$ ./ceylonb compile
Note: Created module io.eldermael.equations/1.0.0
Note: Created module test.io.eldermael.equations/1.0.0
```
I added a battery of tests that can be run once compiled with:

```
$ ./ceylonb test test.io.eldermael.equations
======================== TESTS STARTED =======================
...
```

Finally, to run the program run the following command once you have compiled the module:

```
$ ./ceylonb run io.eldermael.equations example.txt
location = 16
offset = 7
origin = 8
random = 2
```
