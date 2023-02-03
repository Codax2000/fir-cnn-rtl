`timescale 1ns / 1ps
/**
Alex Knowlton
EE 371
Definition for the assert_equals function. Used in testbenches to
neatly print out an error message if the actual value does not
match the expected value.
Call format:
    assert_equals(expected, actual)
        - expected - expected value
        - actual - actual value to test
Error format:
"{time}: Assertion Error. Expected {expected}, received {actual}"
*/
package utils;
    function void assert_equals(expected, actual);
        assert(expected == actual)
            else $display("%3d: Assertion Error. Expected %h, received %h", $time, expected, actual);
        
    endfunction
endpackage
