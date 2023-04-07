`timescale 1ns / 1ps
/**
Alex Knowlton
4/6/2023

useful definitions for testing, including assert equals statement
NOT USED for top-level designs.
*/

/**
assert_equals
Checks that expected and actual values match, otherwise prints a line to the Tcl console
*/
`define assert_equals(expected, actual) \
    assert(actual == expected) \
    else $display("Assertion Error: Expected %h, Received %h", expected, actual);